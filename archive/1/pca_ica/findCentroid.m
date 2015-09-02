function [xCoords yCoords] = findCentroid(inputMatrix)
	% biafra ahanonu
	% updated: 2013.10.31 [19:39:33]
	% adapted from SpikeE centroid finding

	% threshold image
	inputMatrix = thresholdICs(inputMatrix);
	% get the sum of the image
	imagesum = sum(sum(inputMatrix));
	% get coordinates
	xCoords = repmat(1:size(inputMatrix,2), size(inputMatrix,1), 1);
	yCoords=repmat((1:size(inputMatrix,1))', 1,size(inputMatrix,2));
	xCoords = sum(sum(inputMatrix.*xCoords))/imagesum;
	yCoords = sum(sum(inputMatrix.*yCoords))/imagesum;