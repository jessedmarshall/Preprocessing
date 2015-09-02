function obj = computePopulationDistance(obj)
	% for testing out new algorithms, currently mahalanobis distances
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

	if strcmp(obj.analysisType,'group')
		nFiles = length(obj.rawSignals);
	else
		nFiles = 1;
	end

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	obj.detailStats = [];
	obj.detailStats.frame = [];
    obj.detailStats.value = [];
    obj.detailStats.stimulusRef = {};
    obj.detailStats.stimulusTest = {};
    obj.detailStats.subject = {};
    obj.detailStats.assay = {};
    obj.detailStats.assayType = {};
    obj.detailStats.assayNum = {};
	obj.detailStats

	for thisFileNumIdx = 1:length(fileIdxArray)
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			% display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			nameArray = obj.stimulusNameArray;
			saveNameArray = obj.stimulusSaveNameArray;
			idArray = obj.stimulusIdArray;
			assayTable = obj.discreteStimulusTable;
			%
			[IcaTraces IcaFilters signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj);
			signalPeaks = IcaTraces;
			nIDs = length(obj.stimulusNameArray);
			nSignals = size(IcaTraces,1);
			if isempty(IcaFilters);continue;end;
			% IcaTraces = obj.rawSignals{obj.fileNum};
			% IcaFilters = obj.rawImages{obj.fileNum};
			% signalPeaks = obj.signalPeaks{obj.fileNum};
			%
			options.dfofAnalysis = obj.dfofAnalysis;
			options.stimTriggerOnset = obj.stimTriggerOnset;
			options.picsSavePath = obj.picsSavePath;
			thisFileID = obj.fileIDArray{obj.fileNum};
			subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
			framesPerSecond = obj.FRAMES_PER_SECOND;
			timeSeq = obj.timeSequence;
			%
			subject = obj.subjectNum{obj.fileNum};
			assay = obj.assay{obj.fileNum};
			assayType = obj.assayType{obj.fileNum};
			assayNum = obj.assayNum{obj.fileNum};
			%
			% sigModSignalsAll = obj.sigModSignalsAll{obj.fileNum};
			% sigModIdx = 1;
			% sigModSignalsAllTmp = zeros([nSignals nIDs]);
			% for idIdx = 1:length(obj.stimulusNameArray)
			% 	[stimVector] = modelGetStim(obj,idArray(idIdx));
			% 	if ~isempty(stimVector)
			% 		sigModSignalsAllTmp(:,idIdx) = obj.ttestSignSignals{obj.fileNum,idIdx};
			% 		sigModIdx = sigModIdx + 1;
			% 	end
			% end
			% sigModSignalsAll = sigModSignalsAllTmp;
			% sigModSignalsAll = logical(sigModSignalsAll);
			% sigModSignalsAll
			% =====================
			postStimulusTimeSeq = obj.postStimulusTimeSeq;
			postStimulusTimeSeq = -10:10;
			MICRON_PER_PIXEL = obj.MICRON_PER_PIXEL;
			% =====================
			nIDs = length(obj.stimulusNameArray);
			colorArray = hsv(nIDs);
			idNumCounter = 1;
			% =====================
			% calculate pairwise distances
			try
				xCoords = obj.objLocations{obj.fileNum}(valid,1);
				yCoords = obj.objLocations{obj.fileNum}(valid,2);
			catch
				[xCoords yCoords] = findCentroid(IcaFilters);
				% continue;
			end
			dist = pdist([xCoords(:) yCoords(:)]);
			npts = length(xCoords);
			% distanceMatrix = diag(realmax*ones(1,npts))+squareform(dist);
			distanceMatrix = diag(zeros(1,npts))+squareform(dist);
			% =====================
	     	[p,q] = meshgrid(idNumIdxArray, idNumIdxArray);
	     	idPairs = [p(:) q(:)];
	     	% idPairs = unique(sort(idPairs,2),'rows');
	     	% idPairs((idPairs(:,1)==idPairs(:,2)),:) = []
			nIDs = length(idArray);
			% colorArray = hsv(nIDs);
			nPairs = size(idPairs,1);
			% =====================
			% idPairs
			for idPairNum = 1:nPairs
				try
					idNum1 = idPairs(idPairNum,1);
					idNum2 = idPairs(idPairNum,2);
					% =====================
					display(repmat('=',1,7))
					display([num2str(idPairNum) '/' num2str(nPairs) ': analyzing ' nameArray{idNum1} ' | ' nameArray{idNum2}])
					% =====================
					% get stimulus vector
					[stimVector1] = modelGetStim(obj,idArray(idNum1));
					[stimVector2] = modelGetStim(obj,idArray(idNum2));
					% stimVector = output.stimVector;
					if isempty(stimVector1);continue;end;
					if isempty(stimVector2);continue;end;
					% =====================
					stimIdx1 = find(stimVector1);
					stimIdx1 = bsxfun(@plus,stimIdx1(:),postStimulusTimeSeq(:)');
					signalPeaksTmp1 = signalPeaks(:,stimIdx1);
					% IcaTracesTmp1 = IcaTraces(:,stimIdx1);
					signalPeaksTmp1 = alignSignal(signalPeaks,stimVector1,postStimulusTimeSeq,'returnFormat','perSignalStimResponseMean');
					% =====================
					stimIdx2 = find(stimVector2);
					stimIdx2 = bsxfun(@plus,stimIdx2(:),postStimulusTimeSeq(:)');
					signalPeaksTmp2 = signalPeaks(:,stimIdx2);
					% IcaTracesTmp2 = IcaTraces(:,stimIdx2);
					% distanceMatrixTmp = distanceMatrix;
					signalPeaksTmp2 = alignSignal(signalPeaks,stimVector2,postStimulusTimeSeq,'returnFormat','perSignalStimResponseMean');
					% =====================
					display('calculating Mahalanobis distance...')
					% mahalDistances = mahal(signalPeaksTmp2,signalPeaksTmp1);
					Y1 = nancov(signalPeaksTmp1);
					Y2 = nancov(signalPeaksTmp2);
					% size(Y1)
					% size(Y2)
					% size(signalPeaksTmp1)
					% size(signalPeaksTmp2)
					% D = pdist2(signalPeaksTmp1,signalPeaksTmp2,'mahalanobis',Y1).^2;
					D = pdist2(signalPeaksTmp1,signalPeaksTmp2,'euclidean');
					% size(D)
					mahalDistances = nanmean(nanmean(D));
					% D = pdist2(signalPeaksTmp2,signalPeaksTmp1,'mahalanobis',Y2);
					% size(D)
					% nanmean(nanmean(D))
					% pause
					% mahalDistances = nanmean(mahalDistances);
					% =====================
					numPtsToAdd = length(mahalDistances);
					metricLength = 1:length(mahalDistances);
					obj.detailStats.frame(end+1:end+numPtsToAdd,1) = metricLength(:);
					obj.detailStats.value(end+1:end+numPtsToAdd,1) = mahalDistances(:);
					obj.detailStats.stimulusRef(end+1:end+numPtsToAdd,1) = {nameArray{idNum1}};
					obj.detailStats.stimulusTest(end+1:end+numPtsToAdd,1) = {nameArray{idNum2}};
					obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subject};
					obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
					obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
					obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};


					display('calculating background Mahalanobis distance...')
					stimVector2 = zeros(1,length(stimVector2));
					stimVector2(randsample(length(stimVector2),20)) = 1;
					signalPeaksTmpBack = alignSignal(signalPeaks,stimVector2,postStimulusTimeSeq,'returnFormat','perSignalStimResponseMean');
					mahalDistances = mahal(signalPeaksTmpBack,signalPeaksTmp1);

					Y1 = nancov(signalPeaksTmp1);
					Y2 = nancov(signalPeaksTmpBack);
					D = pdist2(signalPeaksTmp1,signalPeaksTmpBack,'mahalanobis',Y1);
					mahalDistances = nanmean(nanmean(D));
					% mahalDistances = nanmean(mahalDistances);

					numPtsToAdd = length(mahalDistances);
					metricLength = 1:length(mahalDistances);
					obj.detailStats.frame(end+1:end+numPtsToAdd,1) = metricLength(:);
					obj.detailStats.value(end+1:end+numPtsToAdd,1) = mahalDistances(:);
					obj.detailStats.stimulusRef(end+1:end+numPtsToAdd,1) = {nameArray{idNum1}};
					obj.detailStats.stimulusTest(end+1:end+numPtsToAdd,1) = {'background'};
					obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subject};
					obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
					obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
					obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
			end

			% write out summary statistics
		 %    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_mahal.tab'];
		 %    display(['saving data to: ' savePath])
			% writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	% write out summary statistics
    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_mahal.tab'];
    display(['saving data to: ' savePath])
	writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
	obj.detailStats = [];
end