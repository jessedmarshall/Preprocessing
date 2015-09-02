function [imgStats] = computeImageFeatures(inputImages, varargin)
    % filters large and small objects in an set of images, returns filtered matricies along with vector with decisions and sizes
    % biafra ahanonu
    % 2013.10.31
    % based on SpikeE code
    % inputs
    %   inputImages - [nSignals x y]
    % outputs
    %   imgStats -
    % options
    %   minNumPixels
    %   maxNumPixels
    %   thresholdImages

    % changelog
        % updated: 2013.11.08 [09:24:12] removeSmallICs now calls a filterImages, name-change due to alteration in function, can slowly replace in codes
    % TODO
        %

    %========================
    % get options
    options.minNumPixels=25;
    options.maxNumPixels=600;
    options.makePlots=1;
    options.waitbarOn=1;
    options.thresholdImages = 1;
    options.valid = [];
    options.featureList = {'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity'};
    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end
    %========================

    nImages = size(inputImages,1);

    reverseStr = '';
    % decide whether to threshold images
    if options.thresholdImages==1
        inputImages = thresholdImages(inputImages,'waitbarOn',1,'binary',1);
    end
    % loop over images and get their stats
    for imageNo = 1:nImages
        iImage = squeeze(inputImages(imageNo,:,:));
        % imagesc(iImage)
        % imgStats.imageSizes(imageNo) = sum(iImage(:)>0);
        for ifeature=featureList
            regionStat = regionprops(iImage, ifeature{1});
            try
                eval(['imgStats.' ifeature{1} '(imageNo) = regionStat.' ifeature{1} ';']);
            catch
                eval(['imgStats.' ifeature{1} '(imageNo) = NaN;']);
            end
        end
        % regionStat = regionprops(iImage, 'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity');
        % imgStats.Eccentricity(imageNo) = regionStat.Eccentricity;
        % imgStats.EquivDiameter(imageNo) = regionStat.EquivDiameter;
        % imgStats.Area(imageNo) = regionStat.Area;
        % imgStats.Orientation(imageNo) = regionStat.Orientation;
        % imgStats.Perimeter(imageNo) = regionStat.Perimeter;
        % imgStats.Solidity(imageNo) = regionStat.Solidity;

        if (mod(imageNo,10)==0|imageNo==nImages)&options.waitbarOn==1
            reverseStr = cmdWaitbar(imageNo,nImages,reverseStr,'inputStr','computing image features');
        end
    end

    if makePlots==1
        [figHandle figNo] = openFigure(1996, '');
            subplot(2,1,1)
            hist(imgStats.Area,round(logspace(0,log10(max(imgStats.Area)))));
            box off;title('distribution of IC sizes');xlabel('area (px^2)');ylabel('count');
            set(gca,'xscale','log');
            h = findobj(gca,'Type','patch');
            set(h,'FaceColor',[0 0 0],'EdgeColor','w');

            if ~isempty(options.valid)
                nPts = 2;
            else
                options.valid = ones(1,nImages);
                nPts = 1;
            end
        pointColors = ['g','r'];
        [figHandle figNo] = openFigure(1997, '');
            for pointNum = 1:nPts
                pointColor = pointColors(pointNum);
                if pointNum==1
                    valid = logical(options.valid);
                else
                    valid = logical(~options.valid);
                end
                [figHandle figNo] = openFigure(1997, '');
                fn=fieldnames(imgStats);
                for i=1:length(fn)
                    subplot(2,length(fn)/2,i)
                    eval(['iStat=imgStats.' fn{i} ';']);
                    plot(find(valid),iStat(valid),[pointColor '.'])
                    title(fn{i})
                    hold on;box off;
                    xlabel('rank'); ylabel(fn{i})
                    hold off
                end

                % subplot(2,1,1)
                % scatter3(imgStats.Eccentricity(valid),imgStats.Perimeter(valid),imgStats.Orientation(valid),[pointColor '.'])
                % xlabel('Eccentricity');ylabel('perimeter');zlabel('Orientation');
                % rotate3d on;hold on;
                % subplot(2,1,2)
                % scatter3(imgStats.Area(valid),imgStats.Perimeter(valid),imgStats.Solidity(valid),[pointColor '.'])
                % xlabel('area');ylabel('perimeter');zlabel('solidity');
                % rotate3d on;hold on;
            end

    end