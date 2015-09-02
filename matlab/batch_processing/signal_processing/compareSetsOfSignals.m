function compareSetsOfSignals(inputSignals,inputImages,varargin)
    % compares sets of signals and images to see if they are different across a range of parameters
    % biafra ahanonu
    % started: 2013.12.09
    % inspired by code of jesse marshall 20131209
    % inputs
        % inputSignals - cell array of signals
        % inputImages - cell array of images
    % outputs
        %
    % changelog
        % updating 2013.12.09: started re-factoring to make more general
    % TODO
        % Kolmogorov–Smirnov test or other tests to determine whether the two sets come from the same distribution

    %========================
    options.waitbarOn = 1;
    % get options
    options = getOptions(options,varargin);
    % fn=fieldnames(options);
    % for i=1:length(fn)
    % eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    nSets = length(inputSignals);

    for thisSet=1:nSets
        thisSetSignals = inputSignals{thisSet};
        thisSetImages = inputImages{thisSet};

        % get the peak statistics for the signal
        [peakOutputStat] = computePeakStatistics(thisSetSignals);

        % compare the peak amplitudes of all signals

        % compare fwhm

        % compare the slope ratios

    end