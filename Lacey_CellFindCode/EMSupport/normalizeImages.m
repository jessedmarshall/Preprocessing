function normImgs = normalizeImages(origImgs)

normImgs=zeros(size(origImgs));

for imgInd=1:size(origImgs,3)
    thisImg=origImgs(:,:,imgInd);
    normImgs(:,:,imgInd)=thisImg/(max(thisImg(:)));
end
