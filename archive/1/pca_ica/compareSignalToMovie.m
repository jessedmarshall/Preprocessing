function compareSignalToMovie(inputMovie, inputFilters, inputSignal, varargin)
	% biafra ahanonu
	% updated: 2013.11.04 [18:40:45]
	% compares inputMovie to inputSignal and inputFilters to see if they match

	%========================
	% old way of saving, only temporary until full switch
	options.oldSave = 0;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
	    eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	% create a cell map to overlay current IC filter onto
	cellmap = createCellMap(inputFilters);

	%Determine whether ICs are valid or invalid
	fig1 = openFigure(789,'full');

	% location of each subplot
	cellMapPlotLoc = 3;
	moviePlotLoc = [1:2 4:5];
	filterPlotLoc = moviePlotLoc;
	avgSpikeTracePlot = 6;
	subplotX = 3;
	subplotY = 2;
	% instructions
	instructionStr =  ': n|right-click|down-arrow = bad IC; y|left-click|up-arrow = good IC';

	% % plot the cell map to provide context
	% subplot(subplotY,subplotX,moviePlotLoc)
	% firstFrame = squeeze(inputMovie(:,:,1));
	% imagesc(firstFrame); axis off; colormap gray;
	% title(['movie']);
	% hold on
	% % make a green image overlayed
	% size(firstFrame)
	% green = cat(3, zeros(size(firstFrame)), ones(size(firstFrame)), zeros(size(firstFrame)));
	% filterOverlay = imshow(green);
	% hold off

	IClist=[1:size(inputMovie,3)];

	lenICList = length(IClist);
	lenICFilts = size(inputFilters,1);
	lenICTraces = size(inputSignal,1);
	minValTraces = min(min(inputSignal));
	maxValTraces = max(max(inputSignal));
	% inputFilters = inputFilters(IClist,:,:);
	% inputSignal = inputSignal(IClist,:);
	valid = ones(1,size(inputFilters,1))*-1;

	i = 1;
	% loop over chosen filters
	while i<=size(inputMovie,3)
	% for i = 1:size(inputFilters,1)
	    forward=1;
	    thisFilt = squeeze(inputFilters(1,:,:));
	    thisTrace = inputSignal(1,:);
	    cellIDStr = ['#' num2str(i) '/' num2str(lenICTraces)];

	    set(fig1,'Color',[1 1 1]);
	    % use thresholded IC as AlphaData for the solid green image, overlay on cell map
	    	thisFrame = squeeze(inputMovie(:,:,i));
		    subplot(subplotY,subplotX,moviePlotLoc)
		    imagesc(thisFrame*25);axis off;colormap gray;
	        green = cat(3, zeros(size(thisFrame)), ones(size(thisFrame)), zeros(size(thisFrame)));
	        size(green)
	        hold on
	        filterOverlay = imshow(green);
	        % thresholdICs(thisFilt)
	        set(filterOverlay, 'AlphaData', thresholdICs(thisFilt)/4);
	        hold off
	    % show the current IC filter
	        subplot(subplotY,subplotX,cellMapPlotLoc)
	        imagesc(thresholdICs(thisFilt));
	        colormap gray
	        axis off;
	        % ij square
	        % title(['IC ' cellIDStr instructionStr])
	    % plot the average detected spike trace
	        subplot(subplotY,subplotX,avgSpikeTracePlot);
	        % [testpeaks] = identifySpikes(thisTrace);
	        % spikeROI = [-40:40];
	        % if((i-40)<1)
	        % end
        	spikeROI = [i:i+80];

	        %
	        % errorbar(spikeROI, avgSpikeTrace, traceErr);
	        % t=1:length(traceErr);
	        % fill([spikeROI fliplr(spikeROI)],[avgSpikeTrace+traceErr fliplr(avgSpikeTrace-traceErr)],[4 4 4]/8, 'FaceAlpha', 0.4, 'EdgeColor','none')
	        % plot(repmat(spikeROI, [size(spikeCenterTrace,1) 1])', spikeCenterTrace','Color',[4 4 4]/8)
	        % hold on;
	        plot(spikeROI, thisTrace(spikeROI),'k', 'LineWidth',3)
	        tmpTrace = squeeze(sum(sum(bsxfun(@times,thresholdICs(thisFilt),inputMovie(:,:,spikeROI)),1),2));
	        tmpTrace = (tmpTrace/max(tmpTrace)-1)/2;
	        hold on
	        plot(spikeROI, tmpTrace/4,'g', 'LineWidth',3)
	        hold off
	        % hold off;
	        % title(['average trace around spikes for cell ' cellIDStr])
	        % ylim([minValTraces maxValTraces]);
	        % box off;
	    % plot the trace over multiple subplots
	        % subplot(subplotY,subplotX,moviePlotLoc)
	        % imagesc(inputMovie(:,:,i));
	        % colormap gray
	        % axis off;
	        % plot(inputSignal(i,:));
	        % [testpeaks] = identifySpikes(thisTrace);
	        % plot(thisTrace, 'r');
	        % hold on;
	        % scatter(testpeaks, thisTrace(testpeaks), 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0])
	        % hold off;
	        % title(['trace ' cellIDStr])
	        % axis([0 length(thisTrace) minValTraces maxValTraces]);
	        % box off;

	    % % get user input
	    % [x,y,reply]=ginput(1);
	    % % decide what to do based on input
	    % if isequal(reply, 3)|isequal(reply, 110)|isequal(reply, 31)
	    %     % n key or right click
	    %     forward=1;
	    %     % display('invalid IC');
	    %     % set(fig1,'Color',[0.8 0 0]);
	    %     valid(i) = 0;
	    % elseif isequal(reply, 28)
	    %     % go back, left
	    %     forward=-1;
	    % elseif isequal(reply, 29)
	    %     % go forward, right
	    %     forward=1;
	    % elseif isequal(reply, 121)|isequal(reply, 1)|isequal(reply, 30)
	    %     % y key or left click
	    %     forward=1;
	    %     % display('valid IC');
	    %     % set(fig1,'Color',[0 0.8 0]);
	    %     valid(i) = 1;
	    % else
	    %     forward=1;
	    %     valid(i) = 1;
	    % end
	    pause(0.05);
	    i=i+forward;
	    if i<=0
	        i=1;
	    end
	end