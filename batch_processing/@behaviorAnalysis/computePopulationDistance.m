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
			[IcaTraces IcaFilters signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj,'returnType','filtered','regexPairs',{
				{obj.rawICtracesSaveStr}});
			signalPeaks = IcaTraces;
			nIDs = length(obj.stimulusNameArray);
			nSignals = size(IcaTraces,1);
			% if isempty(IcaFilters);continue;end;
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
			% postStimulusTimeSeq = -10:10;
			% postStimulusTimeSeq = 0:10;
			postStimulusTimeSeq = -30:0;
			MICRON_PER_PIXEL = obj.MICRON_PER_PIXEL;
			% =====================
			nIDs = length(obj.stimulusNameArray);
			colorArray = hsv(nIDs);
			idNumCounter = 1;
			% =====================
			% calculate pairwise distances
			% try
			% 	xCoords = obj.objLocations{obj.fileNum}(valid,1);
			% 	yCoords = obj.objLocations{obj.fileNum}(valid,2);
			% catch
			% 	[xCoords yCoords] = findCentroid(IcaFilters);
			% 	% continue;
			% end
			% dist = pdist([xCoords(:) yCoords(:)]);
			% npts = length(xCoords);
			% % distanceMatrix = diag(realmax*ones(1,npts))+squareform(dist);
			% distanceMatrix = diag(zeros(1,npts))+squareform(dist);
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
					obj.stimNum = idNum1;
					[stimVector1] = modelGetStim(obj,idArray(idNum1));
					obj.stimNum = idNum2;
					[stimVector2] = modelGetStim(obj,idArray(idNum2));
					% stimVector = output.stimVector;
					if isempty(stimVector1);continue;end;
					if isempty(stimVector2);continue;end;
					% =====================
					[popDistance] = getPopulationDistance(stimVector1,stimVector2,signalPeaks,postStimulusTimeSeq);
					% popDistance = pdist2(signalPeaksTmp1,signalPeaksTmp2,'euclidean');
					% size(popDistance)
					mahalDistances = nanmean(nanmean(popDistance))
					% popDistance = pdist2(signalPeaksTmp2,signalPeaksTmp1,'mahalanobis',Y2);
					% size(popDistance)
					% nanmean(nanmean(popDistance))
					% pause
					% mahalDistances = nanmean(mahalDistances);
					% =====================
					mahalDistancesStr = {'original','shuffled'};
					for distanceTypeNo = 1:length(mahalDistancesStr)
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
					end


					display('calculating background Mahalanobis distance...')
					nStimVector2 = sum(stimVector2);
					stimVector2 = zeros(1,length(stimVector2));
					stimVector2(randsample(length(stimVector2),nStimVector2)) = 1;
					sum(stimVector2)
					[popDistance] = getPopulationDistance(stimVector1,stimVector2,signalPeaks,postStimulusTimeSeq);
					% stimIdxBack = find(stimVector2);
					% stimIdxBack = bsxfun(@plus,stimIdxBack(:),postStimulusTimeSeq(:)');
					% signalPeaksTmpBack = signalPeaks(:,stimIdxBack)';
					% % signalPeaksTmpBack = alignSignal(signalPeaks,stimVector2,postStimulusTimeSeq,'returnFormat','perSignalStimResponseMean');
					% % mahalDistances = mahal(signalPeaksTmpBack,signalPeaksTmp1);

					% Y1 = nancov(signalPeaksTmp1);
					% Y2 = nancov(signalPeaksTmpBack);
					% popDistance = pdist2(signalPeaksTmp1,signalPeaksTmpBack,'mahalanobis');
					% mahalDistances = nanmean(nanmean(popDistance))
					mahalDistances = nanmean(popDistance(:))
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

%% functionname: function description
function [popDistance] = getPopulationDistance(stimVector1,stimVector2,signalPeaks,postStimulusTimeSeq)
		nTimePts = size(signalPeaks,2);

		stimIdx1 = find(stimVector1);
		stimIdx1 = bsxfun(@plus,stimIdx1(:),postStimulusTimeSeq(:)');
		stimIdx1(stimIdx1>nTimePts) = [];
		stimIdx1 = stimIdx1';
		% size(stimIdx1(:))
		% stimIdx1(:)
		signalPeaksTmp1 = signalPeaks(:,stimIdx1(:));
		% size(signalPeaksTmp1)
		% IcaTracesTmp1 = IcaTraces(:,stimIdx1);
		% perStimSignalResponse perSignalStimResponseMean
		% signalPeaksTmp1 = alignSignal(signalPeaks,stimVector1,postStimulusTimeSeq,'returnFormat','perStimSignalResponse');
		% =====================
		stimIdx2 = find(stimVector2);
		stimIdx2 = bsxfun(@plus,stimIdx2(:),postStimulusTimeSeq(:)');
		stimIdx2(stimIdx2>nTimePts) = [];
		stimIdx2 = stimIdx2';
		signalPeaksTmp2 = signalPeaks(:,stimIdx2(:));
		% IcaTracesTmp2 = IcaTraces(:,stimIdx2);
		% distanceMatrixTmp = distanceMatrix;
		% perStimSignalResponse perSignalStimResponseMean
		% signalPeaksTmp2 = alignSignal(signalPeaks,stimVector2,postStimulusTimeSeq,'returnFormat','perStimSignalResponse');
		% =====================
		display('calculating Mahalanobis distance...')
		% mahalDistances = mahal(signalPeaksTmp2,signalPeaksTmp1);
		individualDistanceMethod=0
		if individualDistanceMethod==1
			nCol1 = size(signalPeaksTmp1,2);
			nCol2 = size(signalPeaksTmp2,2);
			[p,q] = meshgrid(1:nCol1, 1:nCol2);
	     	idPairs = [p(:) q(:)];
			nIDs = length(idArray);
			nPairs = size(idPairs,1);
			reverseStr = '';
			for idPairNum = 1:nPairs
				idNum1 = idPairs(idPairNum,1);
				idNum2 = idPairs(idPairNum,2);
				refVector = signalPeaksTmp1(:,idNum1);
				sampleVector = signalPeaksTmp2(:,idNum2);
				refVectorCov = nancov(refVector);
				size(refVector)
				size(sampleVector)
				size(refVectorCov)
				refVectorCov
				% popDistance(idPairNum) = pdist2(refVector(:),sampleVector(:),'mahalanobis',refVectorCov(:));
				popDistance(idPairNum) = pdist2(refVector(:),sampleVector(:),'mahalanobis');
				reverseStr = cmdWaitbar(idPairNum,nPairs,reverseStr,'inputStr','calculating mahalanobis distance','waitbarOn',1,'displayEvery',5);
			end
		end
		individualDistanceMethod2=1
		if individualDistanceMethod2==1
			signalPeaksTmp1 = signalPeaksTmp1';
			signalPeaksTmp2 = signalPeaksTmp2';
			nObservations1 = size(signalPeaksTmp1,1);
			nObservations2 = size(signalPeaksTmp2,1);
			% sampleVector = signalPeaksTmp2;
			imagesc(signalPeaksTmp1);colorbar
			% var()
			% pause
			covX = nancov(signalPeaksTmp1);
			svdx = svd(signalPeaksTmp1);
			condx = cond(signalPeaksTmp1);
			rankx = rank(signalPeaksTmp1)
			rankdef = min(size(signalPeaksTmp1)) -rankx
			% covX = nearestSPD(covX);
			size(covX)
			[~,p] = chol(covX)
			reverseStr = '';
			size(signalPeaksTmp1)
			size(signalPeaksTmp2(1,:))
			for obsNo = 1:nObservations2
				popDistance(:,obsNo) = pdist2(signalPeaksTmp1,signalPeaksTmp2(obsNo,:),'mahalanobis',covX);

				% popDistance = mahal(signalPeaksTmp2(obsNo,:),signalPeaksTmp1);

				% X = signalPeaksTmp1;
				% Y = signalPeaksTmp2(obsNo,:);
				% S = cov(X);
				% mu = mean(X,1);
				% popDistance = (Y-mu)*inv(S)*(Y-mu)';
				% d = ((Y-mu)/S)*(Y-mu)'; % <-- Mathworks prefers this way

				reverseStr = cmdWaitbar(obsNo,nObservations2,reverseStr,'inputStr','calculating mahalanobis distance','waitbarOn',1,'displayEvery',5);
			end
			% popDistance
			% imagesc(popDistance); colorbar
		end
		individualDistanceMethod3 = 0
		if individualDistanceMethod3==1
			signalPeaksTmp1 = signalPeaksTmp1';
			signalPeaksTmp2 = signalPeaksTmp2';
			Y1 = nancov(signalPeaksTmp1);
			Y2 = nancov(signalPeaksTmp2);
			figure(1)
			colormap gray;
			subplot(2,2,1)
			imagesc(Y1);colorbar;
			% size(Y1)
			% size(Y2)
			% size(signalPeaksTmp1)
			% size(signalPeaksTmp2)
			% mahalDistances = nanmean(popDistance(:));
			% size(signalPeaksTmp1)
			% size(signalPeaksTmp2)
			% size(Y1)
			% Y1 = Y1.*Y1';
			Y1 = nearestSPD(Y1);
			[~,p] = chol(Y1)
			% size(Y1)
			% size(signalPeaksTmp1)
			popDistance = pdist2(signalPeaksTmp1,signalPeaksTmp2,'mahalanobis',Y1);
			% popDistance = pdist2(signalPeaksTmp1,signalPeaksTmp2,'seuclidean');
			% popDistance = pdist2(signalPeaksTmp1,signalPeaksTmp2,'euclidean');
			% size(popDistance)
			figure(1)
			colormap gray;
			subplot(2,2,1)
			imagesc(signalPeaksTmp1);
			colorbar
			subplot(2,2,2)
			imagesc(signalPeaksTmp2)
			colorbar
			subplot(2,2,3)
			imagesc(popDistance)
			colorbar
			subplot(2,2,4)
			trueRowNo = 1;
			colLength = size(popDistance,2);
			winLength = length(postStimulusTimeSeq);
			for row1No = 1:size(popDistance,1)
				rowMask = NaN([1 colLength]);
				% row1No:winLength:colLength
				rowMask(trueRowNo:winLength:colLength) = 1;
				popDistance(row1No,:) = popDistance(row1No,:).*rowMask(:)';
				% mod(row1No,winLength)
				if mod(row1No,winLength)==0
					trueRowNo = 1;
				else
					trueRowNo = trueRowNo+1;
				end
			end
			imagesc(popDistance)
			colorbar
		end
		% pause
end