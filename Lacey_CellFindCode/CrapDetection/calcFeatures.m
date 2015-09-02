function featureValues = calcFeatures(allCellTraces, allCellParams,...
    eventTrigImages, eventTimes, noiseSigmas)

normByMedWidth=0;
normBySoftMax=1;

eventTrigImages(isnan(eventTrigImages))=1;

% get convex hulls, binary images, and areas
cellImages=calcCellImgs(allCellParams, size(eventTrigImages(:,:,1)));
[~,areas,binImages] = getConvexHull(cellImages);
if size(areas,2)>1
    areas=areas';
end
clear cellImages

% get noise std devs for individual cells if they are not input
if length(noiseSigmas)==1
    [~,eventsCell] = detectEvents2(allCellTraces);
    nCells=length(eventsCell);
    noiseSigmas=ones(1,nCells);
    for cInd=1:nCells
        noiseSigmas(cInd)=eventsCell{cInd}.sigma;
    end
end

% calculate all features/properties
% could skip calculating some according to booleans above
nCells=size(allCellTraces,1);
nEvents=zeros(nCells,1);   
avgIntensityInHull=zeros(nCells,1);
fracBrightPixInHull=zeros(nCells,1);
fracBrightPixInVsOut=zeros(nCells,1);
SNR=zeros(nCells,1);
for cInd=1:nCells
    if isstruct(eventTimes{cInd})
        eventTimes{cInd}=eventTimes{cInd}.peakind;
    end
    nEvents(cInd)=length(eventTimes{cInd});    
    thisEventTrigImg=eventTrigImages(:,:,cInd)-1;
    if areas(cInd)>0
        maxPixVal=max(thisEventTrigImg(:));
        avgIntensityInHull(cInd)=sum(sum(thisEventTrigImg(binImages(:,:,cInd))))/areas(cInd);
        fracBrightPixInHull(cInd)=sum(thisEventTrigImg(binImages(:,:,cInd))>0.5*maxPixVal)/areas(cInd);
        if sum(thisEventTrigImg(binImages(:,:,cInd))>0.5*maxPixVal)>0
            fracBrightPixInVsOut(cInd)=sum(thisEventTrigImg(~binImages(:,:,cInd))>0.5*maxPixVal)/...
                sum(thisEventTrigImg(binImages(:,:,cInd))>0.5*maxPixVal);
        end
    end
    thisTrace=allCellTraces(cInd,:);
    if nEvents(cInd)>0
        if sum(thisTrace<3*noiseSigmas(cInd))>0
            SNR(cInd)=mean(thisTrace(eventTimes{cInd}))/std(thisTrace(thisTrace<3*noiseSigmas(cInd)));
        end
    end
end
peakAsymmetries=calcPeakAsymmetries(allCellTraces, eventTimes, noiseSigmas);
fractionPeaksShared=calcFractionPeaksShared(allCellTraces, eventTimes, allCellParams);

% aggregate the features
featureValues=[nEvents, avgIntensityInHull, fracBrightPixInHull, areas, SNR, peakAsymmetries, fractionPeaksShared, fracBrightPixInVsOut];

for fInd=1:size(featureValues,2)

    if normByMedWidth
        values=featureValues(:,fInd); %#ok<UNRCH>
        zeroInds=values==0;
        medVal=median(values(~zeroInds));
        prcs=prctile(values(~zeroInds),[25 75]);
        width=prcs(2)-prcs(1);
        values=values-medVal;
        if width>0
            values=values/width;
        end
        featureValues(:,fInd)=values;
    end

    if normBySoftMax
        values=featureValues(:,fInd);
        prc=prctile(values,95);
        values=values/prc;
        featureValues(:,fInd)=values;
    end

end