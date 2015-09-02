function [inputImages inputSignals choices] = signalSorter(inputImages,inputSignals,inputID,nSignals,varargin)
    % displays a GUI for sorting images and their associated signals, also does preliminary sorting based on image/signal properties
    % biafra ahanonu
    % started: 2013.10.08
    % based on code written by maggie carr
    % dependent code
        % getOptions.m, createObjMap.m, removeSmallICs.m, identifySpikes.m
    % inputs
        % inputImages - [N x y] matrix where N = number of images, x/y are dimensions. Use permute(inputImages,[3 1 2]) if you use [x y N] for matrix indexing.
        % inputSignals - [N time] matrix where N = number of signals (traces) and time = frames.
        % inputID - obsolete, kept for compatibility, just input empty []
        % nSignals - obsolete, kept for compatibility
    % outputs
        % inputImages - [N x y] matrix where N = number of images, x/y are dimensions with only manual choices kept.
        % inputSignals
        % choices

    % changelog
        % 2013.10.xx changed to ginput and altered UI to show more relevant information, now shows a objMap overlayed with the current filter, etc.
        % 2013.11.01 [15:48:56]
            % Finished removing all cell array indexing by day, increase maintainability.
            % Input is now filters and traces instead of loading a directory inside fxn (which is cryptic). Output is filtered traces.
            % Can now move forward AND back, 21st century stuff. Also changed some of the other controls to make UI more user friendly.
        % 2013.11.03 [12:45:03] added a panel so that you can see the average trace around all spikes in an IC filter's trace along with several other improvements.
        % 2013.11.04 [10:30:40] changed invalid subscripting to valid, previous way involved negating choices, prone to error.
        % 2013.11.13 [09:25:24] added the ability to loop around and pre-maturely exit
        % 2013.11.19 [09:19:07] auto-saves decisions in case of a crash or other problem
        % 2013.12.07 [16:30:32] added more option (e.g. 's' key to mark rest of signals as bad)
        % 2013.12.10 [09:38:57] refactored a bit to make code more clear
        % 2013.12.15 [22:48:56] now overlays the good and bad images onto the entire image cell map, good for determining whether you've hit all the 'relevant' images
        % 2014.01.05 [09:23:54] small amount of
        % 2014.01.27 - started better integration auto-detecting based on SNR, etc.
        % 2014.03.06 - integrated support for manual scoring of automatic classification via abstraction (not explicitly loading classifier, but scoring pre-defined questionable input signals)
        % 2014.03.12 - sort by SNR or random, view montage of movie frames at peak or compare the signal to the movie directly
        % 2014.05.19 - improved SNR sort for NaNs, montage handles traces with no peaks, etc.

    % TODO
        % DONE: allow option to mark rest as bad signals

    % ============================
    % set default options
    options.nSignals = size(inputImages,1);
    % string to display over the cell map
    options.inputStr = '';
    % can pre-load choices, 1 = good, 0 = bad, 2 = questionable
    options.valid = [];
    % directory to store temporary decisions
    options.tmpDir = ['private' filesep 'tmp'];
    % id for the current session, use system time since it'll be unique
    options.sessionID = num2str(java.lang.System.currentTimeMillis);
    % threshold for SNR auto-annotate
    options.SnrThreshold = 1.2;
    %
    options.slopeRatioThreshold = 0;
    % location of classifier
    options.classifierFilepath = [];
    % type of classifier that was used
    options.classifierType = 'nnet';
    % upper range pct score to manually sort
    options.upperClassifierThres = 0.6;
    % lower range pct score to manually sort
    options.lowerClassifierThres = 0.3;
    % movie matching inputImages/inputSignals src, used to find movie frames at peaks
    options.inputMovie = [];
    % sort by the SNR
    options.sortBySNR = 0;
    % randomize order
    options.randomizeOrder = 0;

    % get options
    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end
    % ============================

    % for manual classification of automated signals
    if ~isempty(valid)&~isempty(find(valid==2))
        inputImagesBackup = inputImages;
        inputSignalsBackup = inputSignals;
        questionableSignalIdx = find(valid==2);
        inputImages = inputImages(questionableSignalIdx,:,:);
        inputSignals = inputSignals(questionableSignalIdx,:);
        validBackup = valid;
        valid = zeros(1,length(questionableSignalIdx));
    else
        validBackup = [];
    end


    % get the SNR for traces and sort traces by this if asked
    [signalSnr ~] = computeSignalSnr(inputSignals);
    if options.sortBySNR==1
        signalSnr(isnan(signalSnr)) = -Inf;
        [signalSnr newIdx] = sort(signalSnr,'descend');
        signalSnr(isinf(signalSnr)) = NaN;
        inputSignals = inputSignals(newIdx,:);
        inputImages = inputImages(newIdx,:,:);
        if ~isempty(valid)
            valid = valid(newIdx);
        end
    end

    % randomize the order if asked
    if options.randomizeOrder==1
        randIdx = randperm(options.nSignals);
        inputSignals = inputSignals(randIdx,:);
        inputImages = inputImages(randIdx,:,:);
        if ~isempty(valid)
            valid = valid(randIdx);
        end
    end
    % =======
    % create a cell map to overlay current IC filter onto
    objMap = createObjMap(inputImages);

    % get the peak statistics
    [peakOutputStat] = computePeakStatistics(inputSignals,'waitbarOn',0);
    % threshold images
    inputImagesThres = thresholdImages(inputImages,'waitbarOn',1);

    % remove small ICs unless a pre-list is loaded in
    if isempty(valid)
        [~, ~, valid, inputImageSizes] = filterImages(inputImages, inputSignals,'thresholdImages',1);
        %
        validPre = valid;
        % pre-select as valid if SNR is above a certain threshold
        validSNR = signalSnr>options.SnrThreshold;
        validPre = valid | validSNR;
        validSlope = peakOutputStat.slopeRatio>options.slopeRatioThreshold;
        validPre = validPre & validSlope;
        % Since 0=invalid, 1=valid, -1=unknown, set all '1' to unknown
        valid(find(valid==1)) = -1;
    else
        % [~, ~, ~, inputImageSizes] = filterImages(inputImagesThres, inputSignals,'thresholdImages',0);
        inputImageSizes = sum(sum(inputImagesThres,2),3);
        inputImageSizes = inputImageSizes(:);
        validPre = valid;
    end

    % =======
    % plot information about the traces
    % plotSignalStatistics(inputSignals,inputImageSizes,inputStr,'r','hold off',signalSnr,peakOutputStat.slopeRatio)
    [signalPeaks, signalPeakIdx] = computeSignalPeaks(inputSignals);
    plotSignalStatisticsWrapper(inputSignals,inputImages,validPre,inputImageSizes,inputStr,signalSnr,peakOutputStat);

    % =======
    % loop over choices
    nSignals = size(inputImages,1);
    display(['# signals: ' num2str(nSignals)]);
    % valid = ones(1,size(inputImages,1))*-1;
    choices = chooseSignals(options,1:nSignals, inputImages,inputSignals,objMap, valid, inputStr,tmpDir,sessionID,signalPeakIdx,signalSnr,inputImagesThres,inputImageSizes);
    % assume all skips were good ICs that user forgot to enter
    validChoices = choices;
    validChoices(find(validChoices==-1))=1;
    validChoices = logical(validChoices);

    % =======
    % plotSignalStatisticsWrapper(inputSignals,inputImages,validChoices,inputImageSizes,inputStr,signalSnr,peakOutputStat);

    % if manually scoring automatic, combine manual classification with automatic
    if ~isempty(validBackup)&~isempty(find(validBackup==2))
        valid = validBackup;
        % add the manual scores for the questionable signals into the valid input vector
        % validChoices
        % questionableSignalIdx
        valid(questionableSignalIdx) = validChoices;
        validChoices = logical(valid);
        choices = validChoices;
        % restore original input data
        inputImages = inputImagesBackup;
        inputSignals = inputSignalsBackup;
    end

    % =======
    % filter input for valid signals
    inputImages = inputImages(validChoices,:,:);
    inputSignals = inputSignals(validChoices,:);

