function [allCellImages, allCellTraces, allCellParams, noiseSigma, eventTimes, eventTrigImages] =...
    EM_main(movie, framerate, pixelSize, sqSize, varargin)

% Written by Lacey Kitch in 2013-2014

%%% This function will execute the cell-finding algorithm.
%%% It chunks the field of view and does the estimation on each chunk
%%% separately, then resolves border conflicts by collapsing cells that
%%% have similar shapes. After the collapse, it recalculates the most
%%% likely traces for all cells.

% Inputs:
% movie: the data. should be a 3D matrix, space x space x time.
%       - Should be centered around 1, ie DFOF.
%       - I have only test on lowpass-divisive-normalized movies. Others
%       might work. Need to test.
%       - Running on 5Hz data is best for noise elimination and runtime. 
%       Then can use calcTracesEventsImages to calculate the traces from 
%       the 20Hz movie.
% framerate: in hz. 5hz and 20hz movies both seem to work.
% pixelSize: size of the edge of one pixel, in um. take downsampling into
%   account.
% sqSize: size of the chunk of data that the algorithm will work with at
%   one time. sqSize=30 means the algorithm will run on a 30x30 square chunk.
%	For each chunk, the data will be tripled in RAM, so if your computer can't
%	handle tripling a 40 x 40 x nFrames single matrix, don't use sqSize=40
%   Optimal for speed, RAM, and accuracy is about 30-40. Using less than 25
%	will be inaccurate.
% varargin: options struct.
%	options.suppressOutput - set to 1 to suppress command line output (default is 0)
%   options.suppressProgressFig - set to 1 to suppress the figure that
%       displays progress in the movie
%	options.icImgs - images of ICA output to use in EM initialization. (optional)
%	options.icTraces - traces of ICA output to use in EM initialization. (optional)
%   options.initWithICsOnly - set to 1 to initialize ONLY with the ICA
%       results, and not use the initialization based on max val timing
%   options.vlm - set to 1 if processing vlm data
%   options.doEventDetect - set to 0 to skip event detection at the end
%       (default is 1)
%   options.optionsED - options structure for event detection (see
%       detectEvents)
%   options.outputSpikeTrigImages - set to 0 to skip calculating
%       event-triggered images for each cell (default is 1)
%   options.recalculateFinalTraces - set to 0 to skip recalculating the
%       final traces after conflict resolution at the end, and to skip trace
%       calculation at the end of each iteration - ONLY set this to 0 if you
%       will be recalculating the traces with a different movie (ie full time
%       resolution) later (default is 1)

% Outputs:
% allCellImages: images of the estimated shape of each cell.
%    array size: nypixels x nxpixels x total # cells.
% allCellTraces: estimated fluorescence values for all cells.
%    array size: total # cells x # frames.
% allCellParams: parameters of the estimated shape of each cell.
%    array size: total # cells x 5 (x centroid, y centroid, x std dev, y std dev, angle)
% noiseSigma: the std dev of the noise of the whole movie
% spikeTrigImages: the event-triggered images of each cell (better for
%   making cell maps than the gaussian images, and better for detecting
%   crap)
% eventTimes: cell containing events for each trace, as calculated by
%   detectEvents

areaOverlapThresh=0.65;
doEventDetect=1;
outputSpikeTrigImages=1;
recalculateFinalTraces=1;
suppressOutput=1;
suppressProgressFig=0;
initWithGrid=0;
vlm=0;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'suppressOutput')
        suppressOutput=options.suppressOutput;
    else
        suppressOutput=0;
    end
    if isfield(options, 'suppressProgressFig')
        suppressProgressFig=options.suppressProgressFig;
    else
        suppressProgressFig=1;
    end
    if isfield(options, 'vlm')
        vlm=options.vlm;
    end
    if isfield(options, 'detectEvents')
        doEventDetect=options.doEventDetect;
    end
    if isfield(options, 'optionsED')
        optionsED=options.optionsED;
    end
    if isfield(options, 'outputSpikeTrigImages')
        outputSpikeTrigImages=options.outputSpikeTrigImages;
    end
    if isfield(options, 'recalculateFinalTraces')
        recalculateFinalTraces=options.recalculateFinalTraces;
    end
    if isfield(options, 'areaOverlapThresh')
        areaOverlapThresh=options.areaOverlapThresh
    end
