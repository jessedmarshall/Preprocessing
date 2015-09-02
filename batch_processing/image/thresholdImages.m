function [thresholdedImage] = thresholdImages(inputImages,varargin)
    % thresholds input images and makes them binary if requested
    % biafra ahanonu
    % started: 2013.10.xx
    % adapted from SpikeE
    %
    % inputs
        %
    % outputs
        %

    % changelog
        % updated: 2013.11.04 [15:30:05] added try...catch block to get around some errors for specific filters
        % 2014.01.14 refactored so it now can handle multiple images instead of just one
        % 2014.01.16 [16:30:36] fixed error after refactoring where thresholdedImage dims were not a 3D matrix, caused assignment errors.
        % 2014.03.13 slight change to support double and other non-integer images
    % TODO
        %

    %========================
    options.threshold = 0.5;
    options.waitbarOn = 1;
    options.binary = 0;
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %     eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    nImages = size(inputImages);
    inputDims = size(inputImages);
    inputDimsLen = length(inputDims);
    if inputDimsLen==3
        nImages = size(inputImages,1);
    elseif inputDimsLen==2
        nImages = 1;
        tmpImage = inputImages; clear inputImages;
        inputImages(1,:,:) = tmpImage;
        options.waitbarOn = 0;
    else
        return
    end
    % loop over all images and threshold
    reverseStr = '';
    % pre-allocate for speed
    thresholdedImage = zeros(size(inputImages));
    for i=1:nImages

        thisFilt = squeeze(inputImages(i,:,:));
        % threshold
        maxVal=nanmax(thisFilt(:));
        cutoffVal = maxVal*options.threshold;
        % cutoffVal = quantile(thisFilt(:),options.threshold);
        replaceVal = 0;
        thisFilt(thisFilt<cutoffVal)=replaceVal;
        thisFilt(isnan(thisFilt))=replaceVal;

        % make image binary
        if options.binary==1
            thisFilt(thisFilt>=cutoffVal)=1;
        else
            % normalize
            thisFilt=thisFilt/maxVal;
        end

        % Remove any pixels not connected to the image max value if there is a filter with max values at the edge, try...catch to get around errors
        try
            [indx indy] = find(thisFilt==1); %Find the maximum
            B = bwlabeln(thisFilt);
            thisFilt(B~=B(indx,indy)) = 0;
        catch
        end
        % size(thisFilt)
        % size(thresholdedImage)
        thresholdedImage(i,:,:)=thisFilt;
        % within loop
        if (mod(i,20)==0|i==nImages)&options.waitbarOn==1
            reverseStr = cmdWaitbar(i,nImages,reverseStr,'inputStr','thresholding images');
        end
    end
    % ensure backwards compatibility
    if nImages==1
        thresholdedImage = squeeze(thresholdedImage);
    end