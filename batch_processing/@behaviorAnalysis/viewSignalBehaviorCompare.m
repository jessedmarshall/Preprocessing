function obj = viewSignalBehaviorCompare(obj)
	% plots comparison of behavior metrics to signal-based analysis (e.g. % significant signals, overlap, etc.)
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

	for thisFileNumIdx = 1:nFilesToAnalyze
		thisFileNum = fileIdxArray(thisFileNumIdx);
		obj.fileNum = thisFileNum;
		display(repmat('=',1,21))
		display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
		% =====================
		% for backwards compatibility, will be removed in the future.
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		nIDs = length(obj.stimulusNameArray);
		nSignals = size(IcaTraces,1);
		if isempty(IcaFilters);continue;end;
		%
		nameArray = obj.stimulusNameArray;
		idArray = obj.stimulusIdArray;
		%
		% signalPeaks = obj.signalPeaks{obj.fileNum};
		%
		options.dfofAnalysis = obj.dfofAnalysis;
		timeSeq = obj.timeSequence;
		subject = obj.subjectNum{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		%
		framesPerSecond = obj.FRAMES_PER_SECOND;
		subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
		%
		figNoAll = obj.figNoAll;
		figNo = obj.figNo;
		figNames = obj.figNames;
		% magic numbers!
		% amount of time to make object maps before/after a stimulus
		prepostTime = 10;
		% ============================
		behaviorMetricTable = obj.behaviorMetricTable;
		behaviorMetricNameArray = obj.behaviorMetricNameArray;
		behaviorMetricIdArray = obj.behaviorMetricIdArray;
		% ============================
		% =====================
		idNumCounter = 1;
		for idNumIdx = 1:length(idNumIdxArray)
			idNum = idNumIdxArray(idNumIdx);
			obj.stimNum = idNum;
			display(repmat('=',1,7))
			display([num2str(idNum) '/' num2str(nIDs) ': analyzing ' nameArray{idNum}])
			% stimVector = obj.stimulusVectorArray{obj.fileNum,idNum};
			stimVector = obj.modelGetStim(idArray(idNum));
			if isempty(stimVector); continue; end;
			% ============================
			obj.behaviorMetricNameArray
			obj.discreteStimulusArray{obj.fileNum}.(['s' num2str(thisID)]) = subjectTable.(frameName);
			% ============================
		    idNumCounter = idNumCounter + 1;
	    end
	end
end