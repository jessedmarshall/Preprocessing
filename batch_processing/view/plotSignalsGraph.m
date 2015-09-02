function plotSignalsGraph(IcaTraces,varargin)
    % plots signals, offsetting by a fixed amount
    % biafra ahanonu
    % started: 2013.11.02
    % inputs
        %
    % outputs
        %
    % changelog
        %
    % TODO
        % add options for how much to offset

    %========================
    options.minAdd = 0.05;
    options.maxAdd = 1.1;
    options.LineWidth = 1;
    option.inputXAxis = [];
    % list of traces to plot
    options.plotList = [];
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end
    %========================
    if isempty(options.plotList)
        tmpTrace = IcaTraces;
    else
        tmpTrace = IcaTraces(plotList,:);
    end

    rmList = sum(~isnan(tmpTrace),2)~=0;
    tmpTrace = tmpTrace(rmList,:);
    rmList = sum(tmpTrace,2)~=0;
    tmpTrace = tmpTrace(rmList,:);

    % for i=1:size(tmpTrace,1)
    %     tmpTrace(i,:)=normalizeVector(tmpTrace(i,:),);
    % end
    tmpTrace2 = tmpTrace;
    for i=2:size(tmpTrace,1)
        tmpTrace(i,:)=tmpTrace(i,:)+max(tmpTrace(i-1,:));
        movAvgFiltSize = 3;
        tmpTrace(i,:) = filtfilt(ones(1,movAvgFiltSize)/movAvgFiltSize,1,tmpTrace(i,:));
    end

    tmpTrace = flipdim(tmpTrace,1);
    % option.inputXAxis
    if isempty(option.inputXAxis)
        plot(tmpTrace','LineWidth',options.LineWidth);
    else
        display('================')
        display('custom x-axis')
        plot(option.inputXAxis,tmpTrace','LineWidth',options.LineWidth);
    end

    axis([0 size(tmpTrace,2) min(tmpTrace(:))-options.minAdd options.maxAdd*max(tmpTrace(:))]);
    box off;

    % for i=1:size(normalTrace,1)
    %     figure(42)
    %     subplot(2,1,1)
    %     plot(IcaTraces(i,:));
    %     subplot(2,1,2)
    %     plot(normalTrace(i,:));
    %     [x,y,reply]=ginput(1);
    % end

    % figure(6)
    % tmpTrace = normalTrace;
    % for i=2:size(tmpTrace,1)
    %     tmpTrace(i,:)=tmpTrace(i,:)+max(tmpTrace(i-1,:))+.1;
    % end
    % plot(tmpTrace([1:20],:)');

    % axis([0 nFrames -0.5 max(tmpTrace([1:20]))+1]);

    % setFigureDefaults();

    % check if two IC traces have correlation
    % l=corrcoef([bandpass' normal']);
    % l(l<0.8)=0;
    % imagesc(l(1:600,600:1400));
    % xlabel('pure DFOF cells');
    % ylabel('bandpass cells');
    % title('bandpass vs normal');

    % figure(42)
    % subplot(3,1,1)
    % plot(IcaTraces(ICtoCheck,:));
    % subplot(3,1,2)
    % plot(normalTrace);
    % subplot(3,1,3)
    % plot(thresholdedTrace);