function plotSignalStatisticsWrapper(inputSignals,inputImages,validChoices,inputImageSizes,inputStr,signalSnr,peakOutputStat)
    % plot good and bad signals with different colors

    % determine number of IC filters to investigate
    pointColor = ['r','g'];
    for pointNum = 1:2
        if pointNum==1
            valid = logical(~validChoices);
        else
            valid = logical(validChoices);
        end
        % plot information about the traces
        plotSignalStatistics(inputSignals(valid,:),inputImageSizes(valid),inputStr,pointColor(pointNum),'hold on',signalSnr(valid),peakOutputStat.slopeRatio(valid))
    end

function plotSignalStatistics(inputSignals,inputImageSizes,inputStr,pointColor, holdState,signalSnr,slopeRatio)
    % plot statistics for input signal

    % get best fit line SNR v slopeRatio
    p = polyfit(signalSnr,slopeRatio,1);   % p returns 2 coefficients fitting r = a_1 * x + a_2
    r = p(1) .* signalSnr + p(2); % compute a new vector r that has matching datapoints in x
    if ~isempty(slopeRatio)&~isempty(signalSnr)
        % start plotting!
        figNo = 1776;%AMERICA
        [figHandle figNo] = openFigure(figNo, '');
        hold off;
        plot(normalizeVector(slopeRatio),'Color',[4 4 4]/5);hold on;
        plot(normalizeVector(signalSnr),'r');
        title(['SNR in trace signal for ' inputStr])
        hleg1 = legend('S_{ratio}','SNR');
        xlabel('ic rank');ylabel('SNR');box off;hold off;

        [figHandle figNo] = openFigure(figNo, '');
        hold off;
        plot(slopeRatio,'Color',[4 4 4]/5);hold on;
        plot(signalSnr,'r');
        title(['SNR in trace signal for ' inputStr])
        hleg1 = legend('S_{ratio}','SNR');
        xlabel('ic rank');ylabel('SNR');box off;hold off;

        [figHandle figNo] = openFigure(figNo, '');
        scatter(signalSnr,slopeRatio,[pointColor '.']);hold on;
        plot(signalSnr, r, 'k-');
        title(['SNR v S_{ratio} for ' inputStr])
        xlabel('SNR');ylabel('S_{ratio}');box off;
        eval(holdState);

        [figHandle figNo] = openFigure(figNo, '');
        scatter3(signalSnr,slopeRatio,inputImageSizes,[pointColor '.'])
        title(['SNR, S_{ratio}, filter size for ' inputStr])
        xlabel('SNR');ylabel('S_{ratio}');zlabel('ic size');
        legend({'bad','good'});rotate3d on;
        eval(holdState);
    end

