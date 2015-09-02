function positionVecsCell = convertPosMatToCell(positionVecsBinned, nFramesByTrial)

%%% Written by Lacey Kitch in 2012-2014

nTrials=length(nFramesByTrial);
positionVecsCell=cell(1,nTrials);
framesBefore=cumsum([0 nFramesByTrial]);
for trInd=1:nTrials
    positionVecsCell{trInd}=positionVecsBinned(framesBefore(trInd)+(1:nFramesByTrial(trInd)));
end