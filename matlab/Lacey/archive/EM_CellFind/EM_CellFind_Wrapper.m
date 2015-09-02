function [output, DFOF] = EM_CellFind_Wrapper(dsMovieFilename, movieFilename, varargin)

% EM Cell Find : Wrapper function
% Written by Lacey Kitch in 2013-2014

% ------------------------------------------------------------------------
% Inputs
% dsMovieFilename : filename, including path, of the temporally downsampled
%   movie. The movie should be normalized and centered around 1 (ie DF/F).
%   Anything in the range 3Hz-6Hz will work. Higher framerate is fine but
%   will be slower (scales linearly with movie length).
% movieFilename : filename (hdf5) or folder pathname (many tif files), of the movie
%   at full temporal resolution. The movie should be normalized and 
%   centered around 1. Input [] to skip this step.
% 
% options : options structure. all inputs optional.
%   options.dsMovieDatasetName : if using an hdf5 file, dataset name of 
%       the downsampled movie in the hdf5 file
%   options.movieDatasetName : if using an hdf5 file, dataset name of 
%       the full resolution movie in the hdf5 file
%   options.EMoptions : options structure for main EM function. Defaults
%       should be fine for most purposes, but see EM_genFilt_main for
%       description of possible options.
%   options.movieTifRegExp : regular expression to be used to find tif
%       files in the specified folder. Default is 'recording_*.tif' to
%       follow the Inscopix naming convention as of late 2013
%   options.eventOptions : options structure for event detection. See
%       detectEventsOnPhi.m for parameters. Main options are
%       numSigmasThresh (number of standard deviations required over
%       baseline for an event), burstDuration (the length of time that a
%       event must remain above threshold on average, in seconds), and
%       framerate (in Hz)


% Outputs
% output : Output structure
%      output.cellImages : images representing sources found (candidate cells). not all
%        will be cells. Size is [x y numCells]
%      output.centroids : centroids of each cell image, x (horizontal) and 
%        then y (vertical). Size is [numCells 2]
%      output.cellTraces : fluorescence traces for each cell, from the full temporal
%        resolution movie. Size is [numCells numFrames] for numFrames of full
%        movie
%      output.dsCellTraces : fluorescence traces for each cell, from the
%        temporally downsampled movie. Size is [numCells numFrames] for 
%        numFrames of downsampled movie
%      output.dsEventTimes : event timings as output by detectEventsOnPhi.
%        This function calculates event times based on the scaled
%        probability traces output by EM. The timing will be for the
%        downsampled movie.
%      output.dsScaledProbability : a scaled probability trace for each cell, from
%        the downsampled movie. Can be used as a denoised fluorescence trace.
%      output.dsFiltTraces : traces calculated by applying the EM output
%        images as filters to the downsampled move. Will be noisier than
%        output.cellTraces.
%      output.EMoptions : options that EM was run with. Good to keep for
%        recordkeeping purposes.
%      output.eventOptions : options that event detection was run with. 
%        Good to keep for recordkeeping purposes.
% DFOF : The full resolution movie as a single MATLAB array. Warning - this 
%   occupies a lot of RAM! (If no full res movie input, is downsampled movie)
%   ****Delete this variable if you do not need it.
% ------------------------------------------------------------------------

% get options
options.dsMovieDatasetName='/Movie';
options.movieDatasetName='/Movie';
options.movieTifRegExp='recording_*.tif';
options.eventOptions.numSigmasThresh=5;
options = getOptions(options, varargin);

% store filenames in output
output.dsMovieFilename=dsMovieFilename;
output.movieFilename=movieFilename;

% load temporally downsampled data
disp('Loading temporally downsampled data...')
if strcmp(dsMovieFilename(end-2:end), 'tif')
    dsImgs=loadTifSlow(dsMovieFilename);
else
    dsImgs = h5read(dsMovieFilename, options.dsMovieDatasetName);
end
disp('Done loading downsampled data. Running EM CellFind algorithm...')


% run EM
options.EMoptions.recalculateFinalTraces=1;
options.EMoptions.useScaledPhi=1;
options.EMoptions.doEventDetect=0;
options.EMoptions.optionsED=[];
[output.cellImages, output.dsCellTraces, output.centroids, ~, output.dsEventTimes, ~, output.dsScaledProbability, output.EMoptions] =...
    EM_genFilt_main(dsImgs, 'options', options.EMoptions);
output.dsFiltTraces=calculateFilteredTraces(dsImgs, output.cellImages);
[output.dsEventTimes, ~, output.eventOptions] = detectEventsOnPhi(output.dsFiltTraces, output.dsScaledProbability, 'options', options.eventOptions);
disp('Done running EM. Loading full resolution data...')


if ~isempty(movieFilename)
    %load 20hz data and calculate traces/events for EM
    clear dsImgs
    try
        DFOF = h5read(movieFilename, options.movieDatasetName);
    catch
        [DFOF,~]=loadDataFromTif(movieFilename, options.movieTifRegExp);
    end 
    disp('Done loading full resolution data. Calculating most likely traces for full movie...')

    % recalculate EM traces and events
    output.cellTraces = calculateTraces(output.cellImages, DFOF);
    
    % note that scaled probability recalculation is not implemented yet
    % calculate scaledProbability for full res movie and detect events
    %[output.scaledPhi, output.eventTimes] = recalcPhiAndDetectEvents(DFOF, cellImages, dsScaledPhi, output.EMoptions, 'options', output.EMoptions.optionsED);
else
    disp('No full resolution filename input, so skipping full temporal resolution trace calculation.')
    disp('Output DFOF is downsampled movie.')
    DFOF=dsImgs;
end
disp('Done with all, ready for event detection and then manual or automated cell classification.')
