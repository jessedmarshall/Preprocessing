function obj = computeSpatioTemporalClustMetric(obj)
	% get centroid locations along with distance matrix
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

	display(repmat('#',1,21))
	display('starting spatio-temporal analysis')
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:length(fileIdxArray)
		thisFileNum = fileIdxArray(thisFileNumIdx);
		obj.fileNum = thisFileNum;
		display(repmat('=',1,21))
		display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
		% ============================
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		nIDs = length(obj.stimulusNameArray);
		nSignals = size(IcaTraces,1);
		% ============================
		% extract coordinates and make distance matrix
		try
			coords = obj.objLocations{obj.fileNum};
			xCoords = coords(:,1);
			yCoords = coords(:,2);
			% [xCoords yCoords] = findCentroid(IcaFilters);
		catch
			continue;
		end
		dist = pdist([xCoords(:) yCoords(:)]);
		npts = length(xCoords);
		distanceMatrix = diag(realmax*ones(1,npts))+squareform(dist);
		for idNum = 1:nIDs
			gfunction = [];
			gfunctionShuffledMean = [];
			gfunctionShuffledStd = [];
			% ============================
			sigModSignals = obj.sigModSignals{obj.fileNum,idNum};
			% ============================
			display(repmat('-',1,7))
			% display(['folder ' num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}])
			display(['stim ' num2str(idNum) '/' num2str(nIDs) ': ' obj.stimulusNameArray{idNum}])
			% calculate the G-function for each group
			miScoresGrouped = sigModSignals;
			uniqueGroups = unique(miScoresGrouped);
			nGroups = length(uniqueGroups);
			% uniqueGroups
			for groupNum=1:nGroups
			    groupId = uniqueGroups(groupNum);
			    groupIdx = find(miScoresGrouped==groupId);
				minDistances = min(distanceMatrix(groupIdx,groupIdx));
				% for i=1:ceil(max(dist))
				for i=1:50
					gfunction(i,groupNum)=sum(minDistances<=i)/length(minDistances);
				end
			end
			% get shuffled distributions
			nSignificantSignals = sum(miScoresGrouped);
			nShuffles = 20;
			distanceCutoff = 50;
			for shuffleNo=1:nShuffles
				groupIdx = randsample(nSignals,nSignificantSignals,false);
				minDistances = min(distanceMatrix(groupIdx,groupIdx));
				for i=1:distanceCutoff
					gfunctionShuffled(i,shuffleNo)=sum(minDistances<=i)/length(minDistances);
				end
			end
			gfunctionShuffledMean = mean(gfunctionShuffled,2);
			gfunctionShuffledStd = std(gfunctionShuffled,0,2);

			% ============================
			if isempty(gfunction)
				display('no significant values, adding blank...');
			end
			obj.distanceMetric{obj.fileNum,idNum} = gfunction;
			obj.distanceMetricShuffleMean{obj.fileNum,idNum} = gfunctionShuffledMean;
			obj.distanceMetricShuffleStd{obj.fileNum,idNum} = gfunctionShuffledStd;
			% ============================
		end
	end
end