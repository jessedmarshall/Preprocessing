function obj = viewPlotSignificantPairwise(obj)
	% DESCRIPTION
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


	obj.detailStats = [];
	obj.detailStats.frame = [];
    obj.detailStats.value = [];
    obj.detailStats.stimulusMI = {};
    obj.detailStats.stimulusAlign = {};
    obj.detailStats.subject = {};
    obj.detailStats.assay = {};
    obj.detailStats.assayType = {};
    obj.detailStats.assayNum = {};
	obj.detailStats

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(length(fileIdxArray)) ': ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			%
			options.dfofAnalysis = obj.dfofAnalysis;
			[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
			nIDs = length(obj.stimulusNameArray);
			nSignals = size(IcaTraces,1);
			if isempty(IcaFilters);continue;end;
			signalPeaksTwo = signalPeaks;
			%
			nameArray = obj.stimulusNameArray;
			saveNameArray = obj.stimulusSaveNameArray;
			idArray = obj.stimulusIdArray;
			nIDs = length(obj.stimulusNameArray);
			%
			timeSeq = obj.timeSequence;
			subject = obj.subjectNum{obj.fileNum};
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
			%
			sigModSignalsAll = obj.sigModSignalsAll{obj.fileNum};
			% stimVectorAll = {obj.stimulusVectorArray{obj.fileNum,:}};
			% =====================

			figNames{figNoAll} = 'miStimTriggered_allPairwise_';
		 	[figNo{figNoAll}, ~] = openFigure(obj.figNoAll, '');
		 		clf
		     	[p,q] = meshgrid(idNumIdxArray, idNumIdxArray);
		     	idPairs = [p(:) q(:)];
		     	% idPairs = unique(sort(idPairs,2),'rows');
		     	% idPairs((idPairs(:,1)==idPairs(:,2)),:) = []
				nIDs = length(idNumIdxArray);
				% colorArray = hsv(nIDs);
				nPairs = size(idPairs,1);
				% ===
				nColors = size(obj.colormap,1);
				colorIdx1 = round(quantile(1:nColors,0.33));
				colorIdx2 = round(quantile(1:nColors,0.66));
				colorIdx3 = round(quantile(1:nColors,1));
				nameColor3 = ['{\color[rgb]{',num2str(obj.colormap(colorIdx3,:)),'}overlap}'];
				% ===
				ycounter = 1;
				xcounter = 1;
				for idPairNum = 1:nPairs
					idNum1 = idPairs(idPairNum,1);
					idNum2 = idPairs(idPairNum,2);
					if size(sigModSignalsAll,2)<idNum1|size(sigModSignalsAll,2)<idNum2
						continue;
					else
						sigModSignalsAllPair = sigModSignalsAll(:,[idNum1 idNum2]);
					end
					% obtain stimulus information
					stimVector = obj.modelGetStim(idArray(idNum2));
					if isempty(stimVector); continue; end;
					% stimVector = stimVectorAll{idNum2};
					% signals sorted by response to stimulus
					nStims = sum(stimVector);
					if nStims<1
						continue
					end
					% get signals to use for alignment from second stim
					signalFilterIdx = sigModSignalsAll(:,[idNum1]);
					if idNum1~=idNum2
						% remove signals that overlap for the two stimuli
						% overlapExcludeIdx = ~logical(sum(sigModSignalsAll(:,[idNum1 idNum2]),2)==2);
						% only look at overlap
						% overlapExcludeIdx = logical(sum(sigModSignalsAll(:,[idNum1 idNum2]),2)==2);
						% signalFilterIdx = signalFilterIdx.*overlapExcludeIdx;
					else
						% overlapExcludeIdx = logical(sum(sigModSignalsAll(:,[idNum1 idNum2]),2)==2);
						% signalFilterIdx = signalFilterIdx.*overlapExcludeIdx;
					end
					% sum(signalFilterIdx)
					if(sum(signalFilterIdx)~=0)
						% only look at responsive signals
						signalPeaksTwoFiltered = signalPeaksTwo(find(signalFilterIdx),:);
						% get the response for each signal aligned to stimulus
						alignResponseAllSignals = alignSignal(signalPeaksTwoFiltered,stimVector,timeSeq);
						% sort by cells most responsive right after stimuli
						% alignResponseAllSignals
						alignResponseAllSignalsSum = sum(alignResponseAllSignals((round(end/2):(round(end/2)+10)),:),1);
						[responseN reponseScoreIdx] = sort(alignResponseAllSignalsSum,'descend');
						signalPeaksTwoSorted = signalPeaksTwoFiltered(reponseScoreIdx,:);
						alignSignalAllSorted = alignResponseAllSignals(:,reponseScoreIdx)';
						[xPlot yPlot] = getSubplotDimensions(nPairs);
						subplot(xPlot,yPlot,idPairNum)
							alignSignalAllSortedImg = alignSignalAllSorted/nStims;
							if options.dfofAnalysis==1
							else
								% alignSignalAllSortedImg(1,1) = 1;
							end
							imagesc(alignSignalAllSortedImg);
							box off;
							% make axis normal
							set(gca,'YDir','normal');
							% axis off;
							set(gca,'xtick',[],'xticklabel',[]);
							if ycounter==1
								% ylabel('signals')
								ylabel([strrep(nameArray{idNum1},'__',' '),' MI'])
							else
								% y=ylim;
								% ylim([0 y(1)]);
							end
							colormap(obj.colormap);
							if options.dfofAnalysis==1
								cb = colorbar('location','southoutside');
								xlabel(cb, '\DeltaF/F/stimulus');
							else
								% xlabel(cb, 'spikes/stimulus');
							end
							if xcounter==1&ycounter==1
								% title([strrep(nameArray{idNum1},'__',' '),' MI signals',10,strrep(nameArray{idNum2},'__',' '),' aligned stimulus'])
								title([strrep(nameArray{idNum2},'__',' '),' aligned'])
							end
							hold on;
							numXTicks = 7;
							L = get(gca,'XLim');
							set(gca,'XTick',round(linspace(L(1),L(2),numXTicks)))
							set(gca,'XTickLabel',round(linspace(min(timeSeq),max(timeSeq),numXTicks)))
							if xcounter==nIDs
								xlabel('frames');
							end
							alignSignalAllSortedMean = sum(alignSignalAllSorted/nStims,1);
							alignLineHeight = round(size(alignSignalAllSorted,1)/2);
							% =====================
							numPtsToAdd = length(alignSignalAllSortedMean);
							metricLength = 1:length(alignSignalAllSortedMean);
							obj.detailStats.frame(end+1:end+numPtsToAdd,1) = metricLength(:);
							obj.detailStats.value(end+1:end+numPtsToAdd,1) = alignSignalAllSortedMean(:);
							obj.detailStats.stimulusMI(end+1:end+numPtsToAdd,1) = {nameArray{idNum1}};
							obj.detailStats.stimulusAlign(end+1:end+numPtsToAdd,1) = {nameArray{idNum2}};
							obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subject};
							obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
							obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
							obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
							% =====================
							if ycounter==1
								thisYMax = max(alignSignalAllSortedMean);
								alignSignalAllSortedMeanNorm = normalizeVector(alignSignalAllSortedMean,'normRange','zeroToOne')*alignLineHeight;
								% alignSignalAllSortedMeanNorm
							else
								% thisYMax
								alignSignalAllSortedMean(end+1) = thisYMax;
								alignSignalAllSortedMeanNorm = normalizeVector(alignSignalAllSortedMean,'normRange','zeroToOne')*alignLineHeight;
								% alignSignalAllSortedMeanNorm
								alignSignalAllSortedMeanNorm = alignSignalAllSortedMeanNorm(1:end-1);
							end
							plot(alignSignalAllSortedMeanNorm,'LineWidth',3,'Color','k');
							hold off;


							% write out summary statistics
						    % savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_pairwisePlot.tab'];
						    % display(['saving data to: ' savePath])
							% writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
					end
					if ycounter==nIDs
						ycounter = 1;
						xcounter = xcounter + 1;
					else
						ycounter = ycounter+1;
					end
		        end
		   %      subplot(xPlot,yPlot,nPairs)
		   %      	imagesc([0:3]);
		   %      	cb = colorbar('location','southoutside');
					% xlabel(cb, 'MI stimuli number');
				suptitle([subjAssayIDStr 10 ' | stimulus modulated signal comparison, excluding ',nameColor3,''])

			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 length(idNumIdxArray)*5 length(idNumIdxArray)*5])
			obj.modelSaveImgToFile([],'sigStimTrigAllStimPairwise_','current',[]);
				% close(figNoAll);
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end


	% write out summary statistics
    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_pairwisePlot.tab'];
    display(['saving data to: ' savePath])
	writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
