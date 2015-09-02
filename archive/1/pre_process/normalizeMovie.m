function [outputMovie] = normalizeMovie(inputMovie, varargin)
	% biafra ahanonu
	% started: 2013.11.09 [09:25:48]
	% takes an input movie and applies a particular normalization

	%========================
	% old way of saving, only temporary until full switch
	options.normalizationType = 'bandpassDivisive';
	options.maxFrame = size(inputMovie,3);
	options.freqLow = 5;
	options.freqHigh = 2;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
	    eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================
	figure(1233)
	switch normalizationType
		case 'bandpassDivisive'
			bandpassMatrix = zeros(size(inputMovie));
			waitbarHandle = waitbar(0, 'normalizing movie...');
			for frame=1:options.maxFrame
				thisFrame = squeeze(inputMovie(:,:,frame));
				bandpassMatrix(:,:,frame) = gaussianbpf(mat2gray(thisFrame),options.freqLow,options.freqHigh);
				if(mod(frame,20)==0)
		            waitbar(frame/options.maxFrame,waitbarHandle)
					% subplot(3,1,1)
					% imagesc(thisFrame);
					% subplot(3,1,2)
					% imagesc(bandpassMatrix(:,:,frame));
					% subplot(3,1,3)
					% imagesc(thisFrame-bandpassMatrix(:,:,frame));
		        end
			% = bsxfun(@ldivide,squeeze(movie20hz(:,:,1)),filteredFrame
			end
			close(waitbarHandle);
			% outputMovie = bandpassMatrix;
			outputMovie = bsxfun(@rdivide,bandpassMatrix,inputMovie);
		otherwise
			return;
	end
