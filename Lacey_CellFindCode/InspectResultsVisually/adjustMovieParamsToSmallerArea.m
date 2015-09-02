function [imgs, params, traces, outOfRangeCells] = adjustMovieParamsToSmallerArea(imgs, imgsXLims, imgsYLims, params, traces)

if length(imgsYLims)~=size(imgs,1) || length(imgsXLims)~=size(imgs,2)
    imgs=imgs(imgsYLims,imgsXLims,:);
end
outOfRangeCells=or(params(:,1)<(min(imgsXLims)-4),...
    params(:,1)>(max(imgsXLims)+4));
outOfRangeCells=or(outOfRangeCells,...
    or(params(:,2)<(min(imgsYLims)-4),...
    params(:,2)>(max(imgsYLims)+4)));
params(outOfRangeCells,:)=[];
traces(outOfRangeCells,:)=[];
params(:,1)=params(:,1)-min(imgsXLims)+1;
params(:,2)=params(:,2)-min(imgsYLims)+1;