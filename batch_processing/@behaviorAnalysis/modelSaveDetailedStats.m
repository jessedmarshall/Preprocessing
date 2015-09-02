function obj = modelSaveDetailedStats(obj)
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

	nameArray = obj.stimulusNameArray;
	saveNameArray = obj.stimulusSaveNameArray;
	idArray = obj.stimulusIdArray;
	timeSeq = obj.timeSequence;
	% ============================
	display('creating bigdata structure...')
	obj.detailStats = [];
    obj.detailStats.frame = [];
    obj.detailStats.value = [];
    obj.detailStats.varType = {};
    % obj.detailStats.subjectType = {};
    obj.detailStats.subject = {};
    obj.detailStats.assay = {};
    obj.detailStats.assayType = {};
    obj.detailStats.assayNum = {};
	obj.detailStats
	% ============================
	if strcmp(obj.analysisType,'group')
	    nFiles = length(obj.rawSignals);
	else
	    nFiles = 1;
	end
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	for thisFileNumIdx = 1:nFilesToAnalyze
		thisFileNum = fileIdxArray(thisFileNumIdx);
		obj.fileNum = thisFileNum;

	    subject = obj.subjectStr{obj.fileNum};
	    assay = obj.assay{obj.fileNum};
	    assayType = obj.assayType{obj.fileNum};
	    assayNum = obj.assayNum{obj.fileNum};
	    nIDs = length(obj.stimulusNameArray);
	    display(repmat('=',1,21))
	    display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
    	[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filtered_traces');

	    idNumTrue = 1;
	    nStimIdx = length(idNumIdxArray);
	    for idNumIdx = 1:nStimIdx
	    	idNum = idNumIdxArray(idNumIdx);
	    	obj.stimNum = idNum;
	    	display([num2str(idNum) '/' num2str(nIDs) ' | extracting/saving summary stats: ' nameArray{idNum}])
	    	% ============================
	    	% signalPeaksTwo = IcaTraces;
	    	timeSeq = obj.timeSequence;
	    	% obtain stimulus information
	    	stimVector = obj.modelGetStim(idArray(idNum));
	    	if isempty(stimVector); continue; end;
    		% signals sorted by response to stimulus
    		nStims = sum(stimVector);
	    	% get the aligned signal, sum over all input signals
	    	% alignSignalAll = alignSignal(signalPeaksTwo,stimVector,timeSeq);

	    	alignedSignalArray = obj.alignedSignalArray{obj.fileNum,idNum};
	    	alignedSignalShuffledMeanArray = obj.alignedSignalShuffledMeanArray{obj.fileNum,idNum};
	    	alignedSignalShuffledStdArray = obj.alignedSignalShuffledStdArray{obj.fileNum,idNum};

	    	% alignedSignalArray = alignSignal(IcaTraces, stimVector,timeSeq,'overallAlign',1);
	    	% alignedSignalArray = alignedSignalArray/nStims;
	    	alignedSignalArray = alignSignal(IcaTraces, stimVector,timeSeq,'returnFormat','mean-sum[1 nTimeSeqPoints]');
	    	% plot(alignedSignalArray)
	    	if isempty(obj.alignedSignalArray{obj.fileNum,idNum})
	    	    continue;
	    	end
	    	% titleSubplot = {'all cells','t-test p<0.05','t-test p>0.05','mutually informative'};
	    	alignSignalNum = 1;
	    	% alignedSignal = obj.alignedSignalArray{obj.fileNum,idNum}{alignSignalNum};
	    	alignedSignal = alignedSignalArray;
	    	if isempty(alignedSignal)
	    	    continue;
	    	end
	    	alignedSignalShuffledMean = obj.alignedSignalShuffledMeanArray{obj.fileNum,idNum}{alignSignalNum};
	    	alignedSignalShuffledStd = obj.alignedSignalShuffledStdArray{obj.fileNum,idNum}{alignSignalNum};
	    	sigModSignals = obj.sigModSignals{obj.fileNum,idNum};
	    	% ============================
	    	% calculate Zscore
	    	% zscores = (alignedSignal-alignedSignalShuffledMean)./alignedSignalShuffledStd;
	    	zscores = alignedSignal;
	    	% ============================
			numPtsToAdd = length(zscores);
			zscoresLength = 1:length(zscores);
			obj.detailStats.frame(end+1:end+numPtsToAdd,1) = zscoresLength(:);
			obj.detailStats.value(end+1:end+numPtsToAdd,1) = zscores(:);
			obj.detailStats.varType(end+1:end+numPtsToAdd,1) = {nameArray{idNum}};
			% obj.bigData.subjectType(end+1:end+numPtsToAdd,1) = subjectType;
			obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subject};
			obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
			obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
			obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
	    end
	end


	% write out large data
    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_stimTriggered_bigData2.tab'];
    display(['saving data to: ' savePath])
    obj.detailStats
	writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
end