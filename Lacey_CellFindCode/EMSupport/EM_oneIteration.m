function logLik = EM_oneIteration(imgs, noiseSigma, bg,...
    thisf, thisMuX, thisMuY, thisSigX, thisSigY, thisTheta,...
    numfvals, muXVals, muYVals, sigXVals, sigYVals, thetaVals, fInc, varargin)

% Written by Lacey Kitch in 2013

% get display options
displayLikelihoods=0;
displayActiveTimes=0;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'displayLikelihoods')
        displayLikelihoods=options.displayLikelihoods;
    end
    if isfield(options, 'displayActiveTimes')
        displayActiveTimes=options.displayActiveTimes;
    end
end

% preallocate log likelihood matrix
nCells=length(thisSigX);
numMuVals=size(muXVals,2);
numSigVals=size(sigXVals,2);
numThetaVals=size(thetaVals,2);
logLik=cell(1,5);
logLik{1}=zeros(nCells,numMuVals);  % muX
logLik{2}=zeros(nCells,numMuVals);  % muY
logLik{3}=zeros(nCells,numSigVals); % sigX
logLik{4}=zeros(nCells,numSigVals); % sigY
logLik{5}=zeros(nCells,numThetaVals); % theta

% calculate cell images for all parameter combinations
imgSize=size(imgs(:,:,1));
paramSizeCumProd=[1 cumprod([numMuVals, numMuVals, numSigVals, numSigVals])];
cellImgsByParam=calcCellImgsByParam(muXVals, muYVals, sigXVals, sigYVals, thetaVals, nCells, imgSize);

% get indices of current parameter guesses
[thisMuXInds, thisMuYInds, thisSigXInds, thisSigYInds, thisThetaInds]=...
    getParamInds(muXVals, muYVals, sigXVals, sigYVals, thetaVals,...
    thisMuX, thisMuY, thisSigX, thisSigY, thisTheta);
clear muXVals muYVals sigXVals sigYVals thetaVals

% initialize cell images for current parameter guesses
% use these to find neighbors and convex hulls
cellImgs=calcCellImgs([thisMuX, thisMuY, thisSigX, thisSigY, thisTheta], imgSize);
[neighbors, ~] = getCellNeighbors(cellImgs);
[cvxHulls,~,~] = getConvexHull(cellImgs);
%clear thisMuX thisMuY thisSigX thisSigY thisTheta cellImgOverlaps cInd

% reshape everything to enable 2D multiplications later
% we don't reshape imgs here because then the whole matrix would be copied
% for this function. instead reshape each F in time loop
cellImgs=reshape(cellImgs, [imgSize(1)*imgSize(2), nCells]);
cellImgsByParam=reshape(cellImgsByParam, [imgSize(1)*imgSize(2), nCells, size(cellImgsByParam,4)]);
bg=reshape(bg, [imgSize(1)*imgSize(2), 1]);

% find the times when each cell is "active"
% this is defined as when the cell has a most likely f value
% greater than 3 times the noise std dev
% thisf is nCells x nFrames, so will activeTimes be
numSigmasThresh=3;
[singleCellActiveTimes,activeTimes]=calcSingleCellActiveTimes(thisf, numSigmasThresh, noiseSigma, neighbors);

% minimum number of frames to use to estimate the cell shape
minNumActiveTimes=15;
maxNumActiveTimes=40;

% set the vector used for the conditional f dist
fOffsetVec=(-ceil(numfvals/2):ceil(numfvals/2))*fInc;
clear numfvals fInc

if displayActiveTimes
    h=figure;
end

% loop over cells and do EM on each separately, during only its solo or
% nearly solo active times
for cInd=1:nCells
    
    % check to see whether this cell has enough times when it is active by
    % itself (no neighbors active)
    % then pick the best active times to use, depending on condition
    [theseActiveTimes, neighborsActiveOk] = findBestActiveTimes(cInd,...
        singleCellActiveTimes, activeTimes, minNumActiveTimes, maxNumActiveTimes,...
        neighbors, thisf, noiseSigma);