function [valid] = chooseSignals(options,signalList, inputImages,inputSignals,objMap, valid, inputStr,tmpDir,sessionID,signalPeakIdx,signalSnr,inputImagesThres,inputImageSizes)
    % manually decide which signals are good or bad, pre-computed values input to speed up movement through signals

    if ~exist(tmpDir,'file')
        mkdir(tmpDir);
    end

    % mainFig = openFigure(1,'full');
    mainFig = figure(1);

    % location of each subplot
    if ~isempty(options.inputMovie)
        objMapPlotLoc = 4;
        tracePlotLoc = [5:6];
    else
        tracePlotLoc = [4:6];
        objMapPlotLoc = 1;
    end
    inputMoviePlotLoc = 1:2;
    filterPlotLoc = 2;
    avgSpikeTracePlot = 3;
    subplotX = 3;
    subplotY = 2;

    % instructions
    instructionStr =  ['up/down:good/bad | left/right: forward/back | m:(montage peak images) | c:(compare signal to movie) |',10,' f:finished | g:(goto signal) | s:(set remaining signals to bad) | signals are assumed good',10,10,10];
    instructionStr =  ['controls',10,10,'up/down:good/bad',10,'left/right: forward/back',10,'m: peak images',10,'c: movie signal',10,'f:finished',10,'g: goto signal',10,'s: remaining bad',10,'signals assumed good'];
    suptitleHandle = suptitle(instructionStr);
    set(suptitleHandle,'FontSize',10,'FontWeight','normal')
    set(suptitleHandle, 'horizontalAlignment', 'left')
    set(suptitleHandle, 'units', 'normalized')
    h1 = get(suptitleHandle, 'position');
    set(suptitleHandle, 'position', [0 -0.2 h1(3)]);

    % plot the cell map to provide context
    subplot(subplotY,subplotX,objMapPlotLoc);
    imagesc(objMap); axis off; colormap gray;
    title(['objMap' inputStr]);hold on;

    % make color image overlays
    zeroMap = zeros(size(objMap));
    oneMap = ones(size(objMap));
    green = cat(3, zeroMap, oneMap, zeroMap);
    blue = cat(3, zeroMap, zeroMap, oneMap);
    red = cat(3, oneMap, zeroMap, zeroMap);
    warning off
    imageOverlay = imshow(blue);
    goodFilterOverlay = imshow(green);
    badFilterOverlay = imshow(red);
    warning on
    hold off

    % get values for plotting
    peakROI = [-40:40];
    minValTraces = min(inputSignals(:));
    minValConstant = -0.1
    if minValTraces<minValConstant
        minValTraces = minValConstant;
    end
    maxValTraces = nanmax(inputSignals(:));
    if maxValTraces>0.4|maxValTraces<0.3
        % maxValTraces = 0.35;
    end

    % filter based on the list
    inputImages = inputImages(signalList,:,:);
    inputSignals = inputSignals(signalList,:);

    % loop over chosen filters
    nImages = size(inputImages,1);

    % initialize loop variables
    saveData=0;
    i = 1;
    reply = 0;
    loopCount = 1;
    warning off

    % pre-calculate
    % if ~isempty(options.inputMovie)
    %     croppedPeakImages = {};
    %     reverseStr = '';
    %     for j=1:nImages
    %         figure(79879);
    %         thisTrace = inputSignals(j,:);
    %         [croppedPeakImages{j}] = viewMontage(options.inputMovie,inputImages(j,:,:),thisTrace);
    %         reverseStr = cmdWaitbar(j,nImages,reverseStr,'inputStr','getting montages','waitbarOn',1,'displayEvery',5);
    %     end
    % end

    % only exit if user clicks options that calls for saving the data
    while saveData==0
        figure(1);
        % change figure color based on nature of current choice
        if valid(i)==1
            set(mainFig,'Color',[0 0.8 0]);
        elseif valid(i)==0
            set(mainFig,'Color',[0.8 0 0]);
        else
            set(mainFig,'Color',[0.42 0.42 0.42]);
        end

        % get loop specific values
        directionOfNextChoice=0;
        thisImage = squeeze(inputImages(i,:,:));
        thisTrace = inputSignals(i,:);
        cellIDStr = ['#' num2str(i) '/' num2str(nImages)];

        if ~isempty(options.inputMovie)
            subplot(subplotY,subplotX,inputMoviePlotLoc)
                % tic
                testpeaks = signalPeakIdx{i};
                if(~isempty(testpeaks))
                    try

                        [croppedPeakImages] = viewMontage(options.inputMovie,inputImages(i,:,:),thisTrace);
                    catch

                    end
                else
                    imagesc(thisImage);
                    colormap(customColormap([]));
                end
                % toc
                % imagesc(croppedPeakImages{i});
                % colormap(customColormap([]));
                % axis off;
        else
            % show the current image
            subplot(subplotY,subplotX,filterPlotLoc)
                imagesc(thisImage);
                colormap gray
                axis off; % ij square
                title(['signal ' cellIDStr]);
        end
            % use thresholded image as AlphaData to overlay on cell map, reduce number of times this is accessed to speed-up analysis
            if mod(loopCount,20)==0|loopCount==1
                subplot(subplotY,subplotX,objMapPlotLoc)
                    % colormap gray
                    goodImages = createObjMap(inputImages(valid==1,:,:));
                    if(isempty(goodImages)) goodImages = zeros(size(objMap)); end
                    badImages = createObjMap(inputImages(valid==0,:,:));
                    if(isempty(badImages)) badImages = zeros(size(objMap)); end
                    set(goodFilterOverlay, 'AlphaData', goodImages);
                    set(badFilterOverlay, 'AlphaData', badImages);
            end
            set(imageOverlay, 'AlphaData', squeeze(inputImagesThres(i,:,:)));

        % if signal has peaks, plot the average signal and other info
        testpeaks = signalPeakIdx{i};
        if(~isempty(testpeaks))
            % tic
            % plot all signals and the average
            subplot(subplotY,subplotX,avgSpikeTracePlot);
                [slopeRatio] = plotPeakSignal(thisTrace,testpeaks,cellIDStr,instructionStr,minValTraces,maxValTraces,peakROI);
            % add in the ratio of the rise/decay slopes. Should be >>1 for calcium
            % subplot(subplotY,subplotX,filterPlotLoc)
                % title(['signal ' cellIDStr]);
            % plot the trace
            subplot(subplotY,subplotX,tracePlotLoc)
                thisStr = [' | SNR = ' num2str(signalSnr(i)) ' | S_{ratio} = ' num2str(slopeRatio) ' | # peaks = ' num2str(length(testpeaks)) ' | size (px) = ' num2str(inputImageSizes(i))];
                plotSignal(thisTrace,testpeaks,cellIDStr,thisStr,minValTraces,maxValTraces);
                showROITrace = 0;
                if ~isempty(options.inputMovie)&showROITrace==1
                    hold on
                    [tmpTrace] = applyImagesToMovie(inputImagesThres(i,:,:),options.inputMovie,'alreadyThreshold',1,'waitbarOn',0);
                    tmpTrace = squeeze(tmpTrace);
                    % nanmean(tmpTrace)
                    % nanmin(tmpTrace)
                    % nanmax(tmpTrace)
                    if abs(nanmax(tmpTrace))<abs(nanmin(tmpTrace))
                        tmpTrace = -tmpTrace;
                    end
                    tmpTrace = tmpTrace+nanmin(tmpTrace);
                    % tmpTrace = (tmpTrace-nanmean(tmpTrace))/nanmean(tmpTrace);
                    tmpTrace = nanmax(thisTrace)*normalizeVector(tmpTrace,'normRange','zeroToOne')+0.1;
                    plot(tmpTrace,'k');
                    legend('original','ROI');legend boxoff;
                    axis([0 length(thisTrace) minValTraces maxValTraces+0.1]);
                    hold off
                end
            % toc
        else
            subplot(subplotY,subplotX,avgSpikeTracePlot);
                plot(peakROI,thisTrace(1:length(peakROI)));
                xlabel('frames');ylabel('df/f');
                ylim([minValTraces maxValTraces]);
                title(['signal peaks ' cellIDStr])
            subplot(subplotY,subplotX,tracePlotLoc)
                plot(thisTrace, 'r');
                xlabel('frames');ylabel('df/f');
                axis([0 length(thisTrace) minValTraces maxValTraces]);
                thisStr = [' | SNR = ' num2str(signalSnr(i)) ' | S_{ratio} = ' num2str(NaN) ' | # peaks = ' num2str(length(testpeaks)) ' | size (px) = ' num2str(inputImageSizes(i))];
                title(['signal ' cellIDStr thisStr])
        end

        % get user input
        figure(1);
        [x,y,reply]=ginput(1);
        % waitforbuttonpress
        % reply = double(get(gcf,'CurrentCharacter'));

        % make a montage of peak frames
        if isequal(reply, 109)&~isempty(options.inputMovie)
            [croppedPeakImages] = viewMontage(options.inputMovie,inputImages(i,:,:),thisTrace);
            ginput(1);
            close(2);figure(mainFig);
        % compare signal to movie
        elseif isequal(reply, 99)&~isempty(options.inputMovie)
            compareSignalToMovie(options.inputMovie, inputImages(i,:,:), thisTrace,'waitbarOn',0,'timeSeq',-10:10);
        else
            [valid directionOfNextChoice saveData i] = respondToUserInput(reply,i,valid,directionOfNextChoice,saveData,nImages);
        end

        % loop if user gets to either end
        i=i+directionOfNextChoice;
        if i<=0 i = nImages; end
        if i>nImages i = 1; end
        % pause(0.001);
        figure(mainFig);

        % already checked that tmp folder exists, then save
        if exist(tmpDir,'file')
            save([tmpDir filesep 'tmpDecisions_' sessionID '.mat'],'valid');
        end

        loopCount = loopCount+1;
    end
    warning on