else
	options=[];
end


% chunking parameters
sqInc=floor(sqSize-10);
if sqInc<5
    sqInc=5;
end

% output parameters
makeMoviesEachSquare=0;
writeAVI=0;              %#ok<NASGU>
filename='ResultsMovie'; %#ok<NASGU>
plotCentroids=1;         %#ok<NASGU>
plotTraces=1;            %#ok<NASGU>

% initialization parameters
if ~vlm
    numSigmasThresh=2;
    timeWiggleRoom=max(ceil(6*framerate/19),2); % units = frames
    minCellArea=pi*6^2/(pixelSize^2); % min area = circle with radius 6um
    maxCellArea=1000;
else
    numSigmasThresh=1;
    timeWiggleRoom=max(ceil(10*framerate/19),2); % units = frames
    minCellArea=5;
    maxCellArea=1000;
end
% toggles for checking initialization
displayRegions=0;
displayGaussianFits=0;
displayFramesToFit=0;
displayMovie=0;

% EM parameters
numMuVals=5;
numSigVals=5;
numThetaVals=3;
movie=single(movie);
noiseSigma=fitNoiseSigma(movie,options);
if ~suppressOutput
    noiseSigma %#ok<NOPRT>
end
usePar=0;

% determine size for chunking
nSqVert=ceil((size(movie,1)-10)/sqInc);
nSqHorz=ceil((size(movie,2)-10)/sqInc);
progressSquare=zeros(nSqVert,nSqHorz);
if ~suppressProgressFig
    figure(101); imagesc(progressSquare); set(gca, 'CLim', [0 1]); colormap(gray);
    set(gca, 'XTick', [], 'YTick', []); title('Progress in movie space...'); drawnow
end

% store all results together
maxCellsPerSq=round(40*sqSize^2/(20^2));
allCellParams=nan(maxCellsPerSq*nSqHorz*nSqVert,5);
allCellTraces=nan(maxCellsPerSq*nSqHorz*nSqVert,size(movie,3));
nCellsSoFar=0;
for vertInd=1:nSqVert
    for horzInd=1:nSqHorz

        progressSquare(vertInd,horzInd)=0.5;
        if ~suppressProgressFig
            % figure(101); stop focus stealing
            imagesc(progressSquare); set(gca, 'CLim', [0 1]); colormap(gray);
            set(gca, 'XTick', [], 'YTick', []); title('Progress in movie space...'); drawnow
        end

        if ~suppressOutput
            disp(['Vert ' num2str(vertInd) ' of ' num2str(nSqVert)])
            disp(['Horz ' num2str(horzInd) ' of ' num2str(nSqHorz)])
        end

        % get chunk of data
        yLims=(vertInd-1)*sqInc+(1:sqSize);
        yLims(yLims>size(movie,1))=[];
        xLims=(horzInd-1)*sqInc+(1:sqSize);
        xLims(xLims>size(movie,2))=[];
        imgs=double(movie(yLims,xLims,:));

        %try
            if ~vlm
                bg=ones(size(imgs(:,:,1)));
            else
                imgs=imgs+1;
                bg=median(imgs,3);
                options.bg=bg;
            end
            if isfield(options, 'icImgs') && isfield(options, 'icTraces')
                [localICimgs,localICtraces] = getLocalICs(options.icImgs,options.icTraces,xLims,yLims);
                options.localICimgs=localICimgs;
                options.localICtraces=localICtraces;
            end

            % segment image by max time and perform gaussian fits to initialize the EM
            threshVal=numSigmasThresh*noiseSigma+1;
            if ~initWithGrid
                cellFitParams = segmentImageByMaxTime_LSsub(imgs, timeWiggleRoom,...
                    threshVal, minCellArea, maxCellArea, displayRegions,...
                    displayGaussianFits, displayFramesToFit, displayMovie, framerate,...
                    areaOverlapThresh, noiseSigma, options);
            else
                cellFitParams = gridInitialize(imgs);
            end
            nCells=size(cellFitParams,1);
            if ~suppressOutput
                nCells %#ok<NOPRT>
            end

            if nCells>0
                % perform EM

                [estCellTraces, estParams, nIterations] =...
                    EM_cellShapesAndTraces(numMuVals, numSigVals, numThetaVals,...
                    imgs, cellFitParams, noiseSigma, bg, usePar, areaOverlapThresh, options); %#ok<NASGU>

                if makeMoviesEachSquare
                    makeResultsMovie(imgs, estParams, estCellTraces, writeAVI,...
                        plotCentroids, plotTraces, [], filename); %#ok<UNRCH>
                end

                estParams(:,1)=estParams(:,1)+xLims(1)-1;
                estParams(:,2)=estParams(:,2)+yLims(1)-1;
                nCells=size(estParams,1);
                allCellParams(nCellsSoFar+(1:nCells),:)=estParams(:,1:5);
                allCellTraces(nCellsSoFar+(1:nCells),:)=estCellTraces;
                nCellsSoFar=nCellsSoFar+nCells;
            end
       %catch err
       %     disp(['Error thrown on vert block ' num2str(vertInd) ', horz block ' num2str(horzInd) ', message: ' err.message])
       %end

        progressSquare(vertInd,horzInd)=1;
    end
