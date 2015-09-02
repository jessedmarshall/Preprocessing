function obj = viewSignalStats(obj)
	% plot various stats about signals (number of peaks, simultaneous firing, etc.)
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

    % ============================
    % reset summary stats
    obj.sumStats = {};
    obj.sumStats.subject{1,1} = nan;
    obj.sumStats.assay{1,1} = nan;
    obj.sumStats.assayType{1,1} = nan;
    obj.sumStats.assayNum{1,1} = nan;
    obj.sumStats.firingRateMean{1,1} = nan;
    obj.sumStats.firingRateMedian{1,1} = nan;
    obj.sumStats.firingRateStd{1,1} = nan;
    obj.sumStats.transientSizeMean{1,1} = nan;
    obj.sumStats.transientSizeMedian{1,1} = nan;
    obj.sumStats.meanSpikesCell{1,1} = nan;
    obj.sumStats.syncActivityMean{1,1} = nan;
    obj.sumStats.syncActivityMax{1,1} = nan;
    obj.sumStats.syncActivityMeanNorm{1,1} = nan;
    obj.sumStats.syncActivityMaxNorm{1,1} = nan;
    obj.sumStats.fwhmMean{1,1} = nan;
    obj.sumStats.numObjs{1,1} = nan;
    obj.sumStats.nSpikeCorrClusters{1,1} = nan;
    % additional stats
    % fano factor
    % skew
    % excess kurtosis

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
        try
    		thisFileNum = fileIdxArray(thisFileNumIdx);
    		obj.fileNum = thisFileNum;
    		fileNum = obj.fileNum;
    		display(repmat('=',1,21))
    		display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
    		% =====================
    		% for backwards compatibility, will be removed in the future.
            showObjMaps = 0;
            switch showObjMaps
                case 1
                    [IcaTraces IcaFilters signalPeaks signalPeakIdx] = modelGetSignalsImages(obj);
                case 0
                    [IcaTraces IcaFilters signalPeaks signalPeakIdx] =     modelGetSignalsImages(obj,'returnType','filtered_traces');
                otherwise
                    body
            end
            nIDs = length(obj.stimulusNameArray);
            nSignals = size(IcaTraces,1);
    		% IcaTraces = obj.rawSignals{obj.fileNum};
    		% IcaFilters = obj.rawImages{obj.fileNum};
    		% nIDs = length(obj.stimulusNameArray);
            % nSignals = obj.nSignals{obj.fileNum};
    		% signalPeaks = obj.signalPeaks{obj.fileNum};
    		% signalPeakIdx = obj.signalPeaksArray{obj.fileNum};
            %
            nameArray = obj.stimulusNameArray;
            idArray = obj.stimulusIdArray;
            %
    		%
    		options.dfofAnalysis = obj.dfofAnalysis;
    		timeSeq = obj.timeSequence;
    		subject = obj.subjectStr{obj.fileNum};
    		assay = obj.assay{obj.fileNum};
    		assayType = obj.assayType{obj.fileNum};
    		assayNum = obj.assayNum{obj.fileNum};
    		%
    		framesPerSecond = obj.FRAMES_PER_SECOND;
    		subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
    		%
    		figNoAll = obj.figNoAll;
    		figNo = obj.figNo;
    		figNames = obj.figNames;
    		% magic numbers!
    		% amount of time to make object maps before/after a stimulus
    		prepostTime = 20;
    		%
    		picsSavePath = [obj.picsSavePath filesep 'cellmaps' filesep];
    		fileFilterRegexp = obj.fileFilterRegexp;
        	% thisFileID = obj.fileIDNameArray{obj.fileNum};
        	thisFileID = obj.fileIDArray{obj.fileNum};
    		% ====================================================================================
        	[peakOutputStat] = computePeakStatistics(IcaTraces,'testpeaks',signalPeaks,'testpeaksArray',signalPeakIdx);
        	[signalSnr a] = computeSignalSnr(IcaTraces,'testpeaks',signalPeaks,'testpeaksArray',signalPeakIdx);
        	% =====================
        	% make separate function
        	% [signalPeaks, signalPeakIdx] = computeSignalPeaks(IcaTraces, 'makePlots', 0,'makeSummaryPlots',1);
        	[r p] = corrcoef(signalPeaks(1:end,:)');
        	corrLinkage = linkage(r,'average','euclidean');
        	% corrLinkage
        	% dendrogram(corrLinkage);
        	% pause
        	maxNumClusters = 10;
        	% spikeCorrClusters = cluster(corrLinkage,'maxclust',maxNumClusters);
        	spikeCorrClusters = cluster(corrLinkage,'cutoff',1.445,'criterion','distance');
        	nSpikeCorrClusters = length(unique(spikeCorrClusters));
        	[Y,idx] = sort(spikeCorrClusters,1,'ascend');
        	correlationMatrixSorted = r(idx,idx);
        	correlationMatrixSorted(correlationMatrixSorted==1) = NaN;
            if showObjMaps==1
            	[objmapSpikeCorrClusters] = groupImagesByColor(IcaFilters,spikeCorrClusters);
            	objmapSpikeCorrClusters = createObjMap(objmapSpikeCorrClusters);
            	objmapSpikeCorrClusters(1,1) = maxNumClusters;
            end
        	% imagesc(tmpR);colorbar
        	% =====================
        	% signalSpikesSum = sum(signalPeaks,1);
        	% tmp.signalPeaks{fileNum} = signalPeaks;
        	% tmp.signalMatrix{fileNum} = IcaTraces;
        	% tmp.fwhmSignal{fileNum} = peakOutputStat.fwhmSignal;
        	% tmp.signalSnr{fileNum} = signalSnr;
        	% =====================
        	% smooth signal by a frame for simultaneous firing
        	% class(signalPeaks)
        	signalSpikesSpread = spreadSignal(signalPeaks,'timeSeq',[-2:2]);
        	display('shuffling signal matrix');
        	signalSpikesSpreadShuffled = spreadSignal(shuffleMatrix(signalPeaks),'timeSeq',[-2:2]);
        	% =====================
        	% firing rate grouped images
        	numPeakEvents = sum(signalPeaks,2);
        	numPeakEvents = numPeakEvents/size(signalPeaks,2)*framesPerSecond;
            if showObjMaps==1
            	[objmapNumPeakEvents] = groupImagesByColor(IcaFilters,numPeakEvents);
            	objmapNumPeakEvents = createObjMap(objmapNumPeakEvents);
            	% to normalize across animals
            	objmapNumPeakEvents(1,1) = 0.035;
            end
        	% =====================
        	% save summmary statistics
        	obj.sumStats.subject{end+1,1} = subject;
        	obj.sumStats.assay{end+1,1} = assay;
        	obj.sumStats.assayType{end+1,1} = assayType;
        	obj.sumStats.assayNum{end+1,1} = assayNum;
        	obj.sumStats.firingRateMean{end+1,1} = nanmean(sum(signalPeaks,2)/size(signalPeaks,2)*framesPerSecond);
        	obj.sumStats.firingRateMedian{end+1,1} = median(sum(signalPeaks,2)/size(signalPeaks,2)*framesPerSecond);
        	obj.sumStats.firingRateStd{end+1,1} = nanstd(sum(signalPeaks,2)/size(signalPeaks,2)*framesPerSecond);
            tmpIcaTraces = IcaTraces(logical(signalPeaks));
            obj.sumStats.transientSizeMean{end+1,1} = nanmean(tmpIcaTraces(:));
            obj.sumStats.transientSizeMedian{end+1,1} = median(tmpIcaTraces(:));
            clear tmpIcaTraces
        	obj.sumStats.meanSpikesCell{end+1,1} = nanmean(sum(signalPeaks,2));
        	obj.sumStats.syncActivityMean{end+1,1} = nanmean(sum(signalSpikesSpread,1));
        	obj.sumStats.syncActivityMax{end+1,1} = nanmax(sum(signalSpikesSpread,1));
            obj.sumStats.syncActivityMeanNorm{end+1,1} = nanmean(sum(signalSpikesSpread,1)/nSignals);
            obj.sumStats.syncActivityMaxNorm{end+1,1} = nanmax(sum(signalSpikesSpread,1)/nSignals);
        	obj.sumStats.fwhmMean{end+1,1} = nanmean(peakOutputStat.fwhmSignal);
        	obj.sumStats.numObjs{end+1,1} = nSignals;
        	obj.sumStats.nSpikeCorrClusters{end+1,1} = nSpikeCorrClusters;


        	% ostruct.summaryStats
        	% movTable = struct2table(ostruct.summaryStats);
        	% writetable(movTable,char(['private\data\' ostruct.info.protocol{fileNum} '_summary_peaks.tab']),'FileType','text','Delimiter','\t');
        	% =====================
        	% save big data statistics
        	if thisFileNumIdx==1
        	    obj.detailStats.frame = [];
        	    obj.detailStats.value = [];
        	    obj.detailStats.varType = {};
                obj.detailStats.varType2 = {};
        	    obj.detailStats.subject = {};
        	    obj.detailStats.assay = {};
        	    obj.detailStats.assayType = {};
        	    obj.detailStats.assayNum = {};
        	end
        	maxH = max(sum(signalSpikesSpread,1));
        	histBins = [0:maxH];
        	histCountsShuffle = hist(sum(signalSpikesSpreadShuffled,1),histBins);
        	histCountsShuffleNorm = histCountsShuffle/sum(histCountsShuffle);

        	histCounts = hist(sum(signalSpikesSpread,1),histBins);
            % histCounts = histCounts-histCountsShuffle;
        	histHNorm = histCounts/sum(histCounts);

        	% tmpSubjInfo = [ostruct.info.subject{fileNum} ostruct.info.assayType{fileNum} ostruct.info.assayNum{fileNum}];
        	frame = histBins;
        	value = histHNorm;
            valueArray = {histHNorm,histCountsShuffleNorm};
        	varType = 'simultaneousfiringEventsDist';
            varType2Array = {'data','shuffled'};
            for varNum = 1:2
            	numPtsToAdd = length(frame(:));
            	obj.detailStats.frame(end+1:end+numPtsToAdd,1) = frame(:);
            	% obj.detailStats.value(end+1:end+numPtsToAdd,1) = value(:);
                obj.detailStats.value(end+1:end+numPtsToAdd,1) = valueArray{varNum}(:);
            	obj.detailStats.varType(end+1:end+numPtsToAdd,1) = {varType};
                obj.detailStats.varType2(end+1:end+numPtsToAdd,1) = {varType2Array{varNum}};
            	obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subject};
            	obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
            	obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
            	obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
            end

            % obj.detailStats

            continue
            % ***************************************************************
            % ***************************************************************
            % ***************************************************************
        	% =====================
        	% look at the pairwise correlation between the neurons
        	% z=xcorr(signalPeaks');
        	% z0 = zeros(size(signalPeaks',2));
        	% zMax = max(z);
        	% z0 = reshape(zMax, [size(z0)]);
        	% figure(9000)
        	% 	imagesc(z0); colormap jet;

        	% z=xcorr(IcaTraces');
        	% z0 = zeros(size(IcaTraces',2));
        	% zMax = max(z);
        	% z0 = reshape(zMax, [size(z0)]);
        	% figure(90001)
        	% 	imagesc(z0); colormap jet;
        	% =====================
        	if sum(strcmp('subjectType',fieldnames(ostruct.data)))>0
        		colorIdx = strcmp(ostruct.data.subjectType(fileNum,1),ostruct.lists.subjectType);
        		subjColor = ostruct.lists.typeColors(colorIdx,:);
        		subjectTypeList = ostruct.lists.subjectType;
        		typeColorsList = ostruct.lists.typeColors;
        	else
        		ostruct.lists.assayType = unique(ostruct.subjInfo.subjectType);
        		subjectTypeList = ostruct.lists.assayType;
        		ostruct.lists.typeColors = hsv(length(ostruct.lists.assayType));
        		typeColorsList = ostruct.lists.typeColors;
        		colorIdx = strcmp(ostruct.subjInfo.subjectType{fileNum},ostruct.lists.assayType);
        		subjColor = ostruct.lists.typeColors(colorIdx,:);
        		% subjectTypeList = {ostruct.subject{fileNum}};
        		% typeColorsList = hsv(1);
        	end
        	% subjColor

        	figNo = 139;
        	if ostruct.counter==1|~any(strcmp('plots',fieldnames(ostruct)))
        		ostruct.plots.figCount = 0;
        		ostruct.plots.plotCount = 1;
        		ostruct.plots.sheight = 3;
        		ostruct.plots.swidth = 3;
        	end
            if showObjMaps==1
            	[figHandle2 figNo2] = openFigure(91000+ostruct.plots.figCount, '');
            		subplot(ostruct.plots.sheight,ostruct.plots.swidth,ostruct.plots.plotCount);
            		imagesc(objmapNumPeakEvents); axis off; box off;
            		colormap(ostruct.colormap);
            		if ostruct.plots.plotCount==1
            			cb = colorbar;
            		end
            		% cb = colorbar('location','southoutside');
            		% if ostruct.plots.plotCount==1
            			% colorbar
            		% end
            		title(thisID);
            		hold on;
            		suptitle('object maps: firing rate');
            		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_cellmaps',num2str(ostruct.plots.figCount),'.png'),'/',''));
            		saveas(gcf,saveFile);
            end

            if showObjMaps==1
            	[figHandle2 figNo2] = openFigure(92000+ostruct.plots.figCount, '');
            		subplot(ostruct.plots.sheight,ostruct.plots.swidth,ostruct.plots.plotCount);
            		imagesc(objmapSpikeCorrClusters); axis off; box off;
            		colormap(ostruct.colormap);
            		if ostruct.plots.plotCount==1
            			cb = colorbar;
            		end
            		title(thisID);
            		hold on;
            		suptitle('object maps: spike correlation clusters');
            		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_cluster_cellmaps',num2str(ostruct.plots.figCount),'.png'),'/',''));
            		saveas(gcf,saveFile);
            end

        	[figHandle2 figNo2] = openFigure(93000+ostruct.plots.figCount, '');
        		subplot(ostruct.plots.sheight,ostruct.plots.swidth,ostruct.plots.plotCount);
        		imagesc(correlationMatrixSorted);
        		axis off; box off;
        		colormap(ostruct.colormap);
        		if ostruct.plots.plotCount==1
        			cb = colorbar;
        		end
        		title(thisID);
        		hold on;
        		suptitle('spike correlation clusters');
        		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_correlations',num2str(ostruct.plots.figCount),'.png'),'/',''));
        		saveas(gcf,saveFile);

        	[figHandle figNo] = openFigure(figNo, '');
        		for i = 1:2
        			subplot(2,1,i);
        			if i==1
        				[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
        			end
        			% signalStd = std(sum(signalPeaks,2));
        			% signalMean = mean(sum(signalPeaks,2));
        			if i==1
        				histBins = 30;
        				allSignalsHz = sum(signalPeaks,2)/size(signalPeaks,2)*framesPerSecond;
        				[histCounts histBins] = hist(allSignalsHz,histBins);
        				histCounts = histCounts/sum(histCounts);
        				phandle = plot(histBins, histCounts, 'Color',subjColor);box off;
        				title(['firing rate distribution']);
        				xlabel('firing rate (spikes/second)');ylabel('count');
        			else
        				histBins = [0:5:100];
        				histCounts = hist(sum(signalPeaks,2),histBins);
        				phandle = plot(histBins, histCounts, 'Color',subjColor);box off;
        				title(['distribution total peaks']);
        				xlabel('total spikes per cell');ylabel('count');
        			end
        			% title(['distribution total peaks, individual signals: std=' num2str(signalStd) ', mean=' num2str(signalMean)]);
        			hold on;
        		end
        		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_firingRate.png'),'/',''));
        		saveas(gcf,saveFile);

        	[figHandle figNo] = openFigure(figNo, '');
        		% subplot(5,ceil(nFiles/5),fileNum);
        		for i = 1:4
        			subplot(2,2,i);
        			if i==1
        				[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
        			end
        			maxFWHM = max(ostruct.fwhmSignal{fileNum});
        			histFWHM = hist(ostruct.fwhmSignal{fileNum},[0:nanmax(ostruct.fwhmSignal{fileNum})]); box off;
        			if i==3|i==4
        				histFWHM = histFWHM/sum(histFWHM);
        			end
        			phandle = plot([0:nanmax(ostruct.fwhmSignal{fileNum})], histFWHM, 'Color',subjColor);box off;
        			xlabel('fwhm (frames)'); ylabel('count');
        			if i==2|i==4
        				set(gca,'YScale','log');
        			end
        			hold on;
        			title('spike full-width half-maximums')
        		end
        		% suptitle('full-width half-maximum for detected spikes'); hold on;
        		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_fwhm.png'),'/',''));
        		saveas(gcf,saveFile);

        	[figHandle figNo] = openFigure(figNo, '');
        		[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
        		phandle = plot(ostruct.signalSnr{fileNum}, 'Color',subjColor);box off;
        		% phandle = plot([0:nanmax(ostruct.fwhmSignal{fileNum})], histFWHM, 'Color',subjColor);box off;
        		xlabel('rank'); ylabel('SNR');
        		hold on;
        		title('signal SNR')
        		% suptitle('full-width half-maximum for detected spikes'); hold on;
        		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_SNR.png'),'/',''));
        		saveas(gcf,saveFile);

        	maxH = max(sum(signalSpikesSpread,1));
        	histBins = [0:maxH];

        	histCountsShuffle = hist(sum(signalSpikesSpreadShuffled,1),histBins);
        	histCountsShuffleNorm = histCountsShuffle/sum(histCountsShuffle);

        	histCounts = hist(sum(signalSpikesSpread,1),histBins)-histCountsShuffle;
        	histHNorm = histCounts/sum(histCounts(histCounts>0));
        	[figHandle figNo] = openFigure(figNo, '');
        		for i = 1:2
        			subplot(1,2,i);
        			if i==1
        				[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
        			end
        			phandle = plot(histBins, histCounts, 'Color',subjColor);box off;
        			% plot shuffle
        			% plot(histBins, histCountsShuffle, 'Color',subjColor,'LineStyle','--');box off;
        			title('simultaneous firing events (counts), dashed = randomly shift spike trains');
        			xlabel('simultaneous spikes');ylabel('count');
        			if i==2
        				set(gca,'YScale','log');
        			end
        			hold on;
        		end
        		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_simSpikesUnorm.png'),'/',''));
        		saveas(gcf,saveFile);
        		% suptitle('simultaneous firing events (counts), dashed = randomly shift spike trains'); hold on;
        	[figHandle figNo] = openFigure(figNo, '');
        		for i = 1:2
        			subplot(1,2,i);
        			if i==1
        				[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
        			end
        			phandle = plot(histBins, histHNorm, 'Color',subjColor);box off;
        			% plot shuffle
        			% plot(histBins, histCountsShuffleNorm, 'Color',subjColor,'LineStyle','--');box off;
        			title('simultaneous firing events (normalized), dashed = randomly shift spike trains');
        			xlabel('simultaneous spikes');ylabel('%');
        			if i==2
        				set(gca,'YScale','log');
        			end
        			hold on;
        		end
        		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_simSpikesNorm.png'),'/',''));
        		saveas(gcf,saveFile);
        		% suptitle('simultaneous firing events (normalized), dashed = randomly shift spike trains'); hold on;
        		% if fileNum==nFiles
        			% saveFile = char(strrep(strcat(options.picsSavePath,'all_cumMovement_.png'),'/',''));
        			% saveas(gcf,saveFile);
        		% end
        		% signalSpikesMore

        	if mod(ostruct.plots.plotCount,ostruct.plots.sheight*ostruct.plots.swidth)==0
        	   ostruct.plots.figCount = ostruct.plots.figCount+1;
        	   ostruct.plots.plotCount = 1;
        	else
        	   ostruct.plots.plotCount = ostruct.plots.plotCount+1;
        	end

        	[figHandle figNo] = openFigure(figNo, '');
        	if fileNum==nFiles
        		ostruct.signalMean = cell2mat(arrayfun(@(x) mean(sum(x{1},2)), ostruct.signalPeaks, 'UniformOutput', false));
        		ostruct.signalStd = cell2mat(arrayfun(@(x) std(sum(x{1},2)), ostruct.signalPeaks, 'UniformOutput', false));
        			plot(ostruct.signalMean); hold on; box off;
        			plot(ostruct.signalStd,'r');
        			title('spikes per cell over entire trial');
        			xlabel('trialNum');ylabel('mean/std of trial spikes');
        			legend({'mean', 'std'});
        			drawnow
        	end
        catch err
            display(repmat('@',1,7))
            disp(getReport(err,'extended','hyperlinks','on'));
            display(repmat('@',1,7))
        end
    end

    % write out summary statistics
    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_signalSummaryStats.tab'];
    display(['saving data to: ' savePath])
    writetable(struct2table(obj.sumStats),savePath,'FileType','text','Delimiter','\t');

    % write out summary statistics
    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_signalDetailedStats.tab'];
    display(['saving data to: ' savePath])
    writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');

    obj.sumStats = [];
    obj.detailStats = [];

end