function cellFitParams = segmentImageByMaxTime_LSsub(imgs, timeWiggleRoom,...
    threshParam, minCellArea, maxCellArea, displayRegions,...
    displayGaussianFits, displayFramesToFit, displayMovie,...
    framerate, areaOverlapThresh, noiseSigma, varargin)

% Written by Lacey Kitch in 2013

% image segmentation based on timing of maximum pixel value
% includes gaussian fits for each cell (in max frame)
% also includes an optional initialization with ICA results

% imgs: raw data
% timeWiggleRoom: number of frames that the max times of nearby pixels are
%   allowed to be apart and still classified as the same region
% threshParam: either a raw value (like 1.008) or a percentile (like 30)
% minCellArea: minimum area of max time clustered region, in pixels
% maxCellArea: maxmimum area
% displayRegions: toggle, to display the max time regions
% displayGaussianFits: toggle, to display the gaussian fits to cell maxes
% displayFramesToFit: toggle, to display the max frames for fitting
% displayMovie: toggle, to display the movie after a cell's image has been
%   subtracted

haveBG=0;
suppressOutput=0;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'localICimgs')
        if ~isempty(options.icImgs)
            initWithICs=1;
            icImgs=options.localICimgs;
        else
            initWithICs=0;
        end
        if isfield(options, 'localICtraces')
            icTraces=options.localICtraces;
        else
            warning('Must include both IC images and IC traces if you want to initialize with ICA results');
            initWithICs=0;
        end
        if isfield(options, 'initWithICsOnly')
            initWithICsOnly=options.initWithICsOnly;
            initWithICs=1;
        else
            initWithICsOnly=0;
        end
    else
        initWithICs=0;
    end
    if isfield(options, 'bg')
        haveBG=1;
        bg=options.bg;
    end
    if isfield(options, 'vlm')
        if options.vlm && ~haveBG
            disp('Waring: calculating traces without taking background into account')
        end
    end
    if isfield(options, 'suppressOutput')
        suppressOutput=options.suppressOutput;
    end
else
	initWithICs=0;
end

% general values needed for all initialization
imgSize=size(imgs(:,:,1));
nFrames=size(imgs,3);
fitWidth=6;    % width for finding subregion of frame to fit gaussian

