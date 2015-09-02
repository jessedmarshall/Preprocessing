function [testpeaks] = identifySpikes(inputSignal, varargin)
    % identifies peaks in an input signal given a particular threshold and other parameters.
    % biafra ahanonu
    % started: 2013.10.28
    % adapted from Lacey Kitch's and Laurie Burns' code
    % inputs
        %
    % outputs
        %
    % changelog
        % 2013.11.18 [20:06:00]
    % TODO
        %

    %========================
    % number of standard deviations above the threshold to count as spike
    options.numStdsForThresh = 3;
    % minimum number of time units between events
    options.minTimeBtEvents = 10;
    % make a plot?
    options.makePlots = 0;
    % the size of the moving average
    options.movAvgReqSize = 2;
    options.movAvgFiltSize = 3;
    % decide whether to have a moving average
    options.doMovAvg = 1;
    % report the midpoint of the rise
    options.reportMidpoint=0;
    % shift peak detection
    options.nFramesShift = 0;
    % get options
    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end;
    %========================

    % moving average of input signal
    if doMovAvg
        inputSignal = filtfilt(ones(1,movAvgFiltSize)/movAvgFiltSize,1,inputSignal);
    end

    % get standard deviation of current signal
    thisStdThreshold = std(inputSignal(:))*numStdsForThresh;
    % run findpeaks (part of signal), returns maxima above thisStdThreshold
    % and ignores smaller peaks around larger maxima within minTimeBtEvents
    warning off
    [~,testpeaks] = findpeaks(inputSignal,'minpeakheight',thisStdThreshold,'minpeakdistance',minTimeBtEvents);
    warning on
    % ignores smaller peaks around larger maxima within minTimeBtEvents
    %[~,testpeaks2] = findpeaks(inputSignal,'minpeakdistance',minTimeBtEvents);
    %testpeaks = intersect(testpeaks,testpeaks2);
    % extra check
    testpeaks = intersect(testpeaks,find(...
        filtfilt(ones(1,movAvgReqSize)/movAvgReqSize,1,inputSignal)>thisStdThreshold)...
        );
    % shift peaks
    testpeaks = testpeaks - options.nFramesShift;

    % decide whether to plot the peaks with points indicating location of
    % chosen peaks
    if makePlots==1
        setFigureDefaults()
        fig1 = figure(422);
        set(gcf,'color','w');
        scnsize = get(0,'ScreenSize');
        position = get(fig1,'Position');
        outerpos = get(fig1,'OuterPosition');
        borders = outerpos - position;
        edge = -borders(1)/2;
        %pos1 = [scnsize(3)/2 + edge, 0, scnsize(3)/2 - edge, scnsize(4)];
        pos1 = [0, 0, scnsize(3), scnsize(4)];
        set(fig1,'OuterPosition',pos1);

        plot(inputSignal, 'r');
        set(gca,'Color','none'); box off;
        axis([0 length(inputSignal) -0.1 0.5]);
        hold on;
        scatter(testpeaks, inputSignal(testpeaks), 'LineWidth',2,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0])
        [x,y,reply]=ginput(1);
        hold off;
        % close(fig1);
    end