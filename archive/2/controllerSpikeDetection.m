function [signalSpikes, signalSpikesArray] = controllerSpikeDetection(signalMatrix, varargin)
    % biafra ahanonu
    % started: 2013.10.28
    % controller to digitize [0,1] an input matrix containing analog
    % signals
    % input
    %   signalMatrix: nSignals*time matrix

    % changelog
    % TODO:
        % 1. allow input of options file (e.g. for different GCaMP variants, brain regions, etc.)
        % 2. integrate nearest neighbor into analysis if there is a lot of cross-talk

    % add controller directory and subdirectories to path
    addpath(genpath(pwd));

    % get options
    % make a plot?
    options.makePlots = 0;
    options.makeSummaryPlots = 1;

    options = getOptions(options,varargin);
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %     eval([fn{i} '=options.' fn{i} ';']);
    % end

    % this matrix will contain digital version of signalMatrix
    signalSpikes = zeros(size(signalMatrix));
    % contains a list for each signal of locations of peaks
    signalSpikesArray = {};
    % open waitbar
    waitbarHandle = waitbar(0, 'detecting traces...');
    % loop over all signals. TODO: convert to parfor, convert signalMatrix
    % to cell array to allow this
    nSignals = size(signalMatrix,1);
    for signalNum=1:nSignals
        % get the current signal and find its peaks
        thisSignal = signalMatrix(signalNum,:);
        signalSpikesArray{signalNum} = identifySpikes(thisSignal, 'makePlots', options.makePlots, 'numStdsForThresh', 3, 'minTimeBtEvents', 20);
        signalSpikes(signalNum,signalSpikesArray{signalNum})=1;
        % reduce waitbar access
        if(mod(signalNum,50)==0)
            waitbar(signalNum/nSignals,waitbarHandle)
        end
    end
    close(waitbarHandle);

    % summary of general statistics for this set of IC data
    if options.makeSummaryPlots==1
        viewSpikeSummary(signalMatrix,signalSpikes);
    end

    % path(pathdef);

% function [options] = getOptions(varargin)
%     % gets default options for the function

%     %Process options
%     validOptions = fieldnames(options);
%     varargin = varargin{1};
%     for i = 1:2:length(varargin)
%         val = varargin{i};
%         if ischar(val)
%             %display([varargin{i} ': ' num2str(varargin{i+1})]);
%             if ~isempty(strmatch(val,validOptions))
%                 eval(['options.' val '=' num2str(varargin{i+1}) ';']);
%             end
%         else
%             continue;
%         end
%     end
%     %display(options);