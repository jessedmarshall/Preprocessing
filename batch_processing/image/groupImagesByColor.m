function [groupedImages] = groupImagesByColor(inputImages,groupVector,varargin)
	% groups images by color based on input grouping vector
	% biafra ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputImages - [nImages x y]
		% groupVector - vector with same number of elements as images in inputImages
	% outputs
		%
	% changelog
		%
	% TODO
		%

	%========================
	% 1 = threshold images, 0 = images already thresholded
	options.thresholdImages = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	if options.thresholdImages==1
		[thresholdedImage] = thresholdImages(inputImages,'binary',1,'waitbarOn',0);
	end
	if isempty(groupVector)
		groupVector = rand(1,size(thresholdedImage,1));
	end
	if size(groupVector,2)>size(groupVector,1)
		groupVector = groupVector';
	end
	% multiple thresholded images by the grouping vector
	groupedImages = bsxfun(@times,groupVector,thresholdedImage);
	% cellmap = createObjMap(groupedImages);
	% imagesc(cellmap);colorbar
	% title(options.title);