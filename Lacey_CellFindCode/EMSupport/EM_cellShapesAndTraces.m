function [estCellTraces, estParams, nIterations] =...
    EM_cellShapesAndTraces(numMuVals, numSigVals, numThetaVals,...
    imgs, cellFitParams, noiseSigma, bg, usePar, areaOverlapThresh, varargin)

% Written by Lacey Kitch in 2013

if ~isempty(varargin)
	options=varargin{1};
	if isfield(options, 'suppressOutput')
		suppressOutput=options.suppressOutput;
	else
		suppressOutput=0;
	end
else
	options=[];
	suppressOutput=0;
end

% initialize all variable value vectors
fInc=0.001;
numfvals=5;
[thisf, thisMuX, thisMuY, thisSigX, thisSigY,...
    thisTheta, muXVals, muYVals, sigXVals, sigYVals, thetaVals] =...
    initializeEMvars_LS(cellFitParams, numMuVals, numSigVals,...
    numThetaVals, imgs, options);

% perform EM
maxIterations=15;
pixelConvergeThresh=0.1;
k=1;
notConverged=1;
changeParam=0;
lastChangeParam=100;
while notConverged && k<=maxIterations
    
    % calculate q, use to calculate logLik, output logLik and q
    % note that q is p(f|F) for LAST iteration's set of params
    % but that we can still use this to get most likely f upon convergence
    % since the parameters won't have changed
    if usePar
        error('Sorry, parallel not implemented for this version. Set usePar=0.')
    else
        logLik = EM_oneIteration(imgs, noiseSigma, bg,...
            thisf, thisMuX, thisMuY, thisSigX, thisSigY, thisTheta,...
            numfvals, muXVals, muYVals, sigXVals, sigYVals, thetaVals, fInc, options);
    end
    
    % update the parameters
    lastLastChangeParam=lastChangeParam;
    lastChangeParam=changeParam;
    [thisMuX, thisMuY, thisSigX, thisSigY, thisTheta, changeParam, ~] =...
        EM_updateParams_LS(logLik,...
        thisMuX, thisMuY, thisSigX, thisSigY, thisTheta,...
        muXVals, muYVals, sigXVals, sigYVals, thetaVals,...
        imgs, options);
    
    theseParams=[thisMuX, thisMuY, thisSigX, thisSigY, thisTheta];
    [~,theseParams,thisf,goodCellInds]=resolveBorderConflicts(theseParams,areaOverlapThresh,imgs,1,options);
    
    thisMuX=theseParams(:,1);
    thisMuY=theseParams(:,2);
    thisSigX=theseParams(:,3);
    thisSigY=theseParams(:,4);
    thisTheta=theseParams(:,5); 
    
    muXVals=muXVals(goodCellInds,:);
    muYVals=muYVals(goodCellInds,:);
    sigXVals=sigXVals(goodCellInds,:);
    sigYVals=sigYVals(goodCellInds,:);
    thetaVals=thetaVals(goodCellInds,:);
    
    % check on convergence and stop if appropriate    
    if changeParam < pixelConvergeThresh || changeParam==lastChangeParam || changeParam==lastLastChangeParam
        notConverged=0;
    end
    if ~suppressOutput
        display(['Iteration ' num2str(k) ' finished | avg change in param, in pixels = ' num2str(changeParam), ' | new nCells = ' num2str(length(thisMuX))]);
    end
    k=k+1;
end

nIterations=k-1;

estParams=[thisMuX, thisMuY, thisSigX, thisSigY, thisTheta];
estCellTraces=thisf;


% from file EM_cellFiltersAndTraces_v4pt1_nomex on 12/11/13 5:21pm