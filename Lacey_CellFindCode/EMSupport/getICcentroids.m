function [icCentroids, goodICinds, icTraces] = getICcentroids(icImgs, icTraces, varargin)

icSizeThresh=8;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options,'icSizeThresh')
        icSizeThresh=options.icSizeThresh;
    end
end

nICs=size(icImgs,3);
icCentroids=zeros(nICs,2);
goodICinds=zeros(1,nICs);
cellInd=0;
for icInd=1:nICs
    
    thisIC=icImgs(:,:,icInd);
    
    [maxVal,maxLoc]=max(thisIC(:));
    
    thisIC(thisIC<0.5*maxVal)=0;
    thisIC(thisIC<=0)=0;
    thisIC(thisIC>0)=1;
    
    thisIClabel=bwlabel(logical(thisIC),4);
    bwIC=thisIClabel==thisIClabel(maxLoc);
    icSize=sum(bwIC(:));
    
    if icSize>=icSizeThresh
        cellInd=cellInd+1;
        info=regionprops(bwIC,'Centroid');
        icCentroids(cellInd,:)=info.Centroid;
        goodICinds(cellInd)=icInd;
    end
end
goodICinds=goodICinds(1:cellInd);
icCentroids=icCentroids(1:cellInd,:);
% 
% if ~isempty(icTraces)
% 	icTraces=icTraces(goodICinds,:);
% end