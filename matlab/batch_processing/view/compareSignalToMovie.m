function [croppedPeakImages] = compareSignalToMovie(inputMovie, inputFilters, inputSignal, varargin)
	% shows a cropped version of inputMovie for each inputFilters and aligns it to inputSignal peaks to make sure detection is working
	% biafra ahanonu
	% started: 2013.11.04 [18:40:45]
	% inputs
		% inputMovie - matrix dims are [X Y t] - where t = number of time points
		% inputFilters - matrix dims are [n X Y] - where n = number of filters, NOTE THE DIFFERENCE
		% inputSignal - matrix dims are [n t] - where n = number of signals, t = number of time points
	% outputs
		% none, this is a display function
	% changelog
		% 2014.01.18 [12:24:29] fully implemented, cut out from controllerAnalysis, need to improve handling at beginning of movie, but that's a playMovie function issue
	% TODO
		%

	%========================
	% old way of saving, only temporary until full switch
	options.oldSave = 0;
	% size in pixels to show signal image
	options.cropSize = 20;
	% frames before/after to show
	options.timeSeq = -30:30;
	% waitbar
	options.waitbarOn = 1;
	% whether to just get the peak images and ignore showing the movie
	options.getOnlyPeakImages = 0;
	% 1 = plus shaped crosshairs, 0 = dot
	options.extendedCrosshairs = 1;
	%
	options.signalPeakArray = [];
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if isempty(options.signalPeakArray)
		[signalPeaks, signalPeakArray] = computeSignalPeaks(inputSignal, 'makePlots', 0,'makeSummaryPlots',0,'waitbarOn',options.waitbarOn);
	else
		signalPeakArray = options.signalPeakArray;
	end

	% get the centroids and other info for movie
	[xCoords yCoords] = findCentroid(inputFilters,'waitbarOn',options.waitbarOn);
	cropSize = options.cropSize;
	nSignals = size(inputFilters,1);
	nPoints = size(inputMovie,3);
	movieDims = size(inputMovie);
	timeSeq = options.timeSeq;

	% inputMovie(inputMovie>1.3) = NaN;
	% inputMovie(inputMovie<0.8) = NaN;

	% loop over all signals and visualize their peaks side-by-side with movie
	exitSignal = 0;
	for signalNo=1:nSignals
		peakLocations = signalPeakArray{signalNo};

		peakIdxs = bsxfun(@plus,timeSeq',peakLocations);
		peakIdxs(find(peakIdxs<1)) = 1;
		peakIdxs(find(peakIdxs>nPoints)) = 1;
		% get region to crop
		warning off;
		xLow = xCoords(signalNo) - cropSize;
		xHigh = xCoords(signalNo) + cropSize;
		yLow = yCoords(signalNo) - cropSize;
		yHigh = yCoords(signalNo) + cropSize;
		% check that not outside movie dimensions
		xMin = 0;
		xMax = movieDims(2);
		yMin = 0;
		yMax = movieDims(1);

		% adjust for the difference in centroid location if movie is cropped
		xDiff = 0;
		yDiff = 0;
		if xLow<xMin xDiff = xLow-xMin; xLow = xMin; end
		if xHigh>xMax xDiff = xHigh-xMax; xHigh = xMax; end
		if yLow<yMin yDiff = yLow-yMin; yLow = yMin; end
		if yHigh>yMax yDiff = yHigh-yMax; yHigh = yMax; end

		% need to add a way to adjust the cropped movie target point if near the boundary

		% get the cropped movie at peaks
		croppedPeakImages = inputMovie(yLow:yHigh,xLow:xHigh,peakLocations);
		firstImg = normalizeVector(squeeze(inputFilters(signalNo,yLow:yHigh,xLow:xHigh)),'normRange','zeroToOne');
		firstImg = padarray(firstImg(2:end-1,2:end-1),[1 1],max(firstImg(:)));
		croppedPeakImages(:,:,end+1) = firstImg;
		% move inputImage to the front
		croppedPeakImages = circshift(croppedPeakImages,[0 0 1]);
		% croppedPeakImagesTmp = croppedPeakImages(:,:,end);
		% croppedPeakImagesTmp(:,:,end+1:end+(length(croppedPeakImages)-1)) = croppedPeakImages(:,:,1:(end-1));
		% croppedPeakImages = croppedPeakImagesTmp;
		for frameNo=1:size(croppedPeakImages,3)
			croppedPeakImages(:,:,frameNo) = normalizeVector(squeeze(croppedPeakImages(:,:,frameNo)),'normRange','zeroToOne');
		end
		% croppedPeakImages = normalizeMovie(croppedPeakImages,'normalizationType','meanDivision');
		cDims = size(croppedPeakImages);
		crossHairLocation = [round(cDims(2)/2+xDiff/2) round(cDims(1)/2+yDiff/2)];
		cHairX = crossHairLocation(1);
		cHairY = crossHairLocation(2);
		% add crosshair to images.
		crossHairVal = NaN;
		croppedPeakImages(cHairY,cHairX,:) = crossHairVal;
		if options.extendedCrosshairs==1
			croppedPeakImages(cHairY-1,cHairX,:) = crossHairVal;
			croppedPeakImages(cHairY+1,cHairX,:) = crossHairVal;
			croppedPeakImages(cHairY,cHairX-1,:) = crossHairVal;
			croppedPeakImages(cHairY,cHairX+1,:) = crossHairVal;
		end

		if options.getOnlyPeakImages==0
			% get cropped version of the movie
			croppedMovie = inputMovie(yLow:yHigh,xLow:xHigh,peakIdxs);
			cDims = size(croppedMovie);
			exitSignal = playMovie(inputMovie(:,:,peakIdxs),'extraMovie',croppedMovie,...
				'extraLinePlot',inputSignal(signalNo,peakIdxs),...
				'windowLength',30,...
				'colormapColor','jet',...
				'extraTitleText',['signal #' num2str(signalNo) '/' num2str(nSignals) '    peaks: ' num2str(length(peakLocations))],...
				'primaryPoint',[xCoords(signalNo) yCoords(signalNo)],...
				'secondaryPoint',crossHairLocation);
				% 'recordMovie','test.avi',...
		end
		warning on;
		if exitSignal==1
			break;
		end
	end