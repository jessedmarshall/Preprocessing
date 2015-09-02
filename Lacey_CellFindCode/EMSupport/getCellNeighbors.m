function [neighbors, cellImgOverlaps] = getCellNeighbors(cellImgs)

nCells=size(cellImgs,3);
cellImgOverlaps = calcCellImgOverlaps(cellImgs);
neighbors=cell(nCells,1);
for cInd=1:nCells
    cellImgOverlaps(cInd,cInd)=0;
    neighbors{cInd}=find(cellImgOverlaps(cInd,:)>0.15);
end