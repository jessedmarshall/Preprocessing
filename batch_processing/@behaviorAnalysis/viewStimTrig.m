function obj = viewStimTrig(obj)
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

	obj.sumStats = {};
	obj.sumStats.subject{1,1} = nan;
	obj.sumStats.assay{1,1} = nan;
	obj.sumStats.assayType{1,1} = nan;
	obj.sumStats.assayNum{1,1} = nan;
	obj.sumStats.stimulus{1,1} = nan;
	obj.sumStats.varType{1,1} = nan;
	obj.sumStats.percentTrialsActiveMean{1,1} = nan;
	obj.sumStats.percentTrialsActiveMedian{1,1} = nan;
	obj.sumStats.meanEventRatePerSignal{1,1} = nan;

	obj.detailStats.frame = [];
	obj.detailStats.value = [];
	obj.detailStats.varType = {};
	obj.detailStats.subject = {};
	obj.detailStats.assay = {};
	obj.detailStats.assayType = {};
	obj.detailStats.assayNum = {};
	obj.detailStats.stimulus = {};

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			%
			[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
			nIDs = length(obj.stimulusNameArray);
			nSignals = size(IcaTraces,1);
			if isempty(IcaFilters);continue;end;
			%
			thisSignal = signalPeaks;
			%
			nameArray = obj.stimulusNameArray;
			saveNameArray = obj.stimulusSaveNameArray;
			idArray = obj.stimulusIdArray;
			assayTable = obj.discreteStimulusTable;
			%
			% signalPeaks = obj.signalPeaks{obj.fileNum};
			%
			usTimeAfterCS = 10;
			options.dfofAnalysis = obj.dfofAnalysis;
			options.stimTriggerOnset = obj.stimTriggerOnset;
			options.picsSavePath = obj.picsSavePath;
			timeSeq = obj.timeSequence;
			subject = obj.subjectStr{obj.fileNum};
			assay = obj.assay{obj.fileNum};
			assayType = obj.assayType{obj.fileNum};
			assayNum = obj.assayNum{obj.fileNum};
			%
			framesPerSecond = obj.FRAMES_PER_SECOND;
			subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
			subjAssayIDStr
			%
			figNoAll = obj.figNoAll;
			figNo = obj.figNo;
			figNames = obj.figNames;
			thisFileID = obj.fileIDArray{obj.fileNum};
			% =====================
			idNumCounter = 1;
			nIDs = length(idNumIdxArray);
			for idNumIdx = 1:length(idNumIdxArray)
				idNum = idNumIdxArray(idNumIdx);
				obj.stimNum = idNum;
				% for idNum = 1:nIDs
				% 	obj.stimNum = idNum;
					% ============================
				if ~isempty(obj.alignedSignalArray)&~isempty(obj.alignedSignalArray{obj.fileNum,idNum})
					% continue;

					alignedSignal = obj.alignedSignalArray{obj.fileNum,idNum}{1};
					alignedSignalShuffledMean = obj.alignedSignalShuffledMeanArray{obj.fileNum,idNum}{1};
					alignedSignalShuffledStd = obj.alignedSignalShuffledStdArray{obj.fileNum,idNum}{1};
					% ============================
					figNames{figNoAll} = 'stimTriggeredAvg_signal_';
			 		[figNo{figNoAll}, ~] = openFigure(figNoAll, '');
			 		% plot(nansum(signalPeaks,1))
			 		% zoom on
			 		% pause

			        % if idNumCounter==1
					% 	suptitle([subjAssayIDStr ' '  ' | triggered firing rate over entire trial, frames/sec = ' num2str(framesPerSecond),10,10])
					% end
					[xPlot yPlot] = getSubplotDimensions(nIDs+1);
			        	subplot(xPlot,yPlot,idNum)
			            a = gca(figNo{1}); % get the axes from the figure
			            cla(a); % clear the axes
						viewLineFilledError(alignedSignalShuffledMean,alignedSignalShuffledStd,'xValues',timeSeq);
						hold on;
						% viewLineFilledError(alignedSignalStimShuffledMean,alignedSignalStimShuffledStd,'xValues',timeSeq);
						% hold on;
						plot(timeSeq, alignedSignal,'r');box off;
						% plot(timeSeq,alignedSignalShuffled/nStims,'k');
						% plot(timeSeq,alignedSignalStimShuffled/nStims,'b');
						title([nameArray{idNum}]);
						if idNum==nIDs
							xlabel('frames');
						end
						axisMax = max(alignedSignal)*1.1;
						axisMaxShuffle = max(alignedSignalShuffledMean+1.96*alignedSignalShuffledStd);
						if axisMaxShuffle>axisMax
							axisMax = axisMaxShuffle;
						end
						ylim([min(alignedSignal)-std(alignedSignal),axisMax]);
						if idNumCounter==1
							if options.dfofAnalysis==1
								ylabel('\DeltaF/F');
							else
								ylabel('spikes/stimulus');
							end
							% make legend
							[xPlot yPlot] = getSubplotDimensions(nIDs+1);
				            subplot(xPlot,yPlot,nIDs+1)
							viewLineFilledError([1 1],[1 1],'xValues',1:2);
							hold on;
							plot([1 2], [1 1],'r');box off;
							h_legend = legend('2\sigma(shuffle)','mean(shuffle)','actual','2\sigma(shuffle stim)','mean(shuffle stim)','Location','Best','Orientation','horizontal');
							h_legend = legend('2\sigma(shuffle)','mean(shuffle)','actual','2\sigma(shuffle stim)','mean(shuffle stim)','Location','Best','Orientation','vertical');
							% set(h_legend,'FontSize',10);
						end
						drawnow
				end
				% obj.modelSaveImgToFile([],'stimTrigTrials_',thisFigNo,strcat(thisFileID,'_',saveNameArray{idNum}));

				% =====================
				% show per trial per neuron activation for all stimuli

				% obtain stimulus information
				% display('---')
				stimVector = obj.modelGetStim(idArray(idNum));
				if isempty(stimVector); continue; end;

				[~, ~] = openFigure(78965, '');
					if idNumCounter==1
						clf
					end
					prepostTime = 10;
					% x = alignSignal(IcaTraces,stimVector,0:50,'returnFormat','count:[nSignals nAlignmemts]');
					alignedSignalPerTrialPost = alignSignal(thisSignal, stimVector,0:prepostTime,'returnFormat','count:[nSignals nAlignmemts]');
					alignedSignalPerTrialPre = alignSignal(thisSignal, stimVector,-prepostTime:0,'returnFormat','count:[nSignals nAlignmemts]');
					% alignedSignalPerTrialRatio = alignedSignalPerTrialPost./alignedSignalPerTrialPre;
					% alignedSignalPerTrialNorm = alignSignal(thisSignal, stimVector,0:prepostTime,'returnFormat','normcount:[nSignals nAlignmemts]');

					if idNumCounter==1
						stimVector2 = obj.modelGetStim(idArray(idNum+1));
						if isempty(stimVector2)
							[responseN reponseScoreIdx] = sort(sum(alignedSignalPerTrialPre,2),'descend');
						else
							stimTimeSeq = obj.stimulusTimeSeq{idNum};
							if nansum(stimTimeSeq(:))<0
								alignedSignalPerTrialPre2 = alignSignal(thisSignal, stimVector2,-prepostTime:0,'returnFormat','count:[nSignals nAlignmemts]');
								ratioScore = (sum(alignedSignalPerTrialPre,2)-sum(alignedSignalPerTrialPre2,2))./(sum(alignedSignalPerTrialPre,2)+sum(alignedSignalPerTrialPre2,2));
							else
								alignedSignalPerTrialPost2 = alignSignal(thisSignal, stimVector2,-prepostTime:0,'returnFormat','count:[nSignals nAlignmemts]');
								ratioScore = (sum(alignedSignalPerTrialPost,2)-sum(alignedSignalPerTrialPost2,2))./(sum(alignedSignalPerTrialPost,2)+sum(alignedSignalPerTrialPost2,2));
							end
							% ratioScore
							ratioScore(ratioScore==-1) = -3;
							ratioScore(ratioScore<0) = ratioScore(ratioScore<0)-2;
							ratioScore(isnan(ratioScore)) = -1;
							[responseN reponseScoreIdx] = sort(ratioScore,'descend');
						end
						% alignedSignalPerTrialPost = alignedSignalPerTrialPost(reponseScoreIdx,:);
						% [responseN reponseScoreIdx] = sort(sum(alignedSignalPerTrialNorm,2),'descend');
						% alignedSignalPerTrialNorm = alignedSignalPerTrialNorm(reponseScoreIdx,:);
					end
					try
						alignedSignalPerTrialPre = alignedSignalPerTrialPre(reponseScoreIdx,:);
						alignedSignalPerTrialPost = alignedSignalPerTrialPost(reponseScoreIdx,:);
					catch
						display('problem with response index')
						% continue
					end

					% for i=1:nAlignSignalsPlot
						subplot(1,nIDs,idNumIdx)
							imagesc(alignedSignalPerTrialPre)
							colormap(flipud(gray))
							% axis off
							% colormap(customColormap([]));
							% cb = colorbar('location','southoutside');
							% xlabel('trial');
							if idNumCounter==1
								ylabel(['pre-stimulus',10,'cell #']);
							end
							set(gca, 'XTick', []);set(gca, 'YTick', []);
							title(nameArray{idNum});
						% subplot(2,nIDs,nIDs+idNum)
						% 	imagesc(alignedSignalPerTrialPost)
						% 	colormap(flipud(gray))
						% 	set(gca, 'XTick', []);set(gca, 'YTick', []);
						% 	% axis off
						% 	% colormap(customColormap([]));
						% 	% cb = colorbar('location','southoutside');
						% 	xlabel('trial');
						% 	if idNumCounter==1
						% 		ylabel(['post-stimulus',10,'cell #']);
						% 	end
						% 	title(nameArray{idNum});
					% end
					% suptitle([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | per trial'])

				% varNameArray = {'preStimulus','postStimulus','winStimulus','onlyStimulus'};
				% % varDataArray = {percentTrialsActivePre,percentTrialsActivePost,percentTrialsActiveWindow};
				% prepostTime = 10;
				% stimTimeSeq = obj.stimulusTimeSeq{idNum};
				% varStimArray = {0:prepostTime,prepostTime:0,stimTimeSeq,0};
				% for varNum=1:length(varNameArray)
				% 	alignedSignalPerTrialTmp = alignSignal(thisSignal, stimVector,varStimArray{varNum},'returnFormat','count:[nSignals nAlignmemts]');
				% 	percentTrialsActiveTmp = sum(alignedSignalPerTrialTmp,2)/size(alignedSignalPerTrialTmp,2);
				% 	nStims = length(find(stimVector));
				% 	stimVectorSpread = spreadSignal(stimVector,'timeSeq',varStimArray{varNum});
				% 	meanEventRatePerSignal = (sum(thisSignal(:,find(stimVectorSpread)),1)/length(find(stimVectorSpread)))*framesPerSecond;
				% 	% SUMMARY
				% 	obj.sumStats.subject{end+1,1} = subject;
				% 	obj.sumStats.assay{end+1,1} = assay;
				% 	obj.sumStats.assayType{end+1,1} = assayType;
				% 	obj.sumStats.assayNum{end+1,1} = assayNum;
				% 	obj.sumStats.stimulus{end+1,1} = nameArray{idNum};
				% 	obj.sumStats.varType{end+1,1} = varNameArray{varNum};
				% 	obj.sumStats.percentTrialsActiveMean{end+1,1} = nanmean(percentTrialsActiveTmp);
				% 	obj.sumStats.percentTrialsActiveMedian{end+1,1} = nanmedian(percentTrialsActiveTmp);
				% 	obj.sumStats.meanEventRatePerSignal{end+1,1} = meanEventRatePerSignal;

				% 	% DETAILED
				% 	numPtsToAdd = length(percentTrialsActiveTmp);
				% 	signalNums = 1:length(percentTrialsActiveTmp(:));
				% 	obj.detailStats.frame(end+1:end+numPtsToAdd,1) = signalNums(:);
				% 	% obj.detailStats.value(end+1:end+numPtsToAdd,1) = value(:);
				%     obj.detailStats.value(end+1:end+numPtsToAdd,1) = percentTrialsActiveTmp(:);
				% 	obj.detailStats.varType(end+1:end+numPtsToAdd,1) = {varNameArray{varNum}};
				% 	obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subject};
				% 	obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
				% 	obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
				% 	obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
				% 	obj.detailStats.stimulus(end+1:end+numPtsToAdd,1) = {nameArray{idNum}};
				% end

				idNumCounter = idNumCounter + 1;
			end
			% [figNo{figNoAll}, ~] = openFigure(figNoAll, '');
			% 	suptitle([subjAssayIDStr ' '  ' | triggered firing rate over entire trial, frames/sec = ' num2str(framesPerSecond)])
			% 	obj.modelSaveImgToFile([],'stimTrigAvgSignal_','current',[]);
			[~, ~] = openFigure(78965, '');
				suptitle([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | per trial'])
				set(gcf,'PaperUnits','inches','PaperPosition',[0 0 20 10])
				obj.modelSaveImgToFile([],'stimTrigTrialsAll_','current',strcat(thisFileID));
			% close(figNoAll);

			% obj.figNoAll = obj.figNoAll + 1;
			obj.figNo = figNo;
			obj.figNames = figNames;
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	% % write out summary statistics
	% savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_stimTrigReliabilitySummary.tab'];
	% display(['saving data to: ' savePath])
	% writetable(struct2table(obj.sumStats),savePath,'FileType','text','Delimiter','\t');

	% % write out summary statistics
	% savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_stimTrigReliabilityDetailed.tab'];
	% display(['saving data to: ' savePath])
	% writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');

	obj.sumStats = [];
	obj.detailStats = [];
end