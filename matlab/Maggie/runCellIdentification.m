function runCellIdentification(animaldir, animalprefix, days, varargin)
% runCellIdentification(animaldir, animalprefix, days, varargin)
%
%This function runs Lacey's EM algorithm for each day in days. First, the
%downsampled DFOF is loaded to calculate the cell parameters, then each
%sessions DFOF movies are loaded to calculate traces and bursts at full
%temporal resolution.
%
%Inputs
%   animaldir: Path to the animals data
%   animalprefix: Animal's name
%   days: Experimental days to be processed.
%
%Options:
%   pixelsize: Size of one pixel (um/pixel), take into 
%       account spatial downsampling. Default: 2.4
%   SquareSize: Size movie is broken down into to run at a time. Default: 40.
%
%   EM_main options:
%
%   showOutput: Set to 1 to suppress command line output. Default: 1.
%   showfigure: Set to 1 to suppress progress figure. Default: 0.
%   EventDetectionOptions: Options structure for event detection
%
%--------------------------------------------------------------------------

%Set default options
pixelSize = 2.4; %um / pixel with 4x spatial downsampling
SquareSize = 40;
options.suppressOutput = 1;
options.suppressProgressFig = 0;
options.optionsED = [];
nPCs = 2000;
nICs = 1800;
muVal = 0.1;

%Process options
for i = 1:2:length(varargin)
    val = lower(varargin{i});
    switch val
        case 'pixelsize'
            pixelSize = varargin{i+1};
        case 'squaresize'
            SquareSize = varargin{i+1};
        case 'showfigure'
            options.suppressProgressFig = varargin{i+1};
        case 'showoutput'
            options.suppressOutput = varargin{i+1};
        case 'eventdetectionoptions'
            options.optionsED = varargin{i+1};
        otherwise
            disp('Warning: Option is not defined');
    end
end
clear varargin i val

%Main loop over experiment days
for dayInd=1:length(days)
    
    %Determine whether experiment day or sleep
    if days(dayInd)<1000 %Experiment day
        display(['Running cell identification for day ', num2str(days(dayInd))])
        filepath = [animaldir filesep animalprefix '_' num2str(days(dayInd),'%02g')];
        daystring = num2str(days(dayInd), '%02g');
    else
        display(['Running cell identification for sleep day ', num2str(days(dayInd)-1000)])
        filepath = [animaldir filesep animalprefix '_sleep_' num2str(days(dayInd)-1000,'%02g')];
        daystring = num2str(days(dayInd)-1000, '%02g');
    end
    
    %Load time-downsampled DFOF to estimate traces
    DFOF = load_tif_movie_new([filepath filesep 'DFOF' filesep 'fullSession_DFOF.tif'],1);
    
    %Run PCA-ICA
    [icImgs,icTraces]=pcaIca(DFOF,nPCs,nICs,muVal);
    [~, goodICinds, ~] = getICcentroids(icImgs, icTraces);
    options.icImgs = icImgs(:,:,goodICinds); clear icImgs
    options.icTraces = icTraces(goodICinds,:); clear icTraces goodICinds
    options.initWithICsOnly =1;
    
    %Set options for running EM_main on downsampled DFOF
    options.recalculateFinalTraces = 0;
    options.doEventDetect = 0;
    options.outputSpikeTrigImages = 0;
    framerate = 4;
    
    %Run cell identification for this day
    [CellImages, ~, CellParams, ~, ~, ~] = ...
        EM_main(DFOF, framerate, pixelSize, SquareSize,options); clear DFOF

    %Save CellImages and Parameters
    savestring = [filepath filesep 'CellParams', daystring,'.mat'];
    save(savestring,'CellParams'); clear savestring
    
    savestring = [filepath filesep 'CellImages', daystring ,'.mat'];
    save(savestring,'CellImages'); clear savestring CellImages
    
    %Load full time DFOF
    files = dir([filepath filesep 'DFOF' filesep 'recording_*_DFOF.tif']);
    DFOFsize = zeros(length(files),1); %Preallocate
    for file = 1:length(files)
        if file ==1
            tmp = imfinfo([filepath filesep 'DFOF' filesep files(file).name]);
            DFOFsize(file) = size(tmp,1);
            Width = tmp(1).Width;
            Height = tmp(1).Height; clear tmp
        else
            DFOFsize(file) = size(imfinfo([filepath filesep 'DFOF' filesep files(file).name]),1);
        end                
    end
	DFOFsize = cumsum(DFOFsize);
    DFOF = zeros(Height,Width,DFOFsize(end),'single');
         
    %Loop over files and load movie
    for file = 1:length(files)
        if file == 1
            DFOF(:,:,1:DFOFsize(file)) = load_tif_movie_new([filepath filesep 'DFOF' filesep files(file).name],1);
        else
            DFOF(:,:,1+DFOFsize(file-1):DFOFsize(file)) = load_tif_movie_new([filepath filesep 'DFOF' filesep files(file).name],1);
        end
    end 
	clear file files DFOFsize
    
    %Calculate NoiseSigma
    noiseSigma = fitNoiseSigma(DFOF);
    
    %Save Noise Sigma
    savestring = [filepath filesep 'noiseSigma', daystring,'.mat'];
    save(savestring,'noiseSigma'); clear savestring

    %Set options for Calculating cell traces, eventTimes, and eventImages on full DFOF
    clear options
    options.doEventDetect = 1;
    options.outputEventTrigImages = 1;
    options.optionsED.doSubMedian = 0;
    options.optionsED.doMovAvg = 0;
    options.optionsED.numSigmasThresh=3;
    options.optionsED.calcSigma=0;
    options.optionsED.reportMidpoint=0;
    options.optionsED.minTimeBtEvents=3;
    
    %Calculate cell traces, eventTimes, and eventImages
    [CellTraces, eventTimes, eventImages] = ...
        calcTracesEventsImages(DFOF, CellParams, noiseSigma, options);
    clear DFOF CellParams options noiseSigma

    %Save Traces, eventTimes, and eventImages
    savestring = [filepath filesep 'CellTraces', daystring,'.mat'];
    save(savestring,'CellTraces'); clear CellTraces savestring

    savestring = [filepath filesep 'eventImages', daystring,'.mat'];
    save(savestring,'eventImages'); clear eventImages savestring
    
    savestring = [filepath filesep 'eventTimes', daystring ,'.mat'];
    save(savestring,'eventTimes'); clear eventTimes savestring
end