function [croppedPeakImages2] = viewMontage(inputMovie,inputImage,thisTrace)
    croppedPeakImages = compareSignalToMovie(inputMovie, inputImage, thisTrace,'getOnlyPeakImages',1,'waitbarOn',0,'extendedCrosshairs',0);
    % display cropped images
    % figure(2);
    % for i=1:size(croppedPeakImages,3)
    %     kurtosisM(1,i) = kurtosis(sum(squeeze(croppedPeakImages(i,:,:)),1));
    %     kurtosisM(2,i) = kurtosis(sum(squeeze(croppedPeakImages(i,:,:)),2));
    %     % [kurtosisX kurtosisY]
    % end
    % kurtosisM'

    croppedPeakImages2(:,:,:,1) = croppedPeakImages;
    warning off
    montage(permute(croppedPeakImages2(:,:,:,1),[1 2 4 3]))
    croppedPeakImages2 = getimage;
    % change zeros to ones, fixes range of image display
    croppedPeakImages2(croppedPeakImages2==0)=NaN;
    imagesc(croppedPeakImages2);
    customColors = customColormap([]);
    colormap(customColors);
    axis off;
    % title('frames at signal peaks, press any key to exit');
    % ginput(1);
    % close(2);figure(mainFig);
    % clear croppedPeakImages2
    warning on

