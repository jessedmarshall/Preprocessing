function [xCoords yCoords] = findCentroid(inputMatrix,varargin)
	% finds the x,y centroid coordinates of each 2D in the 3D input matrix
	% biafra ahanonu
	% started: 2013.10.31 [19:39:33]
	% adapted from SpikeE code
	% inputs
		%
	% outputs
		%
	% changelog
		%
	% TODO
		%

	%========================
	options.waitbarOn = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	inputDims = size(inputMatrix);
	inputDimsLen = length(inputDims);
	if inputDimsLen==3
	    nImages = size(inputMatrix,1);
	elseif inputDimsLen==2
	    nImages = 1;
	    tmpImage = inputMatrix; clear inputMatrix;
	    inputMatrix(1,:,:) = tmpImage;
	    options.waitbarOn = 0;
	else
	    return
	end

	reverseStr = '';
	for imageNum=1:nImages
		% threshold image
		thisImage = squeeze(thresholdImages(inputMatrix(imageNum,:,:),'waitbarOn',0));
		% get the sum of the image
		imagesum = sum(sum(thisImage));
		% get coordinates
		xTmp = repmat(1:size(thisImage,2), size(thisImage,1), 1);
		yTmp = repmat((1:size(thisImage,1))', 1,size(thisImage,2));
		xCoords(imageNum) = sum(sum(thisImage.*xTmp))/imagesum;
		yCoords(imageNum) = sum(sum(thisImage.*yTmp))/imagesum;

		if (mod(imageNum,20)==0|imageNum==nImages)&options.waitbarOn==1
		    reverseStr = cmdWaitbar(imageNum,nImages,reverseStr,'inputStr','finding centroids');
		end
	end