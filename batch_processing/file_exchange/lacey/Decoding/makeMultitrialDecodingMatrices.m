function [eventMatrix, decPositionVec] = makeMultitrialDecodingMatrices(eventTimes,...
    positionVecs, trialsToUse, nFramesByTrial, varargin)

%%% Written by Lacey Kitch in 2012-2014

options.numFramesBack=0;
options.smoothLength=6;
options=getOptions(options, varargin);

nFramesTotal=sum(nFramesByTrial(trialsToUse));
nCells=length(eventTimes);
eventMatrix=zeros(nFramesTotal,nCells*(options.numFramesBack+1));
decPositionVec=zeros(1,nFramesTotal);
framesSoFar=0;
if size(trialsToUse,1)>1
    trialsToUse=trialsToUse';
end
for trialInd=trialsToUse
    
    thisPositionVec=positionVecs{trialInd};

    firstFrame=sum(nFramesByTrial(1:(trialInd-1)))+1;
    lastFrame=sum(nFramesByTrial(1:trialInd));

    theseEventTimes=eventTimes;
    for cInd=1:nCells
        theseEventTimes{cInd}(theseEventTimes{cInd}<firstFrame)=[];
        theseEventTimes{cInd}(theseEventTimes{cInd}>lastFrame)=[];
        theseEventTimes{cInd}=theseEventTimes{cInd}-firstFrame+1;
    end

    [thisEventMatrix, thisDecPositionVec] = makeDecodingMatrices(theseEventTimes,...
        thisPositionVec, options.numFramesBack, options.smoothLength);
    
    eventMatrix(framesSoFar+(1:nFramesByTrial(trialInd)),:)=thisEventMatrix;
    decPositionVec(framesSoFar+(1:nFramesByTrial(trialInd)))=thisDecPositionVec;
    framesSoFar=framesSoFar+nFramesByTrial(trialInd);
end