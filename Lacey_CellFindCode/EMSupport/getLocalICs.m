function [localICimgs, localICtraces] = getLocalICs(icImgs,icTraces,xLims,yLims)

if numel(xLims)==2
    xLims=min(xLims):max(xLims);
    yLims=min(yLims):max(yLims);
end

centroidOptions.icSizeThresh=-1;
[icCentroids,~,~] = getICcentroids(icImgs, icTraces, centroidOptions);

goodxCentroids=and(icCentroids(:,1)>(min(xLims)-5), icCentroids(:,1)<(max(xLims)+5));
goodyCentroids=and(icCentroids(:,2)>(min(yLims)-5), icCentroids(:,2)<(max(yLims)+5));
localICinds=and(goodxCentroids, goodyCentroids);

localICimgs=icImgs(yLims,xLims,localICinds);
localICtraces=icTraces(localICinds,:);

