function allfvals = getAllfVals_singleActiveCell(thisft,...
    activeCellInd, fOffsetVec)

% Written by Lacey Kitch in 2013

% allfvals is numfvecs x nCells
% each row is a set of fValues, one for each cell

if size(thisft,2)>1
    thisft=thisft';
end
allfvals=repmat(thisft,[1, length(fOffsetVec)]);
allfvals(activeCellInd,:)=thisft(activeCellInd)+fOffsetVec;