function compareSpikesInputSignal()
    % biafra ahanonu
    % updated: 2013.10.30 [12:45:53]
    % a series of view functions for some comparison input signals

    m561 = dlmread('A:\biafra\data\behavior\open_field\p97\tracking\2013_09_05_p97_m561_oft1.tracking.tab', '\t', 1,0);
     load('A:\biafra\data\behavior\open_field\p97\traces\v2\v2.traces.2013_09_05_p97_m561_oft1.mat')
    %convert to matrix
     nTraces = length(SpikeTraceData);
    nTime = length(SpikeTraceData(1,1).Trace);
    traces = zeros(nTraces,nTime);
    for i=1:nTraces
        traces(i,:) = SpikeTraceData(1,i).Trace;
    end
    [m561Spikes, m561SpikesLoc] = controllerSpikeDetection(traces);
    IcaTraces = m561Spikes(:,1:18000);

    xdiff = [0; diff(m728tracking(:,2))];
    ydiff = [0; diff(m728tracking(:,3))];
    velocity = sqrt(xdiff.^2 + ydiff.^2);

    downsampledVelocity = interp1(1:length(velocity),velocity,linspace(1,length(velocity),length(IcaTraces)));
    angVel = m561(:,6);
    downsampledAngVel = interp1(1:length(angVel),angVel,linspace(1,length(angVel),length(IcaTraces)));

    movAvg=10;
    avgTraces = filtfilt(ones(1,movAvg)/movAvg,1,sum(signalSpikes));
    downsampledVelocity  = filtfilt(ones(1,movAvg)/movAvg,1,downsampledVelocity);
    downsampledAngVel  = filtfilt(ones(1,movAvg)/movAvg,1,downsampledAngVel);

    setFigureDefaults();

    openFigure(21,'full')
    scath = scatterhist(avgTraces, downsampledVelocity)
    hp=get(scath(1),'children'); % handle for plot inside scaterplot axes
    set(hp,'Marker','.','MarkerSize',12);
    hold on
    gscatter(avgTraces, downsampledVelocity, downsampledVelocity<1)
    fitVals = polyfit(avgTraces, downsampledVelocity,1)
    refline(fitVals(1),fitVals(2))
    xlabel('firing rate (spikes/frame)')
    ylabel('velocity (px/frame)')
    set(gca,'Color','none'); box off;

    % look at firing rate in moving and not moving
    downsampledVelocity(downsampledVelocity>100)=0;
    openFigure(22,'half')
    trialTitle = 'm728\_hcplate01\_trial01';
    subplot(3,1,1);
    idx=downsampledVelocity<1;
    g=signalSpikes;g(:,~idx)=0;g2=1:length(sum(g));
    smoothhist2D([g2; sum(g)]',7,[100,100],0,'image');hold on;
    plot(g2,cumsum(downsampledVelocity)/max(cumsum(downsampledVelocity))*10, 'r');
    title([trialTitle ' frame v. firing rate: velocity<1 or quiescent']);
    legend('distance traveled','Location','NorthWest')
    xlabel('frame'); ylabel('firing rate (spikes/frame)');
    % patch(g2,cumsum(downsampledVelocity)/max(cumsum(downsampledVelocity))*10, 'r', 'EdgeAlpha', 0.5, 'FaceColor', 'none');
    subplot(3,1,2);
    idx=downsampledVelocity>=1;
    g=signalSpikes;g(:,~idx)=0;g2=1:length(sum(g));
    smoothhist2D([g2; sum(g)]',7,[100,100],0,'image');hold on;
    plot(g2,cumsum(downsampledVelocity)/max(cumsum(downsampledVelocity))*10, 'r');
    title([trialTitle ' frame v. firing rate: velocity>=1 or active']);
    legend('distance traveled','Location','NorthWest')
    xlabel('frame'); ylabel('firing rate (spikes/frame)');

    subplot(3,1,3);
    idx=downsampledVelocity>-1;
    g=signalSpikes;g(:,~idx)=0;g2=1:length(sum(g));
    smoothhist2D([g2; sum(g)]',7,[100,100],0,'image');hold on;
    plot(g2,cumsum(downsampledVelocity)/max(cumsum(downsampledVelocity))*10, 'r');
    title([trialTitle ' frame v. firing rate: all velocities']);
    legend('distance traveled','Location','NorthWest')
    xlabel('frame'); ylabel('firing rate (spikes/frame)');
    % text(5.05, 2.5, 'outside', 'clipping', 'off');

    % plot a heatmap
    openFigure(23,'half')
    smoothhist2D([avgTraces; downsampledVelocity]',7,[100,100],0);
    xlabel('firing rate (spikes/frame)')
    ylabel('velocity (px/frame)')
    % refline(-fitVals(1),fitVals(2))

    openFigure(24,'full')
    scath = scatterhist(avgTraces, downsampledAngVel)
    hp=get(scath(1),'children'); % handle for plot inside scaterplot axes
    set(hp,'Marker','.','MarkerSize',12);
    hold on
    gscatter(avgTraces, downsampledAngVel, downsampledVelocity<1)
    fitVals = polyfit(avgTraces, downsampledAngVel,1)
    refline(fitVals(1),fitVals(2))
    xlabel('firing rate (spikes/frame)')
    ylabel('ang velocity (px/frame)')
    set(gca,'Color','none'); box off;

    openFigure(25,'full')
    scatterhist(avgTraces, downsampledAngVel)
    hold on
    gscatter(avgTraces, downsampledAngVel, downsampledVelocity<1)
    fitVals = polyfit(avgTraces, downsampledAngVel,1)
    refline(fitVals(1),fitVals(2))
    xlabel('firing rate (spikes/frame)')
    ylabel('ang velocity (px/frame)')
    set(gca,'Color','none'); box off;

    medianAngleFiring = zeros(1,size(m561Spikes,1));
    medianVelocityFiring = zeros(1,size(m561Spikes,1));
    nSpikesCell = zeros(1,size(m561Spikes,1));
    for i=1:size(m561Spikes,1)
        idx = m561Spikes(i,1:18000)>0;
        nSpikesCell(1,i) = sum(idx);
        medianAngleFiring(1,i)=median(m561Spikes(i,idx).*downsampledAngVel(idx));
        medianVelocityFiring(1,i)=median(m561Spikes(i,idx).*downsampledVelocity(idx));
    end
    openFigure(26,'full')
    subplot(2,2,1)
    plot(sort(medianAngleFiring)); title('cells sorted by median responsive ang velocity');
    subplot(2,2,2)
    plot(sort(nSpikesCell)); title('cells sorted by n spikes in trial');
    subplot(2,2,3)
    plot(nSpikesCell,medianAngleFiring, 'r.'); title('numSpikes vs. median responsive ang velocity');
    subplot(2,2,4)
    plot(nSpikesCell,medianVelocityFiring, 'r.'); title('numSpikes vs. median responsive velocity');

    % use bsxfun to matrix multiple 2D filt to 3D movie
    tmpTrace = sum(sum(bsxfun(@times,thisFilt,DFOF),1),2);

    median(m561Spikes(1,idx).*downsampledAngVel(idx))

    openFigure(27,'full')
    plot(avgTraces,'r')
    hold on
    plot(downsampledVelocity,'b')
    xlabel('unit/frame')
    ylabel('frames')
    hleg1 = legend('firing rate','velocity');
    set(gca,'Color','none'); box off;