function cellImgOverlaps = calcCellImgOverlaps(cellImgs)

% Written by Lacey Kitch in 2013

nCells=size(cellImgs,3);
cellImgOverlaps=ones(nCells,nCells);
for cInd1=1:nCells
    normConst=sum(sum(cellImgs(:,:,cInd1).^2));
    for cInd2=(cInd1+1):nCells
        overlapAmt=sum(sum(cellImgs(:,:,cInd2).*cellImgs(:,:,cInd1)));
        overlapAmt=overlapAmt/normConst;
        cellImgOverlaps(cInd1,cInd2)=overlapAmt;
        cellImgOverlaps(cInd2,cInd1)=overlapAmt;
    end
end

% from file calcCellImgOverlaps on 12/12/13 at 11:41am