%     [meanNeighborRatios, ratioToMeanNeighbor, meanNeighborDifference] = calculateMeanNeighborRatio(cInd, theseActiveTimes, neighbors, thisf);
    
    % if there are no active times, set the likelihood of the current
    % parameters to > the max value
    if isempty(theseActiveTimes)
        logLik{1}(cInd,thisMuXInds(cInd))=1;
        logLik{2}(cInd,thisMuYInds(cInd))=1;
        logLik{3}(cInd,thisSigXInds(cInd))=1;
        logLik{4}(cInd,thisSigYInds(cInd))=1;
        logLik{5}(cInd,thisThetaInds(cInd))=1;
    % if it's not empty, make sure it's the right size
    elseif size(theseActiveTimes,1)>1
        theseActiveTimes=theseActiveTimes';
    end
    if size(theseActiveTimes,1)>1
        error('theseActiveTimes is the wrong size....')
    end
    
    % now go through the active times and add to the likelihood of each
    % shape parameter
    tInd=0;
    for t=theseActiveTimes

        tInd=tInd+1;
        F=imgs(:,:,t);
        if displayActiveTimes
            displayFrameWithMarkedCells(F, cInd, thisMuX, thisMuY, cvxHulls, neighbors, 1, h, neighborsActiveOk, meanNeighborRatios(tInd), ratioToMeanNeighbor(tInd));
        end
        F=reshape(F, [imgSize(1)*imgSize(2), 1]);
        thisft=thisf(:,t);
        
        % actual EM
        allfvals=getAllfVals_singleActiveCell(thisft,cInd,fOffsetVec);

        % E
        thisLoopCellImgs=cellImgs;
        % q(f') = log( p(f=f'|F;sigmas, mus) ) = logp*p(f=f';sigmas,mus)/p(F;sigmas,mus)
        % where f' is a specific vector of f values for all cells
        % elopq exp(q*p(F)/p(f=f'))
        elogp=exp(logpFgivenf(F, allfvals, thisLoopCellImgs, noiseSigma, bg));

        % M
        for muInd=1:numMuVals
            % muX
            linInd=sum(([muInd thisMuYInds(cInd) thisSigXInds(cInd) thisSigYInds(cInd) thisThetaInds(cInd)]-1).*paramSizeCumProd)+1;
            thisLoopCellImgs(:,cInd)=cellImgsByParam(:,cInd,linInd);
            logpThisParam=logpFgivenf(F, allfvals, thisLoopCellImgs, noiseSigma, bg);
            logLik{1}(cInd,muInd)=logLik{1}(cInd,muInd)+sum(logpThisParam.*elogp);

            % muY
            linInd=sum(([thisMuXInds(cInd) muInd thisSigXInds(cInd) thisSigYInds(cInd) thisThetaInds(cInd)]-1).*paramSizeCumProd)+1;
            thisLoopCellImgs(:,cInd)=cellImgsByParam(:,cInd,linInd);
            logpThisParam=logpFgivenf(F, allfvals, thisLoopCellImgs, noiseSigma, bg);
            logLik{2}(cInd,muInd)=logLik{2}(cInd,muInd)+sum(logpThisParam.*elogp);
        end


        for sigInd=1:numSigVals  
            % sigX
            linInd=sum(([thisMuXInds(cInd) thisMuYInds(cInd) sigInd thisSigYInds(cInd) thisThetaInds(cInd)]-1).*paramSizeCumProd)+1;
            thisLoopCellImgs(:,cInd)=cellImgsByParam(:,cInd,linInd);
            logpThisParam=logpFgivenf(F, allfvals, thisLoopCellImgs, noiseSigma, bg);
            logLik{3}(cInd,sigInd)=logLik{3}(cInd,sigInd)+sum(logpThisParam.*elogp);

            % sigY
            linInd=sum(([thisMuXInds(cInd) thisMuYInds(cInd) thisSigXInds(cInd) sigInd thisThetaInds(cInd)]-1).*paramSizeCumProd)+1;
            thisLoopCellImgs(:,cInd)=cellImgsByParam(:,cInd,linInd);
            logpThisParam=logpFgivenf(F, allfvals, thisLoopCellImgs, noiseSigma, bg);
            logLik{4}(cInd,sigInd)=logLik{4}(cInd,sigInd)+sum(logpThisParam.*elogp);
        end


        for thetaInd=1:numThetaVals  
            % theta
            linInd=sum(([thisMuXInds(cInd) thisMuYInds(cInd) thisSigXInds(cInd) thisSigYInds(cInd) thetaInd]-1).*paramSizeCumProd)+1;
            thisLoopCellImgs(:,cInd)=cellImgsByParam(:,cInd,linInd);
            logpThisParam=logpFgivenf(F, allfvals, thisLoopCellImgs, noiseSigma, bg);
            logLik{5}(cInd,thetaInd)=logLik{5}(cInd,thetaInd)+sum(logpThisParam.*elogp);
        end
    end
end
if displayLikelihoods
    figure(81)
    for kkk=1:5
        subplot(5,1,kkk)
        imagesc(logLik{kkk})
        colorbar()
        drawnow;
    end
end

% from file EM_oneIteration_singleActiveTimes_nomex_reshape_timeredo on
% 12/11/13 at 6:09pm