% this section initializes EM parameters by the timing on the maximum
% values of the pixels
if ~initWithICs || ~initWithICsOnly
    
    if ~suppressOutput
        disp('Initializing with max pixel clustering...')
    end
    
    if isempty(displayFramesToFit)
        error('not enough inputs to segment image function (initialization)')
    end
    imgSize=size(imgs(:,:,1));
    nFrames=size(imgs,3);
    imgsForTiming=imgs;

    % create imgsForTiming, which is a spatially and temporally smoothed
    % version of imgs, for extracting time of the max of each pixel
    for t=1:nFrames
        input=imgsForTiming(:,:,t);
        input=padarray(input,[2 2], 'replicate');
        input=medfilt2(input,[3 3]);
        imgsForTiming(:,:,t)=input(3:end-2, 3:end-2);
    end
    if framerate>5
        for i=1:imgSize(1)
            for j=1:imgSize(2)
                thisPixelTrace=padarray(squeeze(imgsForTiming(i,j,:)), 2, 'replicate');
                thisPixelTrace=conv(thisPixelTrace,ones(5,1),'same')/5;
                imgsForTiming(i,j,:)=thisPixelTrace(3:end-2);
            end
        end
    end

    % find max projection and timing of max in smoothed movie
    [maxImg, maxTimes]=max(imgsForTiming,[],3);

    % calculate a threshold and find where the max projection is above it
    if threshParam<2    % if threshParam<2, then this is a number that represents the threshold. If it is >2, it must be a percentile.
        thresh=threshParam;
    else
        if size(imgsForTiming,3)>500
            thresh=prctile(reshape(imgsForTiming(:,:,randperm(1:size(imgsForTiming,3),500)),...
                [imgSize(1)*imgSize(2)*500, 1]), threshParam);
        else
            thresh=prctile(imgsForTiming(:), threshParam);
        end
    end
    if thresh>1.03 || thresh<1
        warning(['Weird threshold value in initialization, thresh = ' num2str(thresh)])
    end
    minVal=min(min(min(imgsForTiming)));
    maxImg(maxImg<thresh)=minVal;
    maxTimes(maxImg<thresh)=-100;
    origNumPixels=sum(maxImg(:)>=thresh);

    % find the location and value of the maximum pixel for the 1st loop
    [maxPixelVal, maxPixelLoc]=max(maxImg(:));


    % loop, finding max pixel each time
    cellInd=0;
    nCellsMax=5*round(origNumPixels/minCellArea);
    cellFitParams=zeros(nCellsMax,6);
    [fullxdata,fullydata]=meshgrid(1:imgSize(2), 1:imgSize(1));
    gaussImgs=zeros(nCellsMax, imgSize(1)*imgSize(2));
    iterNum=0;
    while maxPixelVal>thresh && iterNum<nCellsMax

        iterNum=iterNum+1;

        % this displays the max projection as the loop progresses,
        % each time marking the max pixel and then zeroing out when regions
        % are zeroed for the next loop iteration
        if displayRegions
            figure(6); imagesc(maxImg) %#ok<*UNRCH>
            [jmax, imax]=ind2sub(imgSize, maxPixelLoc);
            hold on
            plot(imax, jmax, 'k*')
            hold off
            pause(2)
        end

        % find when the max occurs at that pixel and find other pixels
        % which have a similar max time and are in a connected region
        thisMaxTime=maxTimes(maxPixelLoc);
        thisRegion=abs(maxTimes-thisMaxTime)<=timeWiggleRoom;
        thisRegionLabeled=bwlabel(thisRegion,4);
        thisRegionLabeled(thisRegionLabeled~=thisRegionLabeled(maxPixelLoc))=0;
        thisRegionLabeled=logical(thisRegionLabeled);
        if displayRegions
            figure(17); 
            subplot(121); imagesc(thisRegion)
            figure(17);
            subplot(122); imagesc(thisRegionLabeled)
            pause(0.5)
        end

        % if this region is large enough, it is a candidate cell
        if sum(thisRegionLabeled(:))>=minCellArea && sum(thisRegionLabeled(:))<=maxCellArea

            %%% at this point the region is a candidate cell. now we need
            %%% to init the params.
            %%% next steps:
                % find frame of max
                % fit gaussian and store params

            % convert to double and subtract one for fitting
            % (because frame is DFOF, which centers on 1)
            if haveBG
                frameToFit=double(imgs(:,:,thisMaxTime)-bg-1);
            else
                frameToFit=double(imgs(:,:,thisMaxTime)-1);
            end
            if displayFramesToFit
                figure(22); subplot(121); imagesc(frameToFit);
            end

            % restrict to local area around the maximum
            % get initial fit parameters based on region properties
            % set param fit initialization, upper bounds, lower bounds
            % perform fit
            try
                [params,resnorm,frameToFit]=fit2DgaussToImgSubregion(frameToFit, thisRegionLabeled, maxPixelLoc, fitWidth, displayFramesToFit);

                % this displays the max frame and the gaussian fit
                if displayGaussianFits
                    % use parameters to create actual gaussian filter image
                    fitImg=gfun(params,[fullydata(:), fullxdata(:)]);
                    fitImg=reshape(fitImg, imgSize(1), imgSize(2));
                    figure(10)
                    subplot(121)
                    imagesc(frameToFit)
                    subplot(122)
                    imagesc(fitImg);
                    colorbar
                    title(num2str(resnorm/norm(frameToFit(:))))
                    pause(1)
                end

                % if the fit is good enough, we store the parameters and take this cell
                % out of the movie for the remaining estimation
                if resnorm/norm(frameToFit(:))<0.1

                    cellInd=cellInd+1;
                    cellFitParams(cellInd,:)=params;

                    % now we find the most likely traces belonging to the cells
                    % found thus far, and subtract them
                    gaussImgs(cellInd,:)=gfun([params(1:5), 1],[fullydata(:), fullxdata(:)]);
                    pixelsToUse=sum(gaussImgs,1)>0.3;
                    c=gaussImgs(1:cellInd,pixelsToUse)';
                    dataSubset=zeros(sum(pixelsToUse),nFrames);
                    for fr=1:nFrames
                        thisFrame=imgsForTiming(:,:,fr);
                        dataSubset(:,fr)=thisFrame(pixelsToUse);
                    end

                    % check the new cell images for singularity. if near singular,
                    % then skip subtracting the trace times this fit and just zero
                    % out the region that was just found.
                    s=svd(c'*c);
                    if sum(s<(0.005*max(s)))<1
                        dataSubset=dataSubset-1;
                        mostLikelyTraces=(c'*c)\c'*dataSubset;
                        % now subtract out the gaussian image times the most likely trace
                        c=gaussImgs(1:cellInd,:)';
                        c=reshape(c, [imgSize(1), imgSize(2), cellInd]);
                        for fr=1:nFrames
                            for cInd=1:cellInd
                                imgsForTiming(:, :, fr)=imgsForTiming(:, :, fr)-...
                                    c(:,:,cInd)*mostLikelyTraces(cInd,fr);
                            end
                            if displayMovie
                                figure(11); subplot(121); imagesc(imgs(:,:,fr));
                                set(gca, 'CLim', [0.98, 1.1])
                                figure(11); subplot(122); imagesc(imgsForTiming(:,:,fr));
                                set(gca, 'CLim', [0.98, 1.1])
                                pause(0.03);
                            end
                        end


                        % find max projection and timing of max in smoothed movie
                        [maxImg, maxTimes]=max(imgsForTiming,[],3);
                        % set any extreme maximum values to the minVal, since these
                        % probably result from subtraction of a large negative value
                        % from a noisy identified gaussian, and we don't want to re-fit
                        % these areas
                        maxImg(maxImg>maxPixelVal)=minVal;
                        maxImg(maxImg<thresh)=minVal;
                        maxTimes(maxImg<thresh)=-100;
                    else
                        regionToExclude=thisRegionLabeled;
                        maxTimes(regionToExclude)=-100;
                        maxImg(regionToExclude)=minVal;
                    end

                else
                    regionToExclude=thisRegionLabeled;
                    maxTimes(regionToExclude)=-100;
                    maxImg(regionToExclude)=minVal;
                end
            catch
                regionToExclude=thisRegionLabeled;
                maxTimes(regionToExclude)=-100;
                maxImg(regionToExclude)=minVal;
            end

        else
            regionToExclude=thisRegionLabeled;
            maxTimes(regionToExclude)=-100;
            maxImg(regionToExclude)=minVal;
        end
        [maxPixelVal, maxPixelLoc]=max(maxImg(:));
    end
    cellFitParams=cellFitParams(1:cellInd,:);
    cellFitParams=cellFitParams(:,1:5);
    clear imgsForTiming
end


% if input is there, also get initialization from IC images, in case max
% timing missed any ICs
if initWithICs
    icDimsOK=1;

    if initWithICsOnly

    end
    yDim=find(size(icImgs)==imgSize(1),1,'first');
    xDim=find(size(icImgs)==imgSize(2),2);
    xDim(xDim==yDim)=[];

    if isempty(yDim) || isempty(xDim)
        error('icImgs is the wrong size, not initializing with ICA results')
        icCellFitParams=zeros(0,5);
        icDimsOK=0;
    else
        icDim=1:3;
        icDim([xDim, yDim])=[];
        icImgs=permute(icImgs, [yDim, xDim, icDim]);
        nICs=size(icImgs,3);

        if size(icTraces,1)~=nICs
            icTraces=icTraces';
        end

        if size(icTraces,1)~=nICs || size(icTraces,2)~=nFrames
            warning('icTraces is the wrong size, not initializing with ICA results')
            icCellFitParams=zeros(0,5);
            icDimsOK=0;
        end
    end

    if icDimsOK
        icCellFitParams=zeros(nICs,5);
        for icInd=1:nICs
            frameToFit=getFrameToFit(icTraces(icInd,:),imgs,noiseSigma,20);
            if haveBG
                frameToFit=double(frameToFit-bg-1);
            else
                frameToFit=double(frameToFit-1);
            end
            thisRegionLabeled=icImgs(:,:,icInd);
            [maxVal,maxPixelLoc]=max(thisRegionLabeled(:));
            thisRegionLabeled(thisRegionLabeled<0.3*maxVal)=0;
            thisRegionLabeled(thisRegionLabeled>0)=1;
            thisRegionLabeled(thisRegionLabeled<0)=0;
            thisRegionLabeled=logical(thisRegionLabeled);
            thisRegionLabeled=bwlabel(thisRegionLabeled,4);
            thisRegionLabeled(thisRegionLabeled~=thisRegionLabeled(maxPixelLoc))=0;
            [params,~,~]=fit2DgaussToImgSubregion(frameToFit, logical(thisRegionLabeled),...
                maxPixelLoc, fitWidth, displayFramesToFit);
            
            if displayFramesToFit
                cellImg=calcCellImgs(params, size(frameToFit));
                figure(97);
                %subplot(131); imagesc(frameToFit); 
                subplot(132); imagesc(icImgs(:,:,icInd));
                subplot(133); imagesc(cellImg);
                pause(1)
            end
            if ~isempty(params)
                icCellFitParams(icInd,:)=params(1:5);
            end
        end
    end
    icCellFitParams(sum(icCellFitParams,2)==0,:)=[];

    if initWithICsOnly
        cellFitParams=icCellFitParams;
    else
        cellFitParams=[cellFitParams; icCellFitParams];
    end
end

calcTraces=0;
[~,cellFitParams,~]=resolveBorderConflicts(cellFitParams,areaOverlapThresh,imgs,calcTraces);


% to github from file segmentImageByMaxTime_LSsub on 12/11/13 at 5:59pm
