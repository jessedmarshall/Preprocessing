function [cvxHulls,areas,binImages] = getConvexHull(cellImages)

% Written by Lacey Kitch in 2014

nCells=size(cellImages,3);
binImages=false(size(cellImages));

cvxHulls=cell(1,nCells);
areas=zeros(1,nCells);

for cInd=1:nCells
    
    thisImage=cellImages(:,:,cInd);

    maxVal=max(thisImage(:));
    thisImage(thisImage<0.4*maxVal)=0;
    thisImage(thisImage>0)=1;
    thisImage=logical(thisImage);
    
    binImages(:,:,cInd)=thisImage;

    info=regionprops(thisImage, 'ConvexHull', 'Area');
    if length(info)>1
        maxArea=-1;
        maxInd=0;
        for regInd=1:length(info)
            if info(regInd).Area>maxArea
                maxArea=info(regInd).Area;
                maxInd=regInd;
            end
        end
        cvxHulls{cInd}=info(maxInd).ConvexHull;
        areas(cInd)=info(maxInd).Area;
    elseif ~isempty(info)    
        cvxHulls{cInd}=info.ConvexHull;
        areas(cInd)=info.Area;
    end
    
end