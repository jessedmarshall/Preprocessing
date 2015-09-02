function [inputImages, inputSignals, valid, imageSizes] = filterImages(inputImages, inputSignals, varargin)
    % filters large and small objects in an set of images, returns filtered matricies along with vector with decisions and sizes
    % biafra ahanonu
    % 2013.10.31
    % based on SpikeE code
    % inputs
        %
    % outputs
        %

    % changelog
        % updated: 2013.11.08 [09:24:12] removeSmallICs now calls a filterImages, name-change due to alteration in function, can slowly replace in codes
        % 2014.04.08 [17:17:59] vectorized algorithm, speed increase. for loop left for potential use later.
    % TODO
        %

    %========================
    % get options
    options.minNumPixels=18;
    options.maxNumPixels=150;
    options.makePlots=1;
    options.waitbarOn=1;
    options.thresholdImages = 1;
    options.SNRthreshold = 1.2;
    %
    options.modifyInputImage = 0;
    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end
    %========================
    display('filtering images...')

    nImages = size(inputImages,1);

    valid = zeros(1,nImages);
    reverseStr = '';

    if options.thresholdImages==1
        if options.modifyInputImage==1
            inputImages = thresholdImages(inputImages,'waitbarOn',1,'binary',1);
        else
            inputImagesCopy = thresholdImages(inputImages,'waitbarOn',1,'binary',1);
        end
    else
        if options.modifyInputImage==1

        else
            inputImagesCopy = inputImages;
        end
    end
    imageSizes = sum(sum(inputImagesCopy,2),3);
    imageSizes = imageSizes(:);
    % imageSizes
    [figHandle figNo] = openFigure(98, '');
        plot(1);
        plot(imageSizes);
        box off;
        xlabel('rank');ylabel('image size (px)');


    valid = (imageSizes>options.minNumPixels)&(imageSizes<options.maxNumPixels);
    % ensure vector dims are compatibly with previous scripts
    valid = valid(:)';
    if options.modifyInputImage==1
        [imgStats] = computeImageFeatures(inputImages,'thresholdImages',0);
    else
        [imgStats] = computeImageFeatures(inputImagesCopy,'thresholdImages',0);
    end
    validCompute = (imgStats.Eccentricity>0.4)...
    &(imgStats.Perimeter<50&imgStats.Perimeter>5)...
    &(imgStats.Solidity>0.8)...
    &(imgStats.EquivDiameter>3&imgStats.EquivDiameter<30)...
    &(~ismember(imgStats.Orientation,[90 -90 0]));
    valid = valid&validCompute(:)';

    % filter by SNR if inputSignals added
    if ~isempty(inputSignals)
        [signalSnr a] = computeSignalSnr(inputSignals);
        validSNR = signalSnr>options.SNRthreshold;
        valid = validSNR & valid;
        % [vs.signalPeaks, vs.signalPeakIdx] = computeSignalPeaks(vs.IcaTraces,'makePlots',0,'makeSummaryPlots',0);
    end

    % [filterImageGroups] = groupImagesByColor(inputImages,valid+1);
    % filterImageGroups = createObjMap(filterImageGroups);
    % [figHandle figNo] = openFigure(2014+round(rand(1)*100), '');
    %     imagesc(filterImageGroups);
    %     colormap(customColormap([]));
    %     box off; axis off;
    %     % colorbar

    % only keep valid images
    inputImages = inputImages(logical(valid),:,:);
    if ~isempty(inputSignals)
        inputSignals = inputSignals(logical(valid),:);
    else
        inputSignals = [];
    end

    display('done!');

    % for i = 1:nImages
    %     if options.thresholdImages==1
    %         thisFilt = squeeze(inputImages(i,:,:));
    %         thisFiltThresholded = thresholdImages(thisFilt,'waitbarOn',0);
    %     else
    %         thisFiltThresholded = squeeze(inputImages(i,:,:));
    %     end
    %     imageSizes(i) = sum(thisFiltThresholded(:)>0);
    %     % regionStat = regionprops(thisFiltThresholded, 'Eccentricity');
    %     % imageEccentricity = regionStat.Eccentricity;

    %     % display([num2str(imageSizes) ' ' num2str(imageSizes>minNumPixels)]);

    %     if (imageSizes(i)>minNumPixels)&(imageSizes(i)<maxNumPixels)
    %         valid(i) = 1;
    %     end
    %     reverseStr = cmdWaitbar(i,nImages,reverseStr,'inputStr','filtering inputs','waitbarOn',options.waitbarOn,'displayEvery',5);
    % end

    if makePlots==1
        [figHandle figNo] = openFigure(99, '');
            %
            subplot(2,1,1)
            hist(imageSizes,round(logspace(0,log10(max(imageSizes)))));
            box off;title('distribution of IC sizes');xlabel('area (px^2)');ylabel('count');
            set(gca,'xscale','log');
            h = findobj(gca,'Type','patch');
            set(h,'FaceColor',[0 0 0],'EdgeColor','w');
            %
            subplot(2,1,2)
            hist(find(valid==0),round(logspace(0,log10(max(find(valid==0))))));
            box off;title('rank of removed ICs');xlabel('rank');ylabel('count');
            set(gca,'xscale','log')
            h = findobj(gca,'Type','patch');
            set(h,'FaceColor',[0 0 0],'EdgeColor','w');
    end