end

% update the progress figure, if using
if ~suppressProgressFig
    figure(101); imagesc(progressSquare); set(gca, 'CLim', [0 1]); colormap(gray);
    if recalculateFinalTraces
        set(gca, 'XTick', [], 'YTick', []); title('Done with shape estimation, resolving conflicts and calculating final traces...'); drawnow
    else
        set(gca, 'XTick', [], 'YTick', []); title('Done with shape estimation, resolving conflicts...'); drawnow
    end
end

% chop off the unused portion of param storage
allCellParams(isnan(allCellParams(:,1)),:)=[];
allCellTraces(isnan(allCellTraces(:,1)),:)=[];

% if we ran EM on more than one square, resolve conflicts and reculate
% traces
if nSqVert>1 || nSqHorz>1
    if recalculateFinalTraces
        calcTraces=1;
    else
        calcTraces=0;
    end
    [allCellImages,allCellParams,allCellTraces]=resolveBorderConflicts(allCellParams,...
        areaOverlapThresh,movie,calcTraces,options);
else
    allCellImages=calcCellImgs(allCellParams, size(movie(:,:,1)));
end

% eliminate any cells that were set as redundant during the svd check in
% the trace calculation (slightly different from resolve conflicts fnc)
redunCells=sum(allCellTraces,2)==0;
allCellTraces(redunCells,:)=[];
allCellParams(redunCells,:)=[];
allCellImages(:,:,redunCells)=[];

% if toggle for calculating traces is off, don't output any traces, since
% they're not accurate
if ~recalculateFinalTraces
    allCellTraces=[];
    eventTimes=[];
    eventTrigImages=[];
else
    % do final event detection and spike triggered image calculation, if
    % options set to do so
    if doEventDetect
        optionsED.noiseSigma=noiseSigma;
        optionsED.reportMidpoint=0;
        [eventTimes,~,~] = detectEvents(allCellTraces, optionsED);
        if outputSpikeTrigImages
            eventTrigImages=getEventTriggeredImages(movie,eventTimes,allCellParams);
        else
            eventTrigImages=[];
        end
    else
        eventTimes=[];
        eventTrigImages=[];
    end
end

% update the progress figure, if using
if ~suppressProgressFig
    close(101)
end