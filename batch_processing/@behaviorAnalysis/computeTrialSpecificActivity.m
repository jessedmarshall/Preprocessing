function obj = computeTrialSpecificActivity(obj)
	% computes firing rate and other statistics for signals on specific set of trials
	% Note, should also have an option to look at just the response of MI signals and signals aligned across sessions
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
	obj.detailStats.subject = {};
	obj.detailStats.assay = {};
	obj.detailStats.assayType = {};
	obj.detailStats.assayNum = {};
	obj.detailStats.stimulus = {};

	nFiles = length(fileIdxArray);
	for thisFileNumIdx = 1:length(fileIdxArray)
		% =====================
		% for backwards compatibility, will be removed in the future.
		nameArray = obj.stimulusNameArray;
		saveNameArray = obj.stimulusSaveNameArray;
		idArray = obj.stimulusIdArray;
		% assayTable = obj.discreteStimulusTable;
		%
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
		assay = obj.assay{obj.fileNum};
		framesPerSecond = obj.FRAMES_PER_SECOND;

		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
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

	%% functionname: function description
	function [outputs] = getResponseInitialTrials(arg)
		trialNumMax = 10;
		triamNumMin = 1;
		for idNumIdx = 1:length(idNumIdxArray)
			idNum = idNumIdxArray(idNumIdx);
			obj.stimNum = idNum;
			stimTimeSeq = obj.stimulusTimeSeq{idNum};
			if options.dfofAnalysis==1
				signalPeaksTwo = IcaTraces;
			else
				signalPeaksTwo = signalPeaks;
			end
			stimVector = obj.modelGetStim(idArray(idNum));
			if isempty(stimVector); continue; end;
			stimVectorIdx = find(stimVector);
			% remove trials that are not being analyzed
			if length(stimVectorIdx)>trialNumMax
				stimVector(stimVectorIdx((trialNumMax+1):end)) = 0;
			end

			% signals sorted by response to stimulus
			nStims = sum(stimVector);
			% get the aligned signal, sum over all input signals
			alignSignalAll = alignSignal(signalPeaksTwo,stimVector,timeSeq);

			% save aligned response to table

		end
end