end


% function obj = incrementSummaryStats(obj)
%     % add identifier information
%     obj.sumStats.subject{end+1,1} = obj.subjectStr{obj.fileNum};
%     obj.sumStats.assay{end+1,1} = obj.assay{obj.fileNum};
%     obj.sumStats.assayType{end+1,1} = obj.assayType{obj.fileNum};
%     obj.sumStats.assayNum{end+1,1} = obj.assayNum{obj.fileNum};
%     obj.sumStats.stimulus{end+1,1} = obj.stimulusNameArray{obj.stimNum};
%     obj.sumStats.pctMI2sigma{end+1,1} = NaN;
%     obj.sumStats.pctTtest{end+1,1} = NaN;
%     % add summary stats
%     obj.sumStats.zscore{end+1,1} = NaN;
%     obj.sumStats.zscoresPost{end+1,1} = NaN;
%     obj.sumStats.zscoresPre{end+1,1} = NaN;
%     obj.sumStats.signalFiringModulation{end+1,1} = NaN;
%     obj.sumStats.signalFiringModulationShuffle{end+1,1} = NaN;
%     obj.sumStats.stimulusOverlay{end+1,1} = NaN;
%     obj.sumStats.overlapMI{end+1,1} = NaN;
%     obj.sumStats.overlapTtest{end+1,1} = NaN;
%     zScoreString = {'All','Ttest','NotTtest','MI'};
%     for alignIdxToUse=1:length(obj.alignedSignalArray{obj.fileNum,obj.stimNum})
%         eval(['obj.sumStats.zscore' zScoreString{alignIdxToUse} '{end+1,1} = NaN;']);
%     end
% end