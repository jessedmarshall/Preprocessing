function [allCellTraces, eventTimes, eventTrigImages] =...
    calcTracesEventsImagesFromImgs(movie, allCellImgs, noiseSigma, varargin)

% Written by Lacey Kitch in 2014

% function to recalculate traces, events, and event-triggered images for a
%   given set of cell parameters and a given movie
% recommended use: run EM_main on a temporally downsampled (ie 5 hz) movie,
%   then run this function on the calculated cell parameters with a full 
%   time resolution (ie 20hz) movie

doEventDetect=1;
outputEventTrigImages=1;
if ~isempty(varargin)
    options=varargin{1};
    
    if isfield(options, 'detectEvents')
        doEventDetect=options.detectEvents;
    end
    if isfield(options, 'optionsED')
        optionsED=options.optionsED;
    end
    if isfield(options, 'outputEventTrigImages')
        outputEventTrigImages=options.outputEventTrigImages;
    end
else
	options=[];
end


% calculate traces
centroidOptions.icSizeThresh=0;
[icCentroids,~,~] = getICcentroids(allCellImgs,[],centroidOptions);
allCellTraces = calculateTraces(allCellImgs,movie,options);
allCellParams=[icCentroids, 5*ones(size(icCentroids)), zeros(size(icCentroids,1),1)];

% do final event detection and spike triggered image calculation, if
% options set to do so
if doEventDetect
    optionsED.noiseSigma=noiseSigma;
    optionsED.reportMidpoint=0;
    [eventTimes,~] = detectEvents2(allCellTraces);
    if outputEventTrigImages
        eventTrigImages=getEventTriggeredImages(movie,eventTimes,allCellParams);
    else
        eventTrigImages=[];
    end
else
    eventTimes=[];
    eventTrigImages=[];
end