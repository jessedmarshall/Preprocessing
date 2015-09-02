function [singleCellActiveTimes, activeTimes] = calcSingleCellActiveTimes(thisf, numSigmasThresh, noiseSigma, neighbors)

nCells=size(thisf,1);
activeTimes=thisf>numSigmasThresh*noiseSigma;
singleCellActiveTimes=activeTimes;
for cInd=1:nCells
    timesNeighborsActive=sum(activeTimes(neighbors{cInd},:),1);
    timesNeighborsActive=logical(timesNeighborsActive);
    singleCellActiveTimes(cInd,timesNeighborsActive)=0;
end