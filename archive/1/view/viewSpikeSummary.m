function [signalMatrix signalSpikes] = viewSpikeSummary(signalMatrix,signalSpikes,varargin)
    % make plots...
    figStart = 100;
    %
    openFigure(figStart,'full');hold off;figStart=figStart+1;
    subplot(2,2,1)
    signalMatrix(signalMatrix<0)=0;
    imagesc(signalMatrix);
    set(gca,'Color','none'); box off;
    colormap hot
    %
    subplot(2,2,2)
    imagesc(signalSpikes);
    set(gca,'Color','none'); box off;
    colormap hot
    %
    subplot(2,2,3)
    g=signalSpikes;
    g2=1:length(sum(g));
    smoothhist2D([g2; sum(g)]',7,[100,100],0.05,'image');hold on;box off;
    title(['all cells: frame v. firing rate']);
    % legend('distance traveled','Location','NorthWest')
    xlabel('frame'); ylabel('firing rate (spikes/frame)');
    %
    subplot(2,2,4)
    topCells = sum(signalSpikes,2);
    topCellCutoff = quantile(topCells, [0.9]);
    topCellIdx = find(topCells>=topCellCutoff);
    g=signalSpikes(topCellIdx,:);
    g2=1:length(sum(g));
    smoothhist2D([g2; sum(g)]',7,[100,100],0.05,'image');hold on;box off;
    title(['top 10% firing cells: frame v. firing rate']);
    % legend('distance traveled','Location','NorthWest')
    xlabel('frame'); ylabel('firing rate (spikes/frame)');


    % histogram of total spikes in trial across all cells
    openFigure(figStart,'full');hold off;figStart=figStart+1;
    subplot(2,2,1)
    hist(sum(signalSpikes,2),30);box off;
    title('distribution total spikes individual cells');
    xlabel('total spikes');ylabel('count');
    subplot(2,2,2)
    maxH = max(sum(signalSpikes,1));
    histH = hist(sum(signalSpikes,1),[0:maxH]);
    plot([0:maxH], histH, 'k');box off;
    set(gca,'YScale','log');
    title('distribution simultaneous firing events');
    xlabel('simultaneous spikes');ylabel('count');
    % set(gca,'xscale','log')
    % histogram of ITIs
    ITIall = []
    for i=1:size(signalSpikes,1)
        ITIest(i) = mean(diff(find(signalSpikes(i,:)==1)));
        ITIall = [ITIall diff(find(signalSpikes(i,:)==1))];
    end
    subplot(2,2,3)
    hist(ITIest,round(logspace(0,log10(max(ITIest)))));box off;
    title('distribution of ITIs in individual cells');
    xlabel('mean ITI (frames)');ylabel('count');
    set(gca,'xscale','log')
    subplot(2,2,4)
    hist(ITIall,round(logspace(0,log10(max(ITIall)))));box off;
    title('distribution of all ITIs in individual cells');
    xlabel('ITI (frames)');ylabel('count');
    set(gca,'xscale','log')

    % openFigure(figStart,'half');hold off;figStart=figStart+1;

    [x,y,reply]=ginput(1);

    % openFigure(figStart,'half');figStart=figStart+1;
    % g = sum(signalSpikes,1);
    % % g = filtfilt(ones(1,5)/5,1,g);
    % % wts = repmat(1/30,29,1);
    % % g = conv(g,wts,'valid');
    % g = interp1(1:length(g),g,linspace(1,length(g),length(g)/30));
    % g2=1:length(g);
    % plot(g2, g(g2), 'r');
    % set(gca,'Color','none'); box off;