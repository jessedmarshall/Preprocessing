function [outputMovie] = createSideBySide(primaryMovie,secondaryMovie,varargin)
	% auto-create side-by-side, either save output as hdf5 or return a matrix
	% biafra ahanonu
	% started: 2014.01.04 (code taken from controllerAnalysis)
	% inputs
		% primaryMovie - string pointing to the video file (.avi, .tif, or .hdf5 supported, auto-detects based on extension) OR a matrix
		% secondaryMovie - string pointing to the video file (.avi, .tif, or .hdf5 supported, auto-detects based on extension) OR a matrix
	% outputs
		% outputMovie - horizontally concatenated movie
	% changelog
		% 2014.01.27 [22:57:19] - changed to allow input of either a path or a matrix, more generalized
	% TODO
		% allow option for vertical concat?
		% spatio-temporal should be one abstracted for-loop, no? - DONE 2014.01.27 [21:52:37]

	% ========================
	% number of frames in each movie to load, [] = all, 1:500 would be 1st to 500th frame.
	options.frameList = [];
	% whether to convert movie to double on load, not recommended
	options.convertToDouble = 0;
	% name of HDF5 dataset name to load
	options.inputDatasetName = '/1';
	% string to a movie, preferably AVI
	options.recordMovie = 0;
	% amount of pixels around the border to crop in primary movie
	options.pxToCrop = [];
	% downsample combined movie
	options.downsampleFactorFinal = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================
	% get the movie
	if strcmp(class(primaryMovie),'char')|strcmp(class(primaryMovie),'cell')
		primaryMovie = loadMovieList(primaryMovie,'convertToDouble',options.convertToDouble,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName);
	end

	% load secondary movie
	if strcmp(class(secondaryMovie),'char')|strcmp(class(secondaryMovie),'cell')
		secondaryMovie = loadMovieList(secondaryMovie,'convertToDouble',options.convertToDouble,'frameList',options.frameList);
	end

	% ========================
	% make movies single for calculations sake
	% primaryMovie = single(primaryMovie);
	% secondaryMovie = single(secondaryMovie);

	% ========================
	display('cropping primary movie...')
	% Get the x and y corner coordinates as integers
	if ~isempty(options.pxToCrop)
		if size(primaryMovie,2)>=size(primaryMovie,1)
			coords(1) = options.pxToCrop; %xmin
			coords(2) = options.pxToCrop; %ymin
			coords(3) = size(primaryMovie,1)-options.pxToCrop;   %xmax
			coords(4) = size(primaryMovie,2)-options.pxToCrop;   %ymax
		else
			coords(1) = options.pxToCrop; %xmin
			coords(2) = options.pxToCrop; %ymin
			coords(4) = size(primaryMovie,1)-options.pxToCrop;   %xmax
			coords(3) = size(primaryMovie,2)-options.pxToCrop;   %ymax
		end
		rowLen = size(primaryMovie,1);
		colLen = size(primaryMovie,2);
		% a,b are left/right column values
		a = coords(1);
		b = coords(3);
		% c,d are top/bottom row values
		c = coords(2);
		d = coords(4);
		cropChoice = 2;
		switch cropChoice
			case 1
				primaryMovie(1:rowLen,1:a,:) = NaN;
				primaryMovie(1:rowLen,b:colLen,:) = NaN;
				primaryMovie(1:c,1:colLen,:) = NaN;
				primaryMovie(d:rowLen,1:colLen,:) = NaN;
			case 2
				primaryMovie = primaryMovie(coords(2):coords(4), coords(1): coords(3),:);
			otherwise

		end
	end
	% ========================
	display('making movies spatially and temporally identical...')
	% to generalize out downsampling, create cell arrays to call that contain the dimension information
	dimensionList = {3, 2, 1};
	dimensionNameList = {'time','space','space'};
	% loop over each of the dimensions to resize to
	loopList = [1 3]; %1:length(dimensionList)
	for i=loopList
		thisDim = dimensionList{i};
		thisDimName = dimensionNameList{i};
		lengthPrimary = size(primaryMovie,thisDim);
		lengthSecond = size(secondaryMovie,thisDim);
		if lengthPrimary>lengthSecond
			% display(['downsampling: ' movieList{1}]);
			downsampleFactor = lengthPrimary/lengthSecond;
			primaryMovie = downsampleMovie(primaryMovie,'downsampleDimension',thisDimName,'downsampleFactor',downsampleFactor,'downsampleZ',lengthSecond);
		elseif lengthSecond>lengthPrimary
			% display(['downsampling: ' vidList{1}]);
			downsampleFactor = lengthSecond/lengthPrimary;
			secondaryMovie = downsampleMovie(secondaryMovie,'downsampleDimension',thisDimName,'downsampleFactor',downsampleFactor,'downsampleZ',lengthPrimary);
		end
	end
	%========================
	display('normalizing movies...')
	% normalize movies between 0 and 1 so they display correctly together, better if their distributions are the same
	[primaryMovie] = normalizeVector(single(primaryMovie),'normRange','zeroToOne');
	[primaryMovie] = normalizeMovie(primaryMovie,'normalizationType','meanSubtraction');
	[secondaryMovie] = normalizeVector(single(secondaryMovie),'normRange','zeroToOne');
	[secondaryMovie] = normalizeMovie(secondaryMovie,'normalizationType','meanSubtraction');
	% ========================
	% horizontally concat the movies
	display('concatenating movies...')
	outputMovie = horzcat(primaryMovie,secondaryMovie);
	clear primaryMovie secondaryMovie
	if options.downsampleFactorFinal>1
		display('downsampling final movie...')
		outputMovie = downsampleMovie(outputMovie,'downsampleDimension','space','downsampleFactor',options.downsampleFactorFinal);
	end

	% if user ask to save movie, do so.
	if options.recordMovie~=0
		writerObj = VideoWriter(options.recordMovie);
		open(writerObj);
		nFrames = size(outputMovie,3);
		reverseStr = '';
		for frame=1:nFrames
			writeVideo(writerObj,squeeze(outputMovie(:,:,frame)));
			if mod(frame,5)==0|frame==nFrames
			    reverseStr = cmdWaitbar(frame,nFrames,reverseStr,'inputStr','writing movie');drawnow;
			end
		end
		close(writerObj);
	end