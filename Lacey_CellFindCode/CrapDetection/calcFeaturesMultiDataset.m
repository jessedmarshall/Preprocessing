function featureValues = calcFeaturesMultiDataset(cellTraces, cellParams,...
    eventTrigImages, eventTimes, noiseSigmas, varargin)


useFracBrightPix=1;
useArea=1;
useSNR=1;
useAvgIntensity=1;
useNumEvents=1;
usePeakAsym=1;
useSharedPeaks=1;
useInVsOut=1;
featureValues=[];
plotFeatureHist=0;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'featureValues')
        featureValues=options.featureValues;
    end
    if isfield(options, 'useFracBrightPix')
        useFracBrightPix=options.useFracBrightPix;
    end
    if isfield(options, 'useArea')
        useArea=options.useArea;
    end
    if isfield(options,'useSNR')
        useSNR=options.useSNR;
    end
    if isfield(options, 'useAvgIntensity')
        useAvgIntensity=options.useAvgIntensity;
    end
    if isfield(options, 'useNumEvents')
        useNumEvents=options.useNumEvents;
    end
    if isfield(options, 'usePeakAsym')
        usePeakAsym=options.usePeakAsym;
    end
    if isfield(options, 'useSharedPeaks')
        useSharedPeaks=options.useSharedPeaks;
    end
    if isfield(options, 'useInVsOut')
        useInVsOut=options.useInVsOut;
    end
end

if isempty(featureValues)
    
    if ~iscell(cellParams)
        nCellsTotal=size(cellTraces,1);
    else
        numCells=zeros(length(cellParams),1);
        for datasetInd=1:length(cellParams)
            numCells(datasetInd)=size(cellParams{datasetInd},1);
        end
        nCellsTotal=sum(numCells);
    end
    
    if ~iscell(cellParams)
        featureValues = calcFeatures(cellTraces,cellParams,eventTrigImages,eventTimes,noiseSigmas);
    else
        for datasetInd=1:length(cellParams)
            
            theseFeatureValues = calcFeatures(cellTraces{datasetInd},cellParams{datasetInd},...
                eventTrigImages{datasetInd},eventTimes{datasetInd},noiseSigmas{datasetInd});
            
            if plotFeatureHist
                for fInd=1:size(theseFeatureValues,2)
                     figure(fInd)
                     subplot(1,length(cellParams),datasetInd)
                     hist(theseFeatureValues(:,fInd),50)
                end
            end
            
            if datasetInd==1
                featureValues=zeros(nCellsTotal,size(theseFeatureValues,2));
                featureValues(1:numCells(1),:)=theseFeatureValues;
            else
                featureValues(sum(numCells(1:(datasetInd-1)))+(1:numCells(datasetInd)),:)=theseFeatureValues; %#ok<AGROW>
            end
        end
    end
end


featuresToUse=logical([useNumEvents, useAvgIntensity, useFracBrightPix, useArea, useSNR, usePeakAsym, useSharedPeaks, useInVsOut]);
featureValues=featureValues(:,featuresToUse);