function obj = computeDiscreteRateStats(obj)
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
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	obj.sumStats = [];
	obj.detailStats = [];

	obj.sumStats = {};
	obj.sumStats.subject{1,1} = nan;
	obj.sumStats.assay{1,1} = nan;
	obj.sumStats.assayType{1,1} = nan;
	obj.sumStats.assayNum{1,1} = nan;
	obj.sumStats.stimulus{1,1} = nan;
	obj.sumStats.varType{1,1} = nan;
	obj.sumStats.percentTrialsActiveMean{1,1} = nan;
	% obj.sumStats.percentTrialsActiveMedian{1,1} = nan;
	obj.sumStats.meanEventRatePerSignal{1,1} = nan;
	obj.sumStats.meanPercentActiveSignals{1,1} = nan;
	obj.sumStats.meanZscorePerSignal{1,1} = nan;

	obj.detailStats.frame = [];
	obj.detailStats.value = [];
	obj.detailStats.varType = {};
	obj.detailStats.statType = {};
	obj.detailStats.subject = {};
	obj.detailStats.assay = {};
	obj.detailStats.assayType = {};
	obj.detailStats.assayNum = {};
	obj.detailStats.stimulus = {};

	nFiles = length(fileIdxArray);
	for thisFileNumIdx = 1:length(fileIdxArray)
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			%
			[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filtered_traces');
			nIDs = length(obj.stimulusNameArray);
			nSignals = size(IcaTraces,1);
			if isempty(IcaTraces);continue;end;
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
			nFrames = obj.nFrames{obj.fileNum};
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
			stimVectorAll = zeros([1 size(IcaTraces,2)]);
			for idNumIdx = 1:(length(idNumIdxArray)+1)
				if idNumIdx<=nIDs
					idNum = idNumIdxArray(idNumIdx);
					obj.stimNum = idNum;
					stimName = nameArray{idNum};
					stimTimeSeq = obj.stimulusTimeSeq{idNum};
					stimVector = obj.modelGetStim(idArray(idNum));
					if isempty(stimVector); continue; end;
					stimVectorAll = stimVectorAll|stimVector;
				else
					display('calculating no stimuli values...')
					stimVector = ~stimVectorAll;
					stimName = 'no stimuli';
					stimTimeSeq = 0;
				end

				varNameArray = {'preStimulus','postStimulus','winStimulus','onlyStimulus'};
				% ADD SIGNIFICANTLY CODING
				% varDataArray = {percentTrialsActivePre,percentTrialsActivePost,percentTrialsActiveWindow};
				prepostTime = 10;
				varStimArray = {0:prepostTime,prepostTime:0,stimTimeSeq,0};
				for varNum=1:length(varNameArray)
					alignedSignalPerTrialTmp = alignSignal(thisSignal, stimVector,varStimArray{varNum},'returnFormat','count:[nSignals nAlignmemts]');
					percentTrialsActiveTmp = sum(alignedSignalPerTrialTmp,2)/size(alignedSignalPerTrialTmp,2);
					nStims = length(find(stimVector));
					stimVectorSpread = spreadSignal(stimVector,'timeSeq',varStimArray{varNum});
					meanEventRatePerSignal = (sum(thisSignal(:,find(stimVectorSpread)),2)/length(find(stimVectorSpread)))*framesPerSecond;
					% look at the mean peak size per signal
					IcaTracesPeaksOnly = IcaTraces.*thisSignal;
					meanPeakSizePerSignal = (sum(IcaTracesPeaksOnly(:,find(stimVectorSpread)),2)/length(find(stimVectorSpread)))*framesPerSecond;

					meanPercentActiveSignals = sum(thisSignal(:,find(stimVectorSpread)),1)/size(thisSignal,1);
					% size(meanPercentActiveSignals)
					% Zscore
					stimMeanEventRate = sum(thisSignal,2)/length(find(stimVectorSpread));
					meanEventRate = nanmean(thisSignal,2);
					stdEventRate = nanstd(thisSignal,[],2);
					% size(stdEventRate)
					zscoreEventRate = (stimMeanEventRate(:)-meanEventRate(:))/stdEventRate(:);

					% SUMMARY
					obj.sumStats.subject{end+1,1} = subject;
					obj.sumStats.assay{end+1,1} = assay;
					obj.sumStats.assayType{end+1,1} = assayType;
					obj.sumStats.assayNum{end+1,1} = assayNum;
					obj.sumStats.stimulus{end+1,1} = stimName;
					obj.sumStats.varType{end+1,1} = varNameArray{varNum};
					obj.sumStats.percentTrialsActiveMean{end+1,1} = nanmean(percentTrialsActiveTmp);
					% obj.sumStats.percentTrialsActiveMedian{end+1,1} = nanmedian(percentTrialsActiveTmp);
					obj.sumStats.meanEventRatePerSignal{end+1,1} = nanmean(meanEventRatePerSignal);
					obj.sumStats.meanPercentActiveSignals{end+1,1} = nanmean(meanPercentActiveSignals);
					obj.sumStats.meanZscorePerSignal{end+1,1} = nanmean(zscoreEventRate(:));

					% DETAILED
					detailsSumStat = {meanEventRatePerSignal,meanPercentActiveSignals,};
					detailsSumStr = {'meanEventRatePerSignal','meanPercentActiveSignals'};
					for statNo=1:length(detailsSumStat)
						numPtsToAdd = length(detailsSumStat{statNo});
						signalNums = 1:length(detailsSumStat{statNo}(:));
						obj.detailStats.frame(end+1:end+numPtsToAdd,1) = signalNums(:);
						% obj.detailStats.value(end+1:end+numPtsToAdd,1) = value(:);
					    obj.detailStats.value(end+1:end+numPtsToAdd,1) = detailsSumStat{statNo}(:);
						obj.detailStats.varType(end+1:end+numPtsToAdd,1) = {varNameArray{varNum}};
						obj.detailStats.statType(end+1:end+numPtsToAdd,1) = {detailsSumStr{statNo}};
						obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subject};
						obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
						obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
						obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
						obj.detailStats.stimulus(end+1:end+numPtsToAdd,1) = {stimName};
					end
				end

				idNumCounter = idNumCounter + 1;
			end
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end

	% write out summary statistics
	savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_stimTrigSummary.tab'];
	display(['saving data to: ' savePath])
	writetable(struct2table(obj.sumStats),savePath,'FileType','text','Delimiter','\t');

	% write out summary statistics
	% savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_stimTrigDetailed.tab'];
	% display(['saving data to: ' savePath])
	% writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');

	% obj.sumStats = [];
	% obj.detailStats = [];