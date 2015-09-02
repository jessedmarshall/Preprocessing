function [matchedObjMaps euclideanStruct] = displayMatchingObjs(inputImages,globalIDs,varargin)
    % example function with outline for necessary components
    % biafra ahanonu
    % started: 2014.01.03 [19:13:01]
    % inputs
        % inputImages - cell array {1, N} N = each trial of [nFilters x y] matrices containing each set of filters, e.g. {imageSet1, imageSet2,...}
        % globalIDs, [M N] matrix with M = number of global IDs and N = each trial. Each m,n pair specifies the index of that global obj m in the data of trial n. If .globalIDs(m,n)==0, means no match was found.
    % outputs
        %
    % changelog
        %
    % TODO
        %

    %========================
    options.inputSignals = [];
    %
    options.permuteImages = 0;
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    try
        if options.permuteImages==1
            for imageNo=1:length(inputImages)
                inputImages{imageNo} = permute(inputImages{imageNo}, [3 1 2]);
            end
        end

        if ~isempty(options.inputSignals)
            figure(292)
            [nrows, ncols] = cellfun(@size, options.inputSignals);
            maxCols = max(ncols);
            signalSnrAll = NaN([length(options.inputSignals) maxCols]);
            for j=1:length(options.inputSignals)
                [signalSnr ~] = computeSignalSnr(options.inputSignals{j});
                signalSnrAll(j,1:length(signalSnr)) = signalSnr;
            end
            plot(signalSnrAll');
            % legend(292);
        end

        reverseStr = '';
        nGlobals = size(globalIDs,1);
        nObjPerGlobal = sum(globalIDs>0,2);
        % sort global IDs by those with most
        [nObjPerGlobalSorted sortedIdx] = sort(nObjPerGlobal,'descend');
        globalIDs = globalIDs(sortedIdx,:);

        for gID = 1:size(globalIDs,2)
            cumProb(gID) = sum(sum(~(globalIDs==0),2)==gID)/size(globalIDs,1);
        end
        figure(1930)
        plot(cumProb);box off;
        % set(gca,'yscale','log');
        % set(gca,'xscale','log');
        figure(1929)
        % for i=1:nGlobals
        globalNo = 1;
        saveData = 0;
        while saveData==0
            nMatchedIDs = sum(globalIDs(globalNo,:)~=0);
            directionOfNextChoice = 1;
            % if globalNo==10
            %     saveData = 1;
            % end

            if ~isempty(options.inputSignals)
                % compute shuffled signalFeatures pairwise
                % if nMatchedIDs>2
                    nShuffles = 2;
                    reverseStr = '';
                    for shuffleNo = 1:nShuffles
                        tmpGlobalIDs = globalIDs;
                        matchIDList = globalIDs(globalNo,:);
                        matchIDIdx = matchIDList~=0;
                        maxGlobalIDs = max(globalIDs,[],1);
                        % obtain a random ID within the range for each trial...clever clever...jk
                        shuffledIDs = arrayfun(@(x) randsample(x,1,true), maxGlobalIDs);
                        shuffledIDs(~matchIDIdx) = 0;
                        tmpGlobalIDs(globalNo,:) = shuffledIDs(:)';
                        [blankVar matchedSignals] = getGlobalData(inputImages,tmpGlobalIDs,options.inputSignals,globalNo);
                        matchIdx = sum(matchedSignals,2)~=0;
                        [blankVar blankVar signalFeaturesEuclideanShuffle blankVar] = getSignalFeatures(matchedSignals(matchIdx,:));
                        shuffledSignalFeaturesEuclidean(shuffleNo) = signalFeaturesEuclideanShuffle;
                        reverseStr = cmdWaitbar(shuffleNo,nShuffles,reverseStr,'inputStr','shuffling euclidean distances','waitbarOn',0,'displayEvery',1);
                    end
                    shuffledSignalFeaturesEuclideanMean(globalNo,1) = nanmean(shuffledSignalFeaturesEuclidean);
                    shuffledSignalFeaturesEuclideanStd(globalNo,1) = nanstd(shuffledSignalFeaturesEuclidean);
                    [groupImages matchedSignals] = getGlobalData(inputImages,globalIDs,options.inputSignals,globalNo);
                    % matchIdx = sum(matchedSignals,2)~=0;
                    [avgSpikeTrace signalFeatures signalFeaturesEuclideanTmp signalFeaturesNorm] = getSignalFeatures(matchedSignals);
                    signalFeaturesEuclidean(globalNo,1) = signalFeaturesEuclideanTmp;
                % else
                %     shuffledSignalFeaturesEuclideanMean(globalNo,1) = NaN;
                %     shuffledSignalFeaturesEuclideanStd(globalNo,1) = NaN;
                %     signalFeaturesEuclidean(globalNo,1) = NaN;
                % end

                subplot(2,2,1:2)

                    imagesc(signalFeaturesNorm')
                    % add labels for each feature
                    numYTicks = size(signalFeatures,2);
                    L = get(gca,'YLim');
                    set(gca,'YTick',0:1:numYTicks*2)
                    set(gca,'YTickLabel',{'','signalSnr','numOfPeaks','slopeRatio','avgFwhm','avgPeakAmplitude'})

                    % display txt in the boxes
                    sizeX = size(signalFeaturesNorm);
                    idxX = 1:(sizeX(1)*sizeX(2));
                    [I,J] = ind2sub(sizeX,idxX);
                    % round values
                    txtVals = round(signalFeatures .* 10^3) ./ 10^3;
                    text(I,J,num2str(txtVals(:)),'HorizontalAlignment','center')
                    title([num2str(globalNo) '/' num2str(nGlobals) ' globalID list: ' num2str(globalIDs(globalNo,:))])


                subplot(2,2,4)
                    % title('example trace')
                    peakROI = [-40:40];
                    set(gca,'ColorOrder',copper(nMatchedIDs));
                    plot(peakROI, avgSpikeTrace');
                    box off; axis off;
                    % add in zero line
                    hold on;
                    xval = 0;
                    x=[xval,xval];
                    y=[min(avgSpikeTrace(:)) max(avgSpikeTrace(:))];
                    plot(x,y,'r'); box off;
                    hold off;
                    title(['euclidean distance: ' num2str(signalFeaturesEuclidean(globalNo)) ' shuffled: ' num2str(shuffledSignalFeaturesEuclideanMean(globalNo))])
                % imagesc([0:0.1:1]); colorbar
                % title('reference for main plot')

                % setup the next subplot
                subplot(2,2,3)
            end

            groupVector = 1:length(inputImages);
            [groupedImages] = groupImagesByColor(groupImages,[]);
            matchedObjMaps(:,:,globalNo) = createObjMap(groupedImages);
            imagesc(matchedObjMaps(:,:,globalNo));
            imagesc(squeeze(nansum(groupImages,1))/nMatchedIDs*100);
            colormap(customColormap([]));
            title('heatmap of percent overlap object maps')
            colorbar

            suptitle(['globalID ' num2str(globalNo) '/' num2str(nGlobals) '   f:finish    left/right: forward/back'])
            [x y reply] = ginput(1);
            reply = 29;
            if isequal(reply, 102)
                return;
            elseif isequal(reply, 28)
                % go back, left
                directionOfNextChoice=-1;
            elseif isequal(reply, 29)
                % go forward, right
                directionOfNextChoice=1;
            end
            % loop if user gets to either end
            globalNo=globalNo+directionOfNextChoice;
            if globalNo<=0 globalNo = nGlobals; end
            % if globalNo>nGlobals globalNo = 1; end
            if globalNo>nGlobals saveData = 1; end

            clear groupImages
            % if mod(i,7)==0|i==nGlobals
            %     reverseStr = cmdWaitbar(i,nGlobals,reverseStr,'inputStr','creating cell maps');
            % end

        end
        % playMovie(cellmap);
        euclideanStruct.shuffledSignalFeaturesEuclideanMean = shuffledSignalFeaturesEuclideanMean;
        euclideanStruct.shuffledSignalFeaturesEuclideanStd = shuffledSignalFeaturesEuclideanStd;
        euclideanStruct.signalFeaturesEuclidean = signalFeaturesEuclidean;

    catch err
        display(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        display(repmat('@',1,7))
    end

function [groupImages matchedSignals] = getGlobalData(inputImages,globalIDs,inputSignals,globalNo)
    matchIDList = globalIDs(globalNo,:);
    matchIDIdx = matchIDList~=0;
    nMatchGlobalIDs = sum(matchIDIdx);
    if ~isempty(inputSignals)
        % get max length
        [nrows, ncols] = cellfun(@size, inputSignals);
        maxCols = max(ncols);
        matchedSignals = zeros(length(inputSignals),maxCols);
    end

    idxNo = 1;
    for j=1:length(inputImages)
        iIdx = globalIDs(globalNo,j);
        if iIdx==0
            nullImage = zeros(size(squeeze(inputImages{1}(1,:,:))));
            nullImage(1,1) = 1;
            groupImages(j,:,:) = nullImage;
        else
            groupImages(j,:,:) = squeeze(inputImages{j}(iIdx,:,:));
            if ~isempty(inputSignals)
                iSignal = inputSignals{j}(iIdx,:);
                matchedSignals(j,1:length(iSignal)) = iSignal;
            end
            idxNo = idxNo + 1;
        end
    end

function [avgSpikeTrace signalFeatures signalFeaturesEuclidean signalFeaturesNorm] = getSignalFeatures(matchedSignals)

    % get the SNR for traces
    [signalSnr ~] = computeSignalSnr(matchedSignals,'waitbarOn',0);
    % get the peak statistics
    [peakOutputStat] = computePeakStatistics(matchedSignals,'waitbarOn',0);
    slopeRatio = peakOutputStat.slopeRatio;
    avgFwhm = peakOutputStat.avgFwhm;
    avgPeakAmplitude = peakOutputStat.avgPeakAmplitude;
    avgSpikeTrace = peakOutputStat.avgSpikeTrace;
    % get the number of spikes
    [signalPeaks, signalPeakIdx] = computeSignalPeaks(matchedSignals,'makeSummaryPlots',0,'waitbarOn',0);
    numOfPeaks = sum(signalPeaks,2);
    signalFeatures = horzcat(signalSnr(:),numOfPeaks(:),slopeRatio(:),avgFwhm(:),avgPeakAmplitude(:));

    % signalFeatures(find(isnan(signalFeatures))) = 0;
    % normalize feature matrix
    X = signalFeatures;
    [m n] = size(signalFeatures);
    xMax = repmat(nanmax(X),m,1);
    xMin = repmat(nanmin(X),m,1);
    signalFeaturesNorm = (X - xMin)./(xMax - xMin);

    % compute pairwise distance
    % pdist(signalFeaturesNorm')
    signalFeaturesEuclidean = nanmean(pdist(signalFeatures));
    % signalFeaturesEuclidean = nanmean(pdist(signalFeaturesNorm));