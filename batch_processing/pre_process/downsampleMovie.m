function [inputMovie] = downsampleMovie(inputMovie, varargin)
	% downsamples a movie in either space or time, uses floor to calculate downsampled dimensions.
	% biafra ahanonu
	% started 2013.11.09 [09:31:32]
	%
	% inputs
		% inputMovie: a NxMxP matrix
	% options
		% downsampleType
		% downsampleFactor - amount to downsample in time
	% changelog
		% 2013.12.19 added the spatial downsampling to the function.
	% TODO

	%========================
	% default options
	options.downsampleDimension = 'time';
	options.downsampleType = 'bilinear';
	options.downsampleFactor = 4;
	% exact dimensions to downsample in Z
	options.downsampleZ = [];
	%
	options.downsampleX = [];
	%
	options.downsampleY = [];
	options.waitbarOn = 1;
	% number of frames in each movie to load, [] = all, 1:500 would be 1st to 500th frame.
	options.frameList = [];
	% whether to convert movie to double on load, not recommended
	options.convertToDouble = 0;
	% name of HDF5 dataset name to load
	options.inputDatasetName = '/1';
	% get user options, else keeps the defaults
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	% load the movie within downsample function
	if strcmp(class(inputMovie),'char')|strcmp(class(inputMovie),'cell')
		inputMovie = loadMovieList(inputMovie,'convertToDouble',options.convertToDouble,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName);
	end

	switch options.downsampleDimension
		case 'time'
			switch options.downsampleType
				case 'bilinear'
					% we do a bit of trickery here: we can downsample the movie in time by downsampling the X*Z 'image' in the Z-plane then stacking these downsampled images in the Y-plane. Would work the same of did Y*Z and stacked in X-plane.
					downX = size(inputMovie,1);
					downY = size(inputMovie,2);
					if isempty(options.downsampleZ)
						downZ = floor(size(inputMovie,3)/options.downsampleFactor);
					else
						downZ = options.downsampleZ;
					end
					% pre-allocate movie
					% inputMovieDownsampled = zeros([downX downY downZ]);
					% this is a normal for loop at the moment, if convert inputMovie to cell array, can force it to be parallel
					reverseStr = '';
					for frame=1:downY
					   downsampledFrame = imresize(squeeze(inputMovie(:,frame,:)),[downX downZ],'bilinear');
					   % to reduce memory footprint, place new frame in old movie and cut off the unneeded frames after
					   inputMovie(1:downX,frame,1:downZ) = downsampledFrame;
					   % inputMovie(:,frame,:) = downsampledFrame;
						if mod(frame,20)==0&options.waitbarOn==1|frame==downY
						    reverseStr = cmdWaitbar(frame,downY,reverseStr,'inputStr','temporally downsampling matrix');
						end
					end
					inputMovie = inputMovie(:,:,1:downZ);
					drawnow;
				otherwise
					return;
			end
		case 'space'
			switch options.downsampleType
				case 'bilinear'
					% we do a bit of trickery here: we can downsample the movie in time by downsampling the X*Z 'image' in the Z-plane then stacking these downsampled images in the Y-plane. Would work the same of did Y*Z and stacked in X-plane.
					downX = floor(size(inputMovie,1)/options.downsampleFactor);
					if ~isempty(options.downsampleX);downX = options.downsampleX; end
					downY = floor(size(inputMovie,2)/options.downsampleFactor);
					if ~isempty(options.downsampleY);downY = options.downsampleY; end
					downZ = size(inputMovie,3);
					% pre-allocate movie
					% inputMovieDownsampled = zeros([downX downY downZ]);
					% this is a normal for loop at the moment, if convert inputMovie to cell array, can force it to be parallel
					reverseStr = '';
					for frame=1:downZ
					   downsampledFrame = imresize(squeeze(inputMovie(:,:,frame)),[downX downY],'bilinear');
					   % to reduce memory footprint, place new frame in old movie and cut off the unneeded frames after
					   inputMovie(1:downX,1:downY,frame) = downsampledFrame;
					   % inputMovieDownsampled(1:downX,1:downY,frame) = downsampledFrame;
						if mod(frame,20)==0&options.waitbarOn==1|frame==downZ
						    reverseStr = cmdWaitbar(frame,downZ,reverseStr,'inputStr','spatially downsampling matrix');
						end
					end
					inputMovie = inputMovie(1:downX,1:downY,:);
					drawnow;
				otherwise
					return;
			end
		otherwise
			display('incorrect dimension option, choose time or space');
	end
	display(' ');