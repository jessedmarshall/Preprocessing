function [inputMovieDownsampled] = downsampleMovie(inputMovie, varargin)
	% biafra ahanonu
	% started 2013.11.09 [09:31:32]
	% downsamples a movie in TIME
	%
	% inputs
	% 	inputMovie: a NxMxP matrix
	% options
	% 	downsampleType
	% 	downsampleFactor - amount to downsample in time

	%========================
	% default options
	options.downsampleDimension = 'time';
	options.downsampleType = 'bilinear';
	options.downsampleFactor = 4;
	% get user options, else keeps the defaults
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	switch options.downsampleDimension
		case 'time'
			switch options.downsampleType
				case 'bilinear'
					% we do a bit of trickery here: we can downsample the movie in time by downsampling the X*Z 'image' in the Z-plane then stacking these downsampled images in the Y-plane. Would work the same of did Y*Z and stacked in X-plane.
					downX = size(inputMovie,1);
					downY = size(inputMovie,2);
					downZ = round(size(inputMovie,3)/options.downsampleFactor);
					% pre-allocate movie
					inputMovieDownsampled = zeros([downX downY downZ]);
					% this is a normal for loop at the moment, if convert inputMovie to cell array, can force it to be parallel
					waitbarHandle = waitbar(0, 'downsampling movie...');
					for frame=1:downY
						if(mod(frame,20)==0)
				            waitbar(frame/downY,waitbarHandle)
				        end
					   downsampledFrame = imresize(squeeze(inputMovie(:,frame,:)),[downX downZ],'bilinear');
					   inputMovieDownsampled(:,frame,:) = downsampledFrame;
					end
					close(waitbarHandle);
					drawnow;
				otherwise
					return;
			end
		case 'space'
			display('not implemented');
		otherwise
			display('incorrect dimension option, choose time or space');
	end