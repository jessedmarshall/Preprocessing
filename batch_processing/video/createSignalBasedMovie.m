function [signalMovie] = createSignalBasedMovie(inputSignals,inputImages,varargin)
	% uses images and signals for sources from an original movie to create a cleaner, more binary movie
	% biafra ahanonu
	% started: 2014.07.20 [14:09:34]
	% inputs
		% inputSignals - [n t], n = number of signals, t = time
		% inputImages - [n x y], n = number of images, x/y are the dimensions of the images, use permute(inputImages,[3 1 2]) if you store z dimension last
	% outputs
		% signalMovie - [x y t] movie, reconstructed from cell traces
	% options
		% filterInputs: should the input images be automatically filtered to remove large or low SNR signals? 0 = no, 1 = yes
		% signalType 'raw' or 'peak', peaks uses a smoothed version of the detected peaks
		% inputPeaks : [n t] matrix (n = number of signals, t = time) of pre-computed peaks, should contain 1 = peak, 0 = no peak

	% changelog
		%
	% TODO
		%

	%========================
	% should the input images be automatically filtered to remove large or low SNR signals?
	options.filterInputs = 0;
	% 'raw' or 'peak', peaks uses a smoothed version of the detected peaks
	options.signalType = 'peak';
	% [n t] matrix (n = number of signals, t = time) of pre-computed peaks, should contain 1 = peak, 0 = no peak
	options.inputPeaks = [];
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		if options.filterInputs==1
			[inputImages, inputSignals, valid, imageSizes] = filterImages(inputImages, inputSignals);
		end
		inputSignalsCopy = inputSignals;
		nSignals = size(inputSignalsCopy,1);
		nPts = size(inputSignalsCopy,2);
		mSize = size(inputImages);
		movieDims = [mSize(2) mSize(3) nPts];
		signalMovie = double(NaN(movieDims));
		inputImagesBinary = thresholdImages(inputImages,'binary',1);
		if isempty(options.inputPeaks)
			[signalPeaks, signalPeakIdx] = computeSignalPeaks(inputSignals,'makePlots',0,'makeSummaryPlots',0);
		else
			signalPeaks = options.inputPeaks;
		end
		switch options.signalType
			case 'peak'
				inputSignalsCopy = signalPeaks;
				inputSignalsCopy = inputSignalsCopy + 0.5;
				for signalNo = 1:nSignals
					V.dt    = 1/5;  % time step size
					tau     = 0.5	;    % decay time constant
			        P.gam   = 1-V.dt/tau; % C(t) = gam*C(t-1)
					inputSignalsCopy(signalNo,:) = filter(1,[1 -P.gam],inputSignalsCopy(signalNo,:));         % calcium concentration
				end
			case 'raw'

			otherwise
				% body
		end

		reverseStr = '';
		for signalNo = 1:nSignals
		    %thisSignal = zeros([1 1 nPts]);
		    %thisSignal(1,1,:) = inputSignalsCopy(signalNo,:);
		    thisSignal = inputSignalsCopy(signalNo,:);
		    thisImage = squeeze(inputImagesBinary(signalNo,:,:));

		    [x y] = find(thisImage==1);
		    xrepmat = repmat(x,[1 nPts])';
		    yrepmat = repmat(y,[1 nPts])';
		    framerepmat = repmat(1:nPts,[1 length(x)]);
		    % get the linear index in the movie of all points to replace, faster than looping over each frame
		    linearInd = sub2ind(movieDims, xrepmat(:),yrepmat(:), framerepmat(:));
		    % repeat the signal so it will fill the entire binary part of the image
		    thisSignalRepmat = repmat(thisSignal,[1 length(x)]);
		    %
		    signalMovie(linearInd) = thisSignalRepmat(:);
		    reverseStr = cmdWaitbar(signalNo,nSignals,reverseStr,'inputStr','making trace movie','waitbarOn',1,'displayEvery',1);
		    % =======
		    % OLD
		    %for i=1:nPts
		    %    signalMovie(x,y,i) = thisSignal(i);
		    %end
		    %playMovie(signalMovie);
		    %tmpMovie = repmat(thisImage,[1 1 nPts]);
		    %tmpMovie = bsxfun(@times,thisSignal,tmpMovie);
		    %playMovie(tmpMovie);
		    %signalMovie = signalMovie + tmpMovie;
		    % =======
		end

		% normalize movie to keep consistent
		[signalMovie] = normalizeVector(signalMovie,'normRange','zeroToOne');

	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end