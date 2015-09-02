function [badCells,avgIntensityInHull,areas,fracBrightPixInHull,SNR,nEvents] = detectBadCells(imgs, allCellImages, allCellTraces,...
    allCellParams, noiseSigma, varargin)

% written by Lacey Kitch in 2014

% initial threshold-based classifier / feature viewer for detecting bad
% cells from EM output

% varargin options struct:
% options.manualSelect - set to 1 to select bad cells manually (default 0)
% options.plotFeatures - set to 1 to plot features for manually selected
%   cells (default 0)
% options.optionsED - options structure for event detection (see
%   detectEvents)
% options.eventTimes - cell, as output by detectEvents, with event times
% options.maxArea - maximum area, criterion for automated cell selection 
%   (default 200 pixels)
% options.minFracBrightPix - minimum fraction of pixels in the event triggered
%   average, within the shape of the gaussian, that are "bright" (>0.5*max)
% options.minAvgIntensity - minimum average intensity of the
%   event-triggered average inside the shape of the gaussian

manualSelect=0;
plotFeatures=0;
minFracBrightPix=0.03;
maxArea=200;
minSNR=4;
minAvgIntensity=2*noiseSigma;
haveEventTimes=0;
if ~isempty(varargin)
    options=varargin{1};
    
    % options for event detection
    if isfield(options, 'optionsED')
        optionsED=options.ED;
    end
    
    % already calculated event times
    if isfield(options, 'eventTimes')
        eventTimes=options.eventTimes;
        haveEventTimes=1;
    end
    
    % select bad cells manually
    if isfield(options,'manualSelect')
        manualSelect=options.manualSelect;
    end
    
    % sorting parameters, if input
    if isfield(options, 'maxArea')
        maxArea=options.maxArea;
    end
    if isfield(options, 'minFracBrightPix')
        minFracBrightPix=options.minFracBrightPix;
    end
    if isfield(options, 'minAvgIntensity')
        minAvgIntensity=options.minAvgIntensity;
    end
    if isfield(options, 'minSNR')
        maxArea=options.minSNR;
    end
    
    if isfield(options, 'plotFeatures')
        plotFeatures=options.plotFeatures;
        if isfield(options, 'badCellsManual')
            badCellsManual=options.badCellsManual;
        end
    end
end
    
% parameters and initializations
nCells=size(allCellImages,3);
avgIntensityInHull=zeros(1,nCells);
fracBrightPixInHull=zeros(1,nCells);
nEvents=zeros(1,nCells);
SNR=zeros(1,nCells);

% detect events if you don't have them already
if ~haveEventTimes
    optionsED.noiseSigma=noiseSigma;
    eventTimes=detectEvents(allCellTraces, optionsED);
end

% get event-triggered images and convex hulls
[cvxHulls,areas,binImages]=getConvexHull(allCellImages);
[eventTrigImages,~]=getEventTriggeredImages(imgs, eventTimes, ...
    allCellParams, allCellImages, allCellTraces);

% fill property/feature vectors
for cInd=1:nCells
    nEvents(cInd)=length(eventTimes{cInd});    
    thisEventTrigImg=eventTrigImages(:,:,cInd)-1;
    avgIntensityInHull(cInd)=sum(sum(thisEventTrigImg(binImages(:,:,cInd))))/areas(cInd);
    fracBrightPixInHull(cInd)=sum(thisEventTrigImg(:)>0.5*max(thisEventTrigImg(:)))/areas(cInd);
    thisTrace=allCellTraces(cInd,:);
    if nEvents(cInd)>0
        SNR(cInd)=mean(thisTrace(eventTimes{cInd}))/std(thisTrace(thisTrace<3*noiseSigma));
    end
end

% do the automatic sorting
badCellsAuto=sort(find(or(fracBrightPixInHull<minFracBrightPix,...
    or(SNR<minSNR,...
    or(areas>maxArea,...
    or(avgIntensityInHull<minAvgIntensity,...
    nEvents==0))))));

% do manual sorting, if desired
% if you choose to select manually, badCells will be a structure.
% otherwise, it will be a vector will cell indices, from the auto-sorting
if manualSelect
    badCellsManual = manualClassifyCells(eventTrigImages, cvxHulls, allCellTraces, eventTimes);
        badCells.badCellsAuto=badCellsAuto;
    badCells.badCellsManual=badCellsManual;
else
    badCells=badCellsAuto;
end


% if you do manual selection, you can plot the features to look at ideal
% sorting values
if plotFeatures && exist('badCellsManual', 'var')

    figure;
    subplot(2,2,1)
    plot(1:nCells,avgIntensityInHull,'g.')
    hold on
    plot(badCellsManual,avgIntensityInHull(badCellsManual), 'r.')
    plot([0 nCells], minAvgIntensity*ones(2,1), '--', 'Color', [0.7 0.7 0.7])
    ylim([min(avgIntensityInHull), max(avgIntensityInHull)]); xlim([0 nCells])
    ylabel('Avg Intensity')

    subplot(2,2,2)
    plot(1:nCells,areas,'g.')
    hold on
    plot(badCellsManual,areas(badCellsManual), 'r.')
    plot([0 nCells], maxArea*ones(2,1), '--', 'Color', [0.7 0.7 0.7])
    ylim([min(areas), max(areas)]); xlim([0 nCells])
    ylabel('Area')

    subplot(2,2,3)
    plot(1:nCells,fracBrightPixInHull,'g.')
    hold on
    plot(badCellsManual,fracBrightPixInHull(badCellsManual), 'r.')
    plot([0 nCells], minFracBrightPix*ones(2,1), '--', 'Color', [0.7 0.7 0.7])
    ylim([min(fracBrightPixInHull), max(fracBrightPixInHull)]); xlim([0 nCells])
    ylabel('Fraction bright pixels')
    
    subplot(2,2,4)
    plot(1:nCells,SNR,'g.')
    hold on
    plot(badCellsManual,SNR(badCellsManual), 'r.')
    %plot([0 nCells], minFracBrightPix*ones(2,1), '--', 'Color', [0.7 0.7 0.7])
    ylim([min(SNR), max(SNR)]); xlim([0 nCells])
    ylabel('SNR')
end
end