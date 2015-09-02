function plotIcaTraces(IcaTraces, nList)
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
    tmpTrace = IcaTraces(nList,:);
    for i=2:size(tmpTrace,1)
        tmpTrace(i,:)=tmpTrace(i,:)+max(tmpTrace(i-1,:))+.1;
    end
    plot(tmpTrace');

    axis([0 size(tmpTrace,2) -0.5 max(tmpTrace([1:20]))+1]);
    box off;

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
