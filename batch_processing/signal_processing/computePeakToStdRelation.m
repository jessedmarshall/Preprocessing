function [numSpikes] = computePeakToStdRelation(inputSignal,varargin)
    % gets the relationship between the standard deviation and number of peaks detected for empirical determination of threshold
    % biafra ahanonu
    % started: 2013.12.14
    % inputs
        %
    % outputs
        %
    % changelog
        %
    % TODO
        %

    %========================
    % get options
    options.stdvSeq = [0.5:0.5:6];
    options.makePlots = 0;
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================


    i = 1;
    for stdv=options.stdvSeq
        [signalSpikes ~] = computeSignalPeaks(inputSignal, 'makePlots', 0,'makeSummaryPlots',0, 'numStdsForThresh',stdv);
        numSpikes(i) = sum(sum(signalSpikes));
        i = i+1;
    end

    if options.makePlots==1
        figure(1111)
        subplot(1,2,1)
        plot(options.stdvSeq,numSpikes);box off;
        title('std vs. num detected spikes');xlabel('std above baseline');ylabel('total number of spikes');
        subplot(1,2,2)
        plot(options.stdvSeq,[0 diff(numSpikes)]);box off;
        title('std vs. diff(num detected spikes)');xlabel('std above baseline');ylabel('diff(total number of spikes)');
        drawnow;
        % [x,y,reply] = ginput();
    end