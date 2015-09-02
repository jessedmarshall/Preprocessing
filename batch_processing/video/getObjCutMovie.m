function [outputCutMovie] = getObjCutMovie(inputMovie,inputImages,varargin)
	% example function with outline for necessary components
	% biafra ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputMovie - [x y frames]
		% inputImages - [nSignals x y] - NOTE the dimensions, permute(inputImages,[3 1 2]) if you use [x y nSignals] convention
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	options.cropSize = 10;
	%
	options.waitbarOn = 1;
	% vector [2 100 200] of frame to keep, if empty, output all
	options.filterVector = [];
	% 1 = make a montage of cut movies, 0 = output cell array of cuts
	options.createMontage = 1;
	% location of stim blink for montage.
	options.stimLocations = [];
	%
	options.extendedCrosshairs = 1;
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
		% do something
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

	% get the centroids and other info for movie
	[xCoords yCoords] = findCentroid(inputImages,'waitbarOn',options.waitbarOn);
	cropSize = options.cropSize;
	nSignals = size(inputImages,1);
	nPoints = size(inputMovie,3);
	movieDims = size(inputMovie);

	reverseStr = '';
	for signalNo = 1:nSignals
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
		k{signalNo} = inputMovie(yLow:yHigh,xLow:xHigh,:);

		cDims = size(k{signalNo});
		crossHairLocation = [round(cDims(2)/2+xDiff/2) round(cDims(1)/2+yDiff/2)];
		cHairX = crossHairLocation(1);
		cHairY = crossHairLocation(2);
		% add crosshair to images.
		crossHairVal = NaN;
		k{signalNo}(cHairY,cHairX,:) = crossHairVal;
		if options.extendedCrosshairs==1
			k{signalNo}(cHairY-1,cHairX,:) = crossHairVal;
			k{signalNo}(cHairY+1,cHairX,:) = crossHairVal;
			k{signalNo}(cHairY,cHairX-1,:) = crossHairVal;
			k{signalNo}(cHairY,cHairX+1,:) = crossHairVal;
		end
		reverseStr = cmdWaitbar(signalNo,nSignals,reverseStr,'inputStr','cutting out object movies','waitbarOn',options.waitbarOn,'displayEvery',2);
	end

	if options.createMontage==1
		[m n t] = size(k{1});
		if ~isempty(options.stimLocations)
			tmpMovie = NaN([m n t]);
			tmpMovie(:,:,options.stimLocations) = 1e5;
			k{end+1} = tmpMovie;
		end

		[xPlot yPlot] = getSubplotDimensions(nSignals+1);
		squareNeed = xPlot*yPlot;
		length(k);
		dimDiff = squareNeed-length(k);
		for ii=1:dimDiff
			k{end+1} = NaN([m n t]);
		end
		size(k);
		k = [k{:}];
		[m2 n2 t2] = size(k);
		nRows = yPlot+1;
		splitIdx = diff(ceil(linspace(1,n2,nRows)));
		splitIdx(end) = splitIdx(end)+1;
		k = mat2cell(k,m2,splitIdx,t2);
		k = vertcat(k{:});
	end

	outputCutMovie = k;
	clear k;