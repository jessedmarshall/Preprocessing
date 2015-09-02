function [allCellTraces, eventTimes, eventTrigImages, noiseSigmas] =...
    calcTracesEventsImages(movie, allCellParams, noiseSigma, varargin)

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
    
    if isfield(options, 'doEventDetect')
        doEventDetect=options.doEventDetect;
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


% get cell images and calculate traces
allCellImgs=calcCellImgs(allCellParams, size(movie(:,:,1)));
allCellTraces = calculateTraces(allCellImgs, movie, options);


% do final event detection and spike triggered image calculation, if
% options set to do so
noiseSigmas=zeros(size(allCellParams,1),1);
if doEventDetect
    optionsED.noiseSigma=noiseSigma;
    optionsED.reportMidpoint=0;
    [eventTimes,eventsCell] = detectEvents2(allCellTraces);
    for cInd=1:size(allCellParams,1)
        noiseSigmas(cInd)=eventsCell{cInd}.sigma;
    end
    if outputEventTrigImages
        eventTrigImages=getEventTriggeredImages(movie,eventTimes,allCellParams);
    else
        eventTrigImages=[];
    end
else
    eventTimes=[];
    eventTrigImages=[];
end