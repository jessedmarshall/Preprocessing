function allfvals = getAllfVals_singleActiveCell(thisft,...
    activeCellInd, fOffsetVec, nCells)

% Written by Lacey Kitch in 2013

% allfvals is numfvecs x nCells
% each row is a set of indices of fValues, one for each cell

numfvecs=length(fOffsetVec);
if size(thisft,2)>1
    thisft=thisft';
end
allfvals=repmat(thisft,[1, length(fOffsetVec)]);
allfvals(activeCellInd,:)=thisft(activeCellInd)+fOffsetVec;

% from file getAllfVals_singleCluster on 12/12/13 at 1:15pm