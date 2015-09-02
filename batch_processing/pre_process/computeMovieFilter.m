function [inputMovie] = computeMovieFilter(inputMovie, varargin)
	% takes an input movie and applies a particular normalization (e.g. lowpass divisive).
	% biafra ahanonu
	% started: 2013.11.09 [09:25:48]
	% inputs
		% inputMovie = [x y frames] 3D matrix
	% outputs
		% inputMovie = [x y frames] 3D matrix normalized

	% changelog
		% 2014.02.17 added in mean subtraction/division to function.
	% TODO
		%

	%========================
	% old way of saving, only temporary until full switch
	options.normalizationType = 'imfilter';
	options.maxFrame = size(inputMovie,3);
	options.freqLow = 5;
	options.freqHigh = 2;
	options.waitbarOn = 1;

	% fspecial, 'disk' option
	option.imfilterType = 'disk';
	% how to deal with boundaries, see http://www.mathworks.com/help/images/ref/imfilter.html
	options.boundaryType = 'circular';
	% 'disk' option: pixel radius to blur
	options.blurRadius = 35;
	% 'gaussian' option
	options.sizeBlur = 80;
	options.sigmaBlur = 3;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
	    eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================
	switch normalizationType
		case 'imfilter'
			% create filter
			switch option.imfilterType
				case 'disk'
					movieFilter = fspecial('disk', options.blurRadius);
				case 'gaussian'
					movieFilter = fspecial('gaussian', [options.sizeBlur options.sizeBlur], options.sigmaBlur);
				otherwise
					return
			end
			nFrames = size(inputMovie,3);
			inputMovieFiltered = zeros(size(inputMovie));
			reverseStr = '';
			for i=1:nFrames
			    thisFrame = squeeze(inputMovie(:,:,i));
			    inputMovie(:,:,i) = imfilter(thisFrame, movieFilter,options.boundaryType);
			    reverseStr = cmdWaitbar(i,nFrames,reverseStr,'inputStr','normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
			end
		otherwise
			inputMovie = NaN
			return;
	end
