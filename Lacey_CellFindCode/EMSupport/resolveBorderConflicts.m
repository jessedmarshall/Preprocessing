function [allCellImgs,finalCellParams,finalCellTraces,goodCellInds] = resolveBorderConflicts(cellFitParams,...
    areaOverlapThresh,imgs,calcTraces,varargin)

% Written by Lacey Kitch in 2013

if ~isempty(varargin)
	options=varargin{1};
else
	options=[];
end

if ~ (calcTraces==1 || calcTraces==0)
    calcTraces %#ok<NOPRT>
    error('ResolveBorderConflicts being called incorrectly');
end
imgSize=size(imgs(:,:,1));

nCells=size(cellFitParams,1);
cellImgs=calcCellImgs(cellFitParams(:,1:5),imgSize);
for cInd=1:nCells
    thisImg=cellImgs(:,:,cInd);
    thisImg(thisImg<0.2*max(thisImg(:)))=0;
    cellImgs(:,:,cInd)=thisImg;
end
cellImgs(cellImgs>0)=1;

finalCellParams=cellFitParams;

cellsToDelete=nan(nCells,1);
nCellsBad=0;

for cInd=1:nCells
    c1Pixels=find(cellImgs(:,:,cInd)>0);
    if ~ismember(cInd,cellsToDelete)
        for matchInd=(cInd+1):nCells
            if abs(cellFitParams(cInd,1)-cellFitParams(matchInd,1))<20 && abs(cellFitParams(cInd,2)-cellFitParams(matchInd,2))<20
                c2Pixels=find(cellImgs(:,:,matchInd)>0);
                thisOverlap=length(intersect(c1Pixels,c2Pixels));
                thisOverlap1=thisOverlap/length(c1Pixels);
                thisOverlap2=thisOverlap/length(c2Pixels);
                    
                if thisOverlap1>areaOverlapThresh && thisOverlap2>areaOverlapThresh
                    nCellsBad=nCellsBad+1;
                    cellsToDelete(nCellsBad)=matchInd;
                end
            end
        end
    end
end
cellsToDelete=cellsToDelete(1:nCellsBad);
finalCellParams(cellsToDelete,:)=[];
allCellImgs=calcCellImgs(finalCellParams, imgSize);
goodCellInds=1:nCells;
goodCellInds(cellsToDelete)=[];

if calcTraces
    finalCellTraces = calculateTraces(allCellImgs, imgs, options);
else
    finalCellTraces=[];
end

% from file resolveBorderConflicts on 12/11/13 at 6:01pm