function [thisf, thisMuX, thisMuY, thisSigX, thisSigY,...
    thisTheta, muXVals, muYVals, sigXVals, sigYVals, thetaVals] =...
    initializeEMvars_LS(cellFitParams, numMuVals, numSigVals,...
    numThetaVals, imgs, varargin)

% Written by Lacey Kitch in 2013

if ~isempty(varargin)
	options=varargin{1};
else
	options=[];
end

nCells=size(cellFitParams,1);

muXVals=zeros(nCells,numMuVals);
muYVals=zeros(nCells,numMuVals);
sigXVals=zeros(nCells,numSigVals);
sigYVals=zeros(nCells,numSigVals);
thetaVals=zeros(nCells,numThetaVals);

muOffsetVec=(1:numMuVals)-ceil(numMuVals/2);
sigOffsetVec=((1:numSigVals)-ceil(numSigVals/2))*0.5;
thetaOffsetVec=((1:numThetaVals)-ceil(numThetaVals/2))*20*pi/180;

thisMuX=zeros(nCells,1);
thisMuY=zeros(nCells,1);
thisSigX=zeros(nCells,1);
thisSigY=zeros(nCells,1);
thisTheta=zeros(nCells,1);

for cInd=1:nCells
    % params = [mux, muy, sigx, sigy, theta, A]
    thisMuX(cInd)=cellFitParams(cInd, 1);
    thisMuY(cInd)=cellFitParams(cInd, 2);
    thisSigX(cInd)=cellFitParams(cInd, 3);
    thisSigY(cInd)=cellFitParams(cInd, 4);
    thisTheta(cInd)=cellFitParams(cInd, 5);
    
    muXVals(cInd,:)=thisMuX(cInd)+muOffsetVec;
    
    muYVals(cInd,:)=thisMuY(cInd)+muOffsetVec;
    
    sigXVals(cInd,:)=thisSigX(cInd)+sigOffsetVec;
    
    sigYVals(cInd,:)=thisSigY(cInd)+sigOffsetVec;
    
    thetaVals(cInd,:)=thisTheta(cInd)+thetaOffsetVec;
end
imgSize=size(imgs(:,:,1));
cellImgs=calcCellImgs(cellFitParams, imgSize);
thisf = calculateTraces(cellImgs, imgs, options);

% from file initializeEMvars_LS on 12/11/13 at 6:04pm