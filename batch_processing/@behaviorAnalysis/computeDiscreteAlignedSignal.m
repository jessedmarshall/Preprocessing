function obj = computeDiscreteAlignedSignal(obj)
	% align signal to a stimulus and display images
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
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();


	movieSettings = inputdlg({...
				'run MI calculations? (0 = no, 1 = yes)',...
				'run dfof analysis? (0 = no, 1 = yes)'...
				'show wilcoxon test graphs? (0 = no, 1 = boxplot, 2 = histogram)'...
			},...
			'discrete stimulus analysis settings',1,...
			{...
				'0',...
				num2str(obj.dfofAnalysis),...
				'0'...
			}...
		);
	runMICalc = str2num(movieSettings{1});
	obj.dfofAnalysis = str2num(movieSettings{2});
	showPerSignalGraph = str2num(movieSettings{3});

	for thisFileNumIdx = 1:nFilesToAnalyze
		thisFileNum = fileIdxArray(thisFileNumIdx);
		obj.fileNum = thisFileNum;
	% for thisFileNum = 1:nFiles
		% obj.fileNum = thisFileNum;
		display(repmat('=',1,21))
		display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
		% =====================
		% for backwards compatibility, will be removed in the future.
		nameArray = obj.stimulusNameArray;
		saveNameArray = obj.stimulusSaveNameArray;
		idArray = obj.stimulusIdArray;
		% assayTable = obj.discreteStimulusTable;
		%
		% [IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filtered_traces');
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		if isempty(IcaTraces); continue; end;
		nSignals = size(IcaTraces,1);
		%
		usTimeAfterCS = 10;
		options.dfofAnalysis = obj.dfofAnalysis;
		% options.stimTriggerOnset = obj.stimTriggerOnset{obj.fileNum};
		options.picsSavePath = obj.picsSavePath;
		thisFileID = obj.fileIDArray{obj.fileNum};
		timeSeq = obj.timeSequence;
		subject = obj.subjectNum{obj.fileNum};
		subjectStr = obj.subjectStr{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		framesPerSecond = obj.FRAMES_PER_SECOND;
		% =====================
		nIDs = length(obj.stimulusNameArray);
		colorArray = hsv(nIDs);
		idNumCounter = 1;
		% =====================
		% initialize some variables
		sigModSignalsAll = zeros([nSignals nIDs]);
		% =====================
		thisFigNo = 9999000;
		[~, ~] = openFigure(thisFigNo+9, '');
		clf

		nIDsTrue = 0;
		for idNumIdx = 1:length(idNumIdxArray)
			idNum = idNumIdxArray(idNumIdx);
			obj.stimNum = idNum;
			% obtain stimulus information
			stimVector = obj.modelGetStim(idArray(idNum));
			if isempty(stimVector); continue; end;
			nIDsTrue = nIDsTrue + 1;
		end

		reponseScoreIdx = [];

		idNumTrue = 1;
		nStimIdx = length(idNumIdxArray);
		for idNumIdx = 1:nStimIdx
			idNum = idNumIdxArray(idNumIdx);
			obj.stimNum = idNum;
			try
				thisFigNo = 9999000;
				% =====================
				display(repmat('=',1,7))
				display([num2str(idNum) '/' num2str(nIDs) ': analyzing ' nameArray{idNum}])
				% =====================
				stimTimeSeq = obj.stimulusTimeSeq{idNum};
				% stimTimeSeq = -4:0;
				% ===============================================================
				if options.dfofAnalysis==1
					signalPeaksTwo = IcaTraces;
				else
					signalPeaksTwo = signalPeaks;
				end
				% ===============================================================
				% obtain stimulus information
				stimVector = obj.modelGetStim(idArray(idNum));
				if isempty(stimVector); continue; end;
				% ===============================================================
				% cascade through stim onset, offset, etc.
				offset = 5;
				display('cleaning up stimulus vector')
				% if options.stimTriggerOnset==1
				% 	stimVectorSpread = spreadSignal(stimVector,'timeSeq',[0:offset]);
				% 	stimVectorSpread = diff(stimVectorSpread);
				% 	stimVectorSpread(stimVectorSpread<0) = 0;
				% 	stimVector = [0; stimVectorSpread(:)]';
				% 	options.stimTriggerOnset = 2;
				% elseif options.stimTriggerOnset==2
				% 	stimVectorSpread = spreadSignal(stimVector,'timeSeq',[-offset:0]);
				% 	stimVectorSpread = diff(stimVectorSpread);
				% 	stimVectorSpread(stimVectorSpread>0) = 0;
				% 	stimVectorSpread(stimVectorSpread<0) = 1;
				% 	stimVector = [0; stimVectorSpread(:)]';
				% 	% exit loop
				% 	options.stimTriggerOnset = 4
				% elseif options.stimTriggerOnset==3
				% 	% FINISH THISSSS
				% 	% convert point frames to continuous data
				% 	stimVector = cumsum(stimVector);
				% elseif options.stimTriggerOnset==0
				% 	options.stimTriggerOnset = 1;
				% else
				% 	% do nothing
				% end
				% stimVectorAll{idNum} = stimVector;
				% options.stimTriggerOnset
				% ===============================================================
				% get signal modulation via t-test for 5 frames post
				display('calculating p-values for signals....')
				stimVectorSpreadTtest = spreadSignal(stimVector,'timeSeq',stimTimeSeq);
				if sum(stimTimeSeq)>=0
					notStimVectorSpreadTtest = spreadSignal(stimVector,'timeSeq',-stimTimeSeq);
				elseif sum(stimTimeSeq)<0
					notStimVectorSpreadTtest = spreadSignal(stimVector,'timeSeq',-stimTimeSeq);
				end
				% notStimVectorSpreadTtest = ~stimVectorSpreadTtest;

				% stimulusSignalPeaks = alignSignal(IcaTraces,stimVectorSpreadTtest,0,'returnFormat','perSignalStimResponseMean');
				% stimulusSignalPeaks = IcaTraces(:,find(stimVectorSpreadTtest));
				% notStimulusSignalPeaks = alignSignal(IcaTraces,notStimVectorSpreadTtest,0,'returnFormat','perSignalStimResponseMean');
				% notStimulusSignalPeaks = alignSignal(IcaTraces,notStimVectorSpreadTtest,0,'returnFormat','perStimSignalResponse');
				% notStimulusSignalPeaks = IcaTraces(:,find(notStimVectorSpreadTtest));
				% stimTimeSeq = 10:30;
				% signalPeaks
				% IcaTraces
				switch obj.dfofAnalysis
					case 0
						stimulusSignalPeaks = alignSignal(signalPeaks,stimVector,stimTimeSeq,'returnFormat','count:[nSignals nAlignmemts]');
						notStimulusSignalPeaks = alignSignal(signalPeaks,stimVector,-stimTimeSeq,'returnFormat','count:[nSignals nAlignmemts]');
					case 1
						stimulusSignalPeaks = alignSignal(IcaTraces,stimVector,stimTimeSeq,'returnFormat','mean:[nSignals nAlignmemts]');
						notStimulusSignalPeaks = alignSignal(IcaTraces,stimVector,-stimTimeSeq,'returnFormat','mean:[nSignals nAlignmemts]');
					otherwise
						% body
				end
				% [h,p] = ttest2(stimulusSignalPeaks',notStimulusSignalPeaks');
				% figure(993213)
				% size(IcaTraces)
				size(stimulusSignalPeaks)
				% showPerSignalGraph = 0;
				nSignalsSig = size(stimulusSignalPeaks,1);
				for signalNo = 1:nSignalsSig
					% stimulusSignalPeaks(signalNo,:)
					% [p,h] = ranksum(stimulusSignalPeaks',notStimulusSignalPeaks');
					% [p(signalNo),h(signalNo)] = ranksum(stimulusSignalPeaks(signalNo,:),notStimulusSignalPeaks(signalNo,:));
					[p(signalNo),h(signalNo)] = ranksum(stimulusSignalPeaks(signalNo,:),notStimulusSignalPeaks(signalNo,:),'tail','right');

					viewStatTestSignificancePlots()
				end
				obj.significantArray{obj.fileNum}{obj.stimNum}.('ttest') = p;
				ttestSignSignals = p<0.01; clear p h

				% showPerSignalGraph = 1;
				significantSignalIdx = find(ttestSignSignals);
				% % significantSignals = find(obj.sigModSignals{obj.fileNum,idNum});
				% nSignalsSig = length(significantSignals);
				% for signalNoIdx = 1:nSignalsSig
				% 	signalNo = significantSignals(signalNoIdx);
				% 	viewStatTestSignificancePlots()
				% end
				% showPerSignalGraph = 0;
				% significantSignalIdx
				if thisFileNumIdx==1
					stimulusSignalPeaksAll{idNumIdx} = [];
				end
				if ~isempty(significantSignalIdx)
					notSignificantSignalIdx = randsample(find(~ttestSignSignals),length(significantSignalIdx));
					[~, ~] = openFigure(42, '');
					subplot(1,nStimIdx,idNumIdx)
						stimulusSignalPeaks = alignSignal(IcaTraces(significantSignalIdx,:),stimVector,stimTimeSeq,'returnFormat','count:[nSignals nAlignmemts]');
						notStimulusSignalPeaks = alignSignal(IcaTraces(significantSignalIdx,:),stimVector,-stimTimeSeq,'returnFormat','count:[nSignals nAlignmemts]');
						groupingVars = [repmat({'stimulus'},[length(stimulusSignalPeaks(:)) 1]); repmat({'no stimulus'},[length(notStimulusSignalPeaks(:)) 1])];
						boxplot([stimulusSignalPeaks(:)' notStimulusSignalPeaks(:)'],...
							groupingVars,...
							'colorgroup',groupingVars,...
							'grouporder',sort(unique(groupingVars)),...
							'labelorientation','inline','notch','on','plotstyle','traditional','whisker',0);
						% 'plotstyle','compact'
						h=findobj(gca,'tag','Outliers');delete(h);axis 'auto y';ylabel('\Deltaf/f')
						% ylim([-0.02 0.1]);
						title(nameArray{idNum})

					% ==================
					% if exist('protocol','var')
					if isempty(stimulusSignalPeaksAll{idNumIdx})
						stimulusSignalPeaksAll{idNumIdx} = stimulusSignalPeaks(:)';
						notStimulusSignalPeaksAll{idNumIdx} = notStimulusSignalPeaks(:)';
						groupingVarsAll{idNumIdx} = [repmat({subjectStr},[length(stimulusSignalPeaks(:)) 1])]
					else
						stimulusSignalPeaksAll{idNumIdx} = [stimulusSignalPeaksAll{idNumIdx} stimulusSignalPeaks(:)'];
						notStimulusSignalPeaksAll{idNumIdx} = [notStimulusSignalPeaksAll{idNumIdx} notStimulusSignalPeaks(:)'];
						groupingVarsAll{idNumIdx} = [groupingVarsAll{idNumIdx}; repmat({subjectStr},[length(stimulusSignalPeaks(:)) 1])]
					end
				end

				% pause

				% ===============================================================
				% calculate mutual information
				display('smoothing signals')
				stimulusSignalPeaks = alignSignal(signalPeaks,stimVectorSpreadTtest,0,'returnFormat','perSignalStimResponseCount');
				notStimulusSignalPeaks = alignSignal(signalPeaks,notStimVectorSpreadTtest,0,'returnFormat','perSignalStimResponseCount');

				% skipMICalc = 1;
				if runMICalc==0
					display('skipping MI calculations...')
					try
						sigModSignals = obj.sigModSignals{obj.fileNum,idNum};
						sigModSignalsAll = obj.sigModSignalsAll{obj.fileNum};
					catch
						display('enter blank MI values...')
						sigModSignals = zeros([1 nSignals]);
						sigModSignalsAll = zeros([1 nSignals]);
					end
				elseif runMICalc==1
					% spreadSignalPeaks = spreadSignal(signalPeaks,'timeSeq',stimTimeSeq);
					stimVectorSpreadMI = spreadSignal(stimVector,'timeSeq',stimTimeSeq);
					% miScores = MutualInformation(stimVector,spreadSignalPeaks);
					miScoresShuffled = mutualInformationShuffle(stimVectorSpreadMI,signalPeaks);
					obj.modelSaveImgToFile([],'MIShuffleScores','current',strcat(thisFileID,'_',saveNameArray{idNum}));

					sigModSignals = miScoresShuffled(:,1)>(miScoresShuffled(:,2)+1.96*miScoresShuffled(:,3));
					sigModSignalsZscore = miScoresShuffled(:,4);
					obj.significantArray{obj.fileNum}{obj.stimNum}.('MI') = sigModSignalsZscore;
					nSignals = size(miScoresShuffled,1);
					pieNums = [sum(sigModSignals)/nSignals sum(~sigModSignals)/nSignals];
					sigModSignalsAll(:,idNum) = sigModSignals;
					% if idNumCounter==1
					% 	sigModSignalsAll = sigModSignals(:);
					% else
					% 	sigModSignalsAll = [sigModSignalsAll sigModSignals(:)];
					% end
					% pieLabels = strcat({'not-significant','significant'},' : ',num2str(pieNums));
				else
					sigModSignals = zeros([1 nSignals]);
					sigModSignalsAll = zeros([1 nSignals]);
				end
				%
				obj.sigModSignals{obj.fileNum,idNum} = sigModSignals;
				obj.sigModSignalsAll{obj.fileNum} = sigModSignalsAll;
				%
				obj.ttestSignSignals{obj.fileNum,idNum} = ttestSignSignals;
				% =====================
				viewDiscreteAlignedSignal();
				% =====================
				idNumCounter = idNumCounter+1;
			catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
			end
		end
	end
	function viewStatTestSignificancePlots2()
		if idNumIdx==nStimIdx
			suptitle([obj.fileIDNameArray{obj.fileNum}])
			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 20 7])
			obj.modelSaveImgToFile([],'significantRanksumBoxplots_','current',strcat(thisFileID));
			clf
		end
		if thisFileNumIdx==nFilesToAnalyze&idNumIdx==nStimIdx
			display('***********************************')
			for tmpI = 1:length(stimulusSignalPeaksAll)
				[~, ~] = openFigure(41, '');
				subplot(1,length(stimulusSignalPeaksAll),tmpI)
				stimulusSignalPeaks = stimulusSignalPeaksAll{tmpI}(:);
				notStimulusSignalPeaks = notStimulusSignalPeaksAll{tmpI}(:);
				groupingVars = [repmat({'stimulus'},[length(stimulusSignalPeaks(:)) 1]); repmat({'no stimulus'},[length(notStimulusSignalPeaks(:)) 1])];
				sigPeaksAll = (stimulusSignalPeaks(:)'-notStimulusSignalPeaks(:)');
				notSigPeaksAll = (notStimulusSignalPeaks(:)'-notStimulusSignalPeaks(:)');
				% hold on
				% for ii=1:length(sigPeaksAll)
				% 	plot([1,2],[sigPeaksAll(ii),notSigPeaksAll(ii)],'-or',...
				% 	'MarkerFaceColor',[1,0.5,0.5])
				% end
				% continue
				boxplot([sigPeaksAll(:)' notSigPeaksAll(:)'],...
					groupingVars,...
					'colorgroup',groupingVars,...
					'grouporder',sort(unique(groupingVars)),...
					'labelorientation','inline','notch','on','plotstyle','traditional','whisker',0);
				% 'plotstyle','compact'
					h=findobj(gca,'tag','Outliers');delete(h);axis 'auto y';ylabel('\Deltaf/f (per trial difference)')
					% ylim([-0.02 0.1]);
				title(nameArray{tmpI})
				[~, ~] = openFigure(40, '');
					subplot(1,length(stimulusSignalPeaksAll),tmpI)
					boxplot([sigPeaksAll(:)'],...
						groupingVarsAll{tmpI},...
						'colorgroup',groupingVarsAll{tmpI},...
						'grouporder',sort(unique(groupingVarsAll{tmpI})),...
						'labelorientation','inline','notch','on','plotstyle','compact','whisker',0);
					% 'plotstyle','compact'
						h=findobj(gca,'tag','Outliers');delete(h);axis 'auto y';ylabel('\Deltaf/f (per trial difference)')
				title(nameArray{tmpI})
			end
			% suptitle('all animals')

		end
		% continue
	end
	function viewStatTestSignificancePlots()
		afterStimulusInterest = sum(stimTimeSeq)>0;
		switch showPerSignalGraph
			case 1
				clf
				subplot(1,2,1)
					if afterStimulusInterest
						before = notStimulusSignalPeaks(signalNo,:);
						after = stimulusSignalPeaks(signalNo,:);
						xticklabelShow = {'not stimulus','stimulus'};
					else
						after = notStimulusSignalPeaks(signalNo,:);
						before = stimulusSignalPeaks(signalNo,:);
						xticklabelShow = {'stimulus','not stimulus'};
					end
					% boxplot([before,after]);
					hold on
					for ii=1:length(before)
						plot([1,2],[before(ii),after(ii)],'-or',...
						'MarkerFaceColor',[1,0.5,0.5])
					end
					boxplot([before',after'],'notch','off','labels',xticklabelShow)
					% set(gca,'XTickLabel',xticklabelShow)
					switch obj.dfofAnalysis
						case 0
							% ylim([-0.1 0.3]);
						case 1
							ylim([-0.1 0.3]);
						otherwise
							% body
					end
					hold off
					title([num2str(signalNo) '|' num2str(p(signalNo))])
				subplot(1,2,2)
					% size(peakIdxs)
					framesToAlign = find(stimVector);
					framesPerSecond = 5;
					% timeVector = [-stimTimeSeq:stimTimeSeq];
					% timeVector = [-stimTimeSeq stimTimeSeq];
					timeVector = [-nanmax(abs(stimTimeSeq)):nanmax(abs(stimTimeSeq))];
					% peakIdxs = bsxfun(@plus,timeVector,framesToAlign(:))';
					% peakIdxs(:)

					% x = reshape(IcaTraces(signalNo,peakIdxs),size(peakIdxs))';
					% x
					% x = IcaTraces(signalNo,peakIdxs(:));

					x = alignSignal(IcaTraces(signalNo,:), stimVector,timeVector,'returnFormat','[nSignals nAlignmemts nTimeSeqPoints]');
					x = squeeze(x);
					% size(x)
					% imagesc(x)
					plot(repmat(timeVector, [size(x,1) 1])', x','Color',[4 4 4]/8)
					% plotSignalsGraph(x','LineWidth',2.5);
					hold on;
					plot(timeVector, nansum(x,1),'k', 'LineWidth',3);box off;
					xlabel('frames relative to stimulus')
					ylim([-0.1 0.3]);
					hold off;
				suptitle([num2str(signalNo) ' / ' num2str(nSignalsSig)])
				pause
			case 2
				% hist(stimulusSignalPeaks(signalNo,:),20)
				[counts1, values1] = hist(stimulusSignalPeaks(signalNo,:), 20);
				[counts2, values2] = hist(notStimulusSignalPeaks(signalNo,:), 20);
				plot(values1, counts1, 'r-');
				hold on
				plot(values2, counts2, 'b-');
				legend({'stimuli','not stimuli'})
				title(num2str(p(signalNo)))
				hold off
				pause
			otherwise
				% body
		end
		% figure(222)
		% subplot(2,1,1)
		% plot(stimVectorSpreadTtest, 'Color', 'red');
		% subplot(2,1,2)
		% plot(notStimVectorSpreadTtest, 'Color', 'green')
		% % legend({'stimulus','not stimulus'});

		% figure(221);
		% maxH = max(stimulusSignalPeaks(:));
		% histH = hist(stimulusSignalPeaks(:),[0:maxH]);
		% plot([0:maxH], histH/max(histH), 'Color', 'red');box off;
		% hold on;
		% maxH = max(notStimulusSignalPeaks(:));
		% histH = hist(notStimulusSignalPeaks(:),[0:maxH]);
		% plot([0:maxH], histH/max(histH), 'Color', 'black');box off;
		% legend({'stimulus','not stimulus'});
		% hold off;
	end
	function viewDiscreteAlignedSignal()
		% ===============================================================
		% signals sorted by response to stimulus
		nStims = sum(stimVector);
		% get the aligned signal, sum over all input signals
		alignSignalAll = alignSignal(signalPeaksTwo,stimVector,timeSeq);
		% sort by cells most responsive right after stimuli
		% alignSignalAllSum = sum(alignSignalAll((round(end/2):(round(end/2)+10)),:),1);
		alignSignalAllSum = sum(alignSignalAll((round(end/2)+7:end),:),1);
		alignSignalAllSum = sum(alignSignalAll(((round(end/2)-7)):round(end/2),:),1);
		alignSignalAllSum2 = sum(alignSignalAll((round(end/2):(round(end/2)+7)),:),1);
		sortMetric = alignSignalAllSum-alignSignalAllSum2;
		g = alignSignalAll;
		% get the median time-point during which a cell fires
		% [i j] = find(g); k = g; k(find(g)) = j; k(k==0) = NaN; sortMetric = nanmedian(k,1);
		% sortMetric(isnan(sortMetric)) = 0;
		%
		if idNumIdx==1
			[responseN reponseScoreIdx] = sort(sortMetric,'descend');
		end
		signalPeaksTwoSorted = signalPeaksTwo(reponseScoreIdx,:);
		nSignals = size(signalPeaksTwo,1);
		% alignSetsIdx = {1:nSignals,[1:10],[nSignals-10:nSignals],find(sigModSignals(reponseScoreIdx))};
		% size(ttestSignSignals)
		% size(sigModSignals)
		% size(reponseScoreIdx)
		alignSetsIdx = {1:nSignals,find(ttestSignSignals(reponseScoreIdx)),find(~ttestSignSignals(reponseScoreIdx)),find(sigModSignals(reponseScoreIdx))};
		numAlignSets = length(alignSetsIdx);
		reverseStr = '';
		titleSubplot = {'all cells','t-test p<0.05','t-test p>0.05','mutually informative'};
		[~, ~] = openFigure(thisFigNo, '');
			subplotX = 4;
			subplotY = 3;
			imgSubplotLoc = {[1 5],[2 6],[3 7],[4 8]};
			plotSubplotLoc = {[9],[10],[11],[12]};
			signalPeaksTwoSorted = signalPeaksTwo(reponseScoreIdx,:);
			alignSignalAllSorted = alignSignalAll(:,reponseScoreIdx);
			clear alignSignalImg alignedSignalArray alignedSignalArray
			maxValAll = 0; minValAll = 0;
			for alignNo = 1:numAlignSets
				display([num2str(alignNo) '\' num2str(numAlignSets) ' | aligning and shuffling: ' titleSubplot{alignNo}])
				nAlignSignals = length(alignSetsIdx{alignNo});
				alignSignalImg{alignNo} = alignSignalAllSorted(:,alignSetsIdx{alignNo})';
				thisSignal = signalPeaksTwoSorted(alignSetsIdx{alignNo},:);
				% make dummy vector if empty
				if isempty(thisSignal)
					display('using empty dummy vector')
					thisSignal = zeros([1 size(signalPeaksTwoSorted,2)]);
				end
				alignedSignalArray{alignNo} = alignSignal(thisSignal, stimVector,timeSeq,'overallAlign',1);
				% alignedSignalArray{alignNo} = alignSignal(thisSignal, stimVector,timeSeq,'returnFormat','totalStimResponseMean');
				alignedSignalArray{alignNo} = alignedSignalArray{alignNo}/nStims;
				% nShuffles = 20;
				% for i=1:nShuffles
				% 	alignedSignalShuffled(:,i) = alignSignal(shuffleMatrix(thisSignal,'waitbarOn',0), stimVector,timeSeq,'overallAlign',1)';
				% 	% alignedSignalStimShuffled(:,i) = alignSignal(signalPeaks, shuffleMatrix(stimVector,'waitbarOn',0),timeSeq,'overallAlign',1)';
					% reverseStr = cmdWaitbar(i,nShuffles,reverseStr,'inputStr','shuffling alignment','waitbarOn',1,'displayEvery',1);
				% end
				% alignedSignalShuffledMeanArray{alignNo} = mean(alignedSignalShuffled/nStims,2);
				% alignedSignalShuffledStdArray{alignNo} = std(alignedSignalShuffled/nStims,0,2);
				ttestSpreadIdx = 0:5;
				stimVectorSpreadTtest = spreadSignal(stimVector,'timeSeq',ttestSpreadIdx);
				notStimVectorSpreadTtest = ~stimVectorSpreadTtest;
				notStimulusSignalPeaks = alignSignal(thisSignal,notStimVectorSpreadTtest,0,'returnFormat','totalStimResponseCount');
				alignedSignalShuffledMeanArray{alignNo} = repmat(nanmean(notStimulusSignalPeaks),[length(alignedSignalArray{alignNo}) 1]);
				alignedSignalShuffledStdArray{alignNo} = repmat(nanstd(notStimulusSignalPeaks),[length(alignedSignalArray{alignNo}) 1]);
				% maxDisplayValue = max(alignSignalImg{1}(:));
				% minDisplayValue = min(alignSignalImg{1}(:));
				alignSignalImg{alignNo}(1,1) = max(alignSignalImg{1}(:));
				alignSignalImg{alignNo}(1,2) = min(alignSignalImg{1}(:));
				%
				subplot(subplotY,subplotX,imgSubplotLoc{alignNo})
					% alignTMPPP = alignSignalImg{alignNo}/nStims;
					% alignTMPPP(alignTMPPP<0.05) = 0;
					% imagesc(alignTMPPP);
					% imagesc(alignSignalImg{alignNo}/nStims);
					imagesc(alignSignalImg{alignNo});
					% =======
					% tmpTraces = alignSignal(IcaTraces(alignSetsIdx{alignNo},:),stimVector,timeSeq);
					% plotSignalsGraph(tmpTraces(:,1:10)','LineWidth',2.5);
					% =======
					box off;axis off; set(gca,'xtick',[],'xticklabel',[]);
					ylabel('cells')
					colormap(customColormap([]));
					cb = colorbar('location','southoutside');
					if options.dfofAnalysis==1
						xlabel(cb, '\DeltaF/F/stimulus');
					else
						xlabel(cb, 'spikes/stimulus');
					end

					midpoint = round(size(alignSignalImg{alignNo},2)/2);
					x = [midpoint midpoint];
					y = [1 size(alignSignalImg{alignNo},1)];
					maxStimSeq = nanmax(abs(stimTimeSeq));
					hold on;
					plot(x,y,'Color','r','LineStyle','-');
					x = [midpoint+maxStimSeq midpoint+maxStimSeq];
					plot(x,y,'Color','g','LineStyle','-');
					x = [midpoint-maxStimSeq midpoint-maxStimSeq];
					plot(x,y,'Color','g','LineStyle','-');
					hold off;

					title(titleSubplot{alignNo});
				subplot(subplotY,subplotX,plotSubplotLoc{alignNo})
					viewLineFilledError(alignedSignalShuffledMeanArray{alignNo},alignedSignalShuffledStdArray{alignNo},'xValues',timeSeq);
					hold on;
					% ========
					% FREEZE ADDED
						plot(timeSeq, alignedSignalArray{alignNo},'k','LineWidth',2); hold on;
						tmpAlignSignalAll = alignSignal(thisSignal,stimVector,timeSeq);
						tmpAlignSignalAllSum = sum(tmpAlignSignalAll((round(end/2):(round(end/2)+10)),:),1)-sum(tmpAlignSignalAll((round(end/2)-10:(round(end/2))),:),1);
						% tmpAlignSignalAllSum
						updownArray = {tmpAlignSignalAllSum>=0,tmpAlignSignalAllSum<0};
						updownColorArray = {'g','r'};
						for updownIdx = 1:length(updownArray)
							tmpAlignedSignalArray = alignSignal(thisSignal(updownArray{updownIdx},:), stimVector,timeSeq,'overallAlign',1);
							tmpAlignedSignalArray = tmpAlignedSignalArray/nStims;
							if ~isempty(tmpAlignedSignalArray)
								plot(timeSeq, tmpAlignedSignalArray,updownColorArray{updownIdx},'LineWidth',2); hold on;
							end
						end
						box off;
					% ========
					if alignNo==1
						if options.dfofAnalysis==1
							ylabel('\DeltaF/F');
						else
							ylabel('spikes/stimulus');

						end
					end
					if options.dfofAnalysis==1

					else
						kkk = [alignedSignalArray{alignNo} alignedSignalShuffledMeanArray{alignNo}+1.96*alignedSignalShuffledStdArray{alignNo}];
						kkk = nanmax(kkk(:))*1.1;
						y=ylim;
						try
							ylim([0 kkk]);
						catch

						end
					end
					xlabel('frames')
					hold off;
				% calculate max if want all plots to have same axes
				biMean = alignedSignalShuffledMeanArray{alignNo};
				biStd = alignedSignalShuffledStdArray{alignNo};
				biAll = alignedSignalArray{alignNo};
				biMax = [biMean+1.96*biStd biAll];
				biMin = [biMean-1.96*biStd biAll];
				maxVal = max(biMax(:));
				minVal = min(biMin(:));
				if (maxVal>maxValAll) maxValAll = maxVal; end;
				if (minVal<minValAll) minValAll = minVal; end;
			end
			for alignNo = 1:numAlignSets
				subplot(subplotY,subplotX,plotSubplotLoc{alignNo})
					ylim([minValAll-0.1*abs(minValAll),maxValAll+0.1*maxValAll])
			end
			suptitle([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | all trials'])
			% title([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | all trials'])
		obj.modelSaveImgToFile([],'stimTriggeredPerCell_',thisFigNo,strcat(thisFileID,'_',saveNameArray{idNum}));
		% store the aligned signal in output structure
		% ostruct.aggregate.stimTriggered{idNum}(ostruct.counter,:) = alignedSignalArray{1};
		% =====================
		[~, ~] = openFigure(thisFigNo+9, '');
			subplot(1,nIDsTrue,idNumTrue)
				% tmpImgAlign = alignSignalImg{1};
				% tmpImgAlign(end+1:end+3,:) = 0;
				% tmpImgAlign(end+1:end+3,:) = 1;
				switch obj.dfofAnalysis
					case 0
						if strcmp(nameArray{idNum},'lick  all')==1
							imagesc(alignSignalImg{1}/nStims);
						else
							imagesc(alignSignalImg{1}/nStims==0);
						end
					case 1
						imagesc(alignSignalImg{1}/nStims);
					otherwise
						% body
				end

				% =======
				% tmpTraces = alignSignal(IcaTraces(alignSetsIdx{alignNo},:),stimVector,timeSeq);
				% plotSignalsGraph(tmpTraces(:,1:10)','LineWidth',2.5);
				% =======
				% box off;
				% axis off;
				timeSeqLen = length(timeSeq);
				timeSeqSeconds = round(timeSeq/framesPerSecond);
				set(gca,'xtick',[timeSeqLen/5 timeSeqLen/2 timeSeqLen/5*4],'xticklabel',[timeSeqSeconds(round(end/5)) timeSeqSeconds(round(end/2)) timeSeqSeconds(round(end/5*4))]);
				if idNumTrue ~= 1
					set(gca,'ytick',[],'yticklabel',[]);
				end
				ylabel('cells')
				xlabel('seconds');
				% colormap(customColormap([]));
				% colormap(customColormap({[0 0 0], [0 0 1],[1 0 0]}));
				switch obj.dfofAnalysis
					case 0
						colormap(customColormap({[1 1 1],[0 0 0],[1 0 0]}));
						colormap gray
					case 1
						colormap(obj.colormap);
					otherwise
						% body
				end
				cb = colorbar('location','southoutside');
				if options.dfofAnalysis==1
					xlabel(cb, '\DeltaF/F/stimulus');
				else
					xlabel(cb, 'spikes/stimulus');
				end
				hold on;
				xval = timeSeqLen/2;
				x=[xval,xval];
				% y=[minValTraces maxValTraces];
				y=[0 size(IcaTraces,1)];
				plot(x,y,'r');

				stimVectorCopy = obj.modelGetStim(idArray(idNum));
				stimVectorCopy = sum(stimVectorCopy);
				title([nameArray{idNum},10,num2str(stimVectorCopy)]);
			if idNum==nIDs
				suptitle([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | all trials'])
				% title([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | all trials'])
			end
			set(thisFigNo+9,'PaperUnits','inches','PaperPosition',[0 0 20 7])
			obj.modelSaveImgToFile([],'stimTriggeredPerCellAll_','current',strcat(thisFileID));
			idNumTrue = idNumTrue + 1;

		% =====================
		% thisSignal = signalPeaksTwoSorted;
		thisSignal = signalPeaksTwo;
		% thisFigNo = thisFigNo+1;
		[~, ~] = openFigure(thisFigNo+1, '');
			prepostTime = 10;
			% x = alignSignal(IcaTraces,stimVector,0:50,'returnFormat','count:[nSignals nAlignmemts]');
			alignedSignalPerTrial = alignSignal(thisSignal, stimVector,0:prepostTime,'returnFormat','count:[nSignals nAlignmemts]');
			alignedSignalPerTrialPre = alignSignal(thisSignal, stimVector,-prepostTime:0,'returnFormat','count:[nSignals nAlignmemts]');
			alignedSignalPerTrialRatio = alignedSignalPerTrial./alignedSignalPerTrialPre;
			alignedSignalPerTrialNorm = alignSignal(thisSignal, stimVector,0:prepostTime,'returnFormat','normcount:[nSignals nAlignmemts]');

			% [responseN reponseScoreIdx] = sort(sum(alignedSignalPerTrial,2),'descend');
			% alignedSignalPerTrial = alignedSignalPerTrial(reponseScoreIdx,:);
			% [responseN reponseScoreIdx] = sort(sum(alignedSignalPerTrialNorm,2),'descend');
			% alignedSignalPerTrialNorm = alignedSignalPerTrialNorm(reponseScoreIdx,:);

			% for i=1:nAlignSignalsPlot
				subplot(1,3,1)
					imagesc(alignedSignalPerTrial)
					colormap(customColormap([]));
					cb = colorbar('location','southoutside');
					xlabel('trial');ylabel('cell #');
					title('unormalized');
				subplot(1,3,2)
					imagesc(alignedSignalPerTrialNorm)
					colormap(customColormap([]));
					cb = colorbar('location','southoutside');
					xlabel('trial');ylabel('cell #');
					title('per trial normalized');
			% end
			suptitle([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | per trial'])
			% title([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | per trial'])
		obj.modelSaveImgToFile([],'stimTrigTrials_','current',strcat(thisFileID,'_',saveNameArray{idNum}));

		[~, ~] = openFigure(thisFigNo, '');
			suptitle([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | all trials'])
			drawnow;

		% [~, ~] = openFigure(thisFigNo+9, '');
		% =====================
		% add analysis to object
		alignIdxToUse = 1;
		% obj.stimulusVectorArray{obj.fileNum,idNum} = stimVector;
		obj.alignedSignalArray{obj.fileNum,idNum} = alignedSignalArray;
		obj.alignedSignalShuffledMeanArray{obj.fileNum,idNum} = alignedSignalShuffledMeanArray;
		obj.alignedSignalShuffledStdArray{obj.fileNum,idNum} = alignedSignalShuffledStdArray;
	end
end