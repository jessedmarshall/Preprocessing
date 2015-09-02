function playMovie(inputMovie, varargin)
	% biafra ahanonu
	% started 2013.11.09 [10:39:50]
	% just plays the input movie
	% changelog
		% 2013.11.13 [21:30:53] can now pre-maturely exit the movie, 21st century stuff

	%========================
	% options
	% frame frame
	options.fps = 60;
	options.extraMovie = [];
	options.extraLinePlot = [];
	options.windowLength = 30;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	nFrames = size(inputMovie,3);

	fig1 = openFigure(42,'half');
	thisKey=1;
	% set(fig1,'keypress','thisKey=get(gcf,''CurrentCharacter'');');
    colormap gray
	% for frame=1:size(inputMovie,3)
	frame=1;
	subplotNumPlots = sum([~isempty(options.extraMovie) ~isempty(options.extraLinePlot)])+1;
	subplotRows = 2;
	subplotCols = 2;
	while frame<nFrames
		subplotNum = 1;
	    if ~isempty(options.extraMovie)|~isempty(options.extraLinePlot)
	    	subplot(subplotRows,subplotCols,subplotNum)
	    end
	    % display na image for the movie
	    imagesc(squeeze(inputMovie(:,:,frame)));
	    axis off;axis square;
	    % axis image;
	    title(['close to stop, frame: ' num2str(frame) '/' num2str(size(inputMovie,3))]);
	    % if user has an extra movie
	    if ~isempty(options.extraMovie)
	    	subplotNum = subplotNum+1;
	    	subplot(subplotRows,subplotCols,subplotNum)
	    	imagesc(squeeze(options.extraMovie(:,:,frame)));
	    	axis off;axis square;
	    	% axis image;
	    end
	    % if user wants a lineplot to also be shown
	    if ~isempty(options.extraLinePlot)
	    	% increment subplot
	    	% subplotNum = subplotNum+1;
	    	subplotNum = [3:4];
	    	subplot(subplotRows,subplotCols,subplotNum)
	    	if frame<options.windowLength
	    		frame = options.windowLength
	    	elseif frame>(frame+options.windowLength)
	    		frame=nFrames;
	    	end
	    	linewindow = (frame-options.windowLength):(frame+options.windowLength);
	    	linewindow = linewindow(find(linewindow>0));

	    	plot(linspace(-1,1,length(linewindow)),options.extraLinePlot(:,linewindow)'); hold on;
	    	ylim([-0.05 max(max(options.extraLinePlot))]);
	    	xval = 0;
	    	x=[xval,xval];
	    	y=[-0.05 max(max(options.extraLinePlot))];
	    	plot(x,y,'r'); box off; hold off;
	    end
	    %imagesc(imcomplement(squeeze(dfofMovie(:,:,frame))));
	    pause(1/options.fps);
	    frame = frame+1;
	    if sum(findobj('type','figure')==42)==0
	    	fig1 = openFigure(42,'half');
	    	frame = nFrames-1;
	    end
    	% set(fig1,'keypress','keyboard');
		% if ~isempty(thisKey)
		% 	if strcmp(thisKey,'f'); break; end;
		% 	if strcmp(thisKey,'p'); pause; thisKey=[]; end;
		% end
	end