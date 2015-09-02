function [inputMovie] = normalizeMovie(inputMovie, varargin)
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

	% input is an image, convert to movie
	if length(size(inputMovie))==2
		inputMovieDims = 2;
		inputMovieTmp(:,:,1) = inputMovie;
		inputMovie = inputMovieTmp;
	else
		inputMovieDims = 3;
	end
	%========================
	% fft,imfilterSmooth,imfilter,meanSubtraction,meanDivision,negativeRemoval
	options.normalizationType = 'meanDivision';
	% for fft
	options.secondaryNormalizationType = [];
	% maximum frame to normalize
	options.maxFrame = size(inputMovie,3);
	% ===
	% options for fft
	% for bandpass, low freq to pass
	options.freqLow = 10;
	% for bandpass, high freq to pass
	options.freqHigh = 50;
	% highpass, lowpass, bandpass
	options.bandpassType = 'highpass';
	% binary or gaussian
	options.bandpassMask = 'binary';
	% show the frequency spectrum and images
	% 0 = no, 1 = yes
	options.showImages = 0;
	% ===
	% fspecial, 'disk' option
	option.imfilterType = 'disk';
	% how to deal with boundaries, see http://www.mathworks.com/help/images/ref/imfilter.html
	options.boundaryType = 'circular';
	% 'disk' option: pixel radius to blur
	options.blurRadius = 35;
	% 'gaussian' option
	options.sizeBlur = 80;
	options.sigmaBlur = 3;
	% ===
	% cmd line waitbar on?
	options.waitbarOn = 1;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
	    eval([fn{i} '=options.' fn{i} ';']);
	end
	if strcmp(normalizationType,'bandpassDivisive')
		normalizationType = 'fft';
	end
	if strcmp(normalizationType,'lowpassFFTDivisive')
		normalizationType = 'fft';
		options.secondaryNormalizationType = 'lowpassFFTDivisive';
		options.bandpassType = 'lowpass';
	end
	%========================
	switch normalizationType
		case 'imagejFFT'
			% opens imagej
			% MUST ADD \Fiji.app\scripts
			% open imagej instance
			Miji(false);
			startTime = tic;
			% pass matrix to imagej
			MIJ.createImage('result', inputMovie, true);
			% settings taken from original imagej implementation
			bpstr= ' filter_large=10000 filter_small=80 suppress=None tolerance=5 process';
			MIJ.run('Bandpass Filter...',bpstr);
			% grab the image from imagej
			inputMovieFFT = MIJ.getCurrentImage;
			% close imagej instance
			MIJ.run('Close');
			MIJ.exit;
			toc(startTime);
			% divide lowpass from image
			inputMovie = bsxfun(@rdivide,single(inputMovie),single(inputMovieFFT));
		case 'fft'
			bandpassMatrix = zeros(size(inputMovie));
			% get options
			ioptions.showImages = options.showImages;
			ioptions.lowFreq = options.freqLow;
			ioptions.highFreq = options.freqHigh;
			ioptions.bandpassType = options.bandpassType;
			ioptions.bandpassMask = options.bandpassMask;
			reverseStr = '';
			% convert movie to correct class output by fft
			outputClass = class(fftImage(squeeze(inputMovie(:,:,1)),'options',ioptions));
			inputMovie = cast(inputMovie,outputClass);
			for frame=1:options.maxFrame
				thisFrame = squeeze(inputMovie(:,:,frame));
				if isempty(options.secondaryNormalizationType)
					inputMovie(:,:,frame) = fftImage(thisFrame,'options',ioptions);
				else
					tmpFrame = fftImage(thisFrame,'options',ioptions);
					inputMovie(:,:,frame) = thisFrame./tmpFrame;
				end
				% bandpassMatrix(:,:,frame) = fftImage(thisFrame,'options',ioptions);
				% bandpassMatrix(:,:,frame) = imcomplement(bandpassMatrix(:,:,frame));
				reverseStr = cmdWaitbar(frame,options.maxFrame,reverseStr,'inputStr','normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
				% = bsxfun(@ldivide,squeeze(movie20hz(:,:,1)),filteredFrame
			end
			% inputMovie = bandpassMatrix;
			% inputMovie = bsxfun(@ldivide,inputMovie,bandpassMatrix);
		case 'imfilterSmooth'
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
			for frame=1:nFrames
			    thisFrame = squeeze(inputMovie(:,:,frame));
			    thisFrame(find(isnan(thisFrame)))=nanmean(thisFrame(:));
			    inputMovieFiltered(:,:,frame) = imfilter(thisFrame, movieFilter,options.boundaryType);
			    reverseStr = cmdWaitbar(frame,nFrames,reverseStr,'inputStr','normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
			end
			% divide each frame by the filtered movie to remove 'background'
			inputMovie = inputMovieFiltered;
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
			for frame=1:nFrames
			    thisFrame = squeeze(inputMovie(:,:,frame));
			    thisFrame(find(isnan(thisFrame)))=nanmean(thisFrame(:));
			    inputMovieFiltered(:,:,frame) = imfilter(thisFrame, movieFilter,options.boundaryType);
			    reverseStr = cmdWaitbar(frame,nFrames,reverseStr,'inputStr','normalizing movie','waitbarOn',options.waitbarOn,'displayEvery',5);
			end
			% divide each frame by the filtered movie to remove 'background'
			inputMovie = bsxfun(@ldivide,inputMovieFiltered,inputMovie);
		case 'meanSubtraction'
			inputMean = nanmean(nanmean(inputMovie,1),2);
			inputMean = cast(inputMean,class(inputMovie));
			inputMovie = bsxfun(@minus,inputMovie,inputMean);
		case 'meanDivision'
			inputMean = nanmean(nanmean(inputMovie,1),2);
			inputMean = cast(inputMean,class(inputMovie));
			inputMovie = bsxfun(@rdivide,inputMovie,inputMean);
			% inputMean = nansum(nansum(inputMovie,1),2);
			% inputMean = cast(inputMean,class(inputMovie))
		case 'negativeRemoval'
			inputMin = abs(nanmin(inputMovie(:)))
			inputMin = cast(inputMin,class(inputMovie));
			inputMovie = bsxfun(@plus,inputMovie,inputMin);
		otherwise
			inputMovie = NaN
			return;
	end

	if inputMovieDims==2
		inputMovie = squeeze(inputMovie(:,:,1));
	end
end