function [slopeRatio] = plotPeakSignal(thisTrace,testpeaks,cellIDStr,instructionStr,minValTraces,maxValTraces,peakROI)
    % display plots of the signal around peaks in the signal

    [peakOutputStat] = computePeakStatistics(thisTrace,'waitbarOn',0);
    avgSpikeTrace = peakOutputStat.avgSpikeTrace;
    spikeCenterTrace = peakOutputStat.spikeCenterTrace{1};
    slopeRatio = peakOutputStat.slopeRatio;

    plot(repmat(peakROI, [size(spikeCenterTrace,1) 1])', spikeCenterTrace','Color',[4 4 4]/8)
    hold on;
    plot(peakROI, avgSpikeTrace,'k', 'LineWidth',3);box off;
    % add in zero line
    xval = 0;
    x=[xval,xval];
    y=[minValTraces maxValTraces];
    plot(x,y,'r'); box off;

    hold off;
    title(['signal transients ' cellIDStr])
    xlabel('frames');ylabel('df/f');
    ylim([minValTraces maxValTraces]);

function plotSignal(thisTrace,testpeaks,cellIDStr,instructionStr,minValTraces,maxValTraces)
    % plots a signal along with test peaks
    plot(thisTrace, 'r');
    hold on;
    scatter(testpeaks, thisTrace(testpeaks), 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0])
    title(['signal ' cellIDStr instructionStr])
    xlabel('frames');ylabel('df/f');
    axis([0 length(thisTrace) minValTraces maxValTraces]);
    box off;
    hold off;

function [valid directionOfNextChoice saveData i] = respondToUserInput(reply,i,valid,directionOfNextChoice,saveData,nFilters)
    % decide what to do based on input (not a switch due to multiple comparisons)
    if isequal(reply, 3)|isequal(reply, 110)|isequal(reply, 31)
        % n key or right click
        directionOfNextChoice=1;
        % display('invalid IC');
        % set(mainFig,'Color',[0.8 0 0]);
        valid(i) = 0;
    elseif isequal(reply, 28)
        % go back, left
        directionOfNextChoice=-1;
    elseif isequal(reply, 29)
        % go forward, right
        directionOfNextChoice=1;
    elseif isequal(reply, 102)
        % user clicked 'f' for finished, exit loop
        saveData=1;
        % i=nFilters+1;
    elseif isequal(reply, 103)
        % if user clicks 'g' for goto, ask for which IC they want to see
        icChange = inputdlg('enter signal #');
        if ~isempty(icChange)
            icChange = str2num(icChange{1});
            if icChange>nFilters|icChange<1
                % do nothing, invalid command
            else
                i = icChange;
                directionOfNextChoice = 0;
            end
        end
    elseif isequal(reply, 115)
        % 's' if user wants to get ride of the rest of the ICs
        display(['classifying the following signals as bad: ' num2str(i) ':' num2str(nFilters)])
        valid(i:nFilters) = 0;
        saveData=1;
    elseif isequal(reply, 121)|isequal(reply, 1)|isequal(reply, 30)
        % y key or left click
        directionOfNextChoice=1;
        % display('valid IC');
        % set(mainFig,'Color',[0 0.8 0]);
        valid(i) = 1;
    else
        % forward=1;
        % valid(i) = 1;
    end