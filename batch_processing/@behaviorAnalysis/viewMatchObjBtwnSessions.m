function obj = viewMatchObjBtwnSessions(obj)
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

		% for folderNo = 1:length(obj.dataPath)
		% 	filesToLoad = getFileList(obj.dataPath{folderNo},'_ICfilters.mat');
		% 	if isempty(filesToLoad)
		% 		display(['missing ICs: ' obj.dataPath{folderNo}])
		% 	end
		% 	filesToLoad = getFileList(obj.dataPath{folderNo},'crop');
		% 	if isempty(filesToLoad)
		% 		display(['missing dfof: ' obj.dataPath{folderNo}])
		% 	end
		% end
		% return

	nFiles = length(obj.rawSignals);
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	subjectList = unique(obj.subjectStr(fileIdxArray));
	[xPlot yPlot] = getSubplotDimensions(length(subjectList));
	length(subjectList)
	thisFigNo = 1;
	for thisSubjectStr=subjectList
		thisSubjectStr = thisSubjectStr{1};
		[~, ~] = openFigure(thisFigNo, '');
			subplot(xPlot,yPlot,find(strcmp(thisSubjectStr,subjectList)));
			title(thisSubjectStr)
	end
	drawnow

	for thisSubjectStr=subjectList
		try
			display(repmat('=',1,21))
			thisSubjectStr = thisSubjectStr{1};
			display(thisSubjectStr);
			%
			[~, ~] = openFigure(thisFigNo, '');
				subplot(xPlot,yPlot,find(strcmp(thisSubjectStr,subjectList)));
				title(thisSubjectStr)
			%
			%
			inputSignals = {};
			inputImages = {};
			globalIDsTmp = obj.globalIDs.(thisSubjectStr);
			globalIDFolders = obj.globalIDFolders.(thisSubjectStr);
			globalIDs = [];
			validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
			% filter for folders chosen by the user
			validFoldersIdx = intersect(validFoldersIdx,fileIdxArray);
			% % remove folders that were not in alignment
			% validAssayIdx = find(strcmp(assayTypeList{assayTypeNo},obj.assayType));
			% % filter for folders chosen by the user
			% validAssayIdx = intersect(validFoldersIdx,validAssayIdx);
			%
			if isempty(validFoldersIdx)
				continue;
			end
			addNo = 1;
			for idx = 1:length(validFoldersIdx)
			% for idx = 1:2
				obj.fileNum = validFoldersIdx(idx);
				display(repmat('*',1,7))
				display([num2str(idx) '/' num2str(length(validFoldersIdx)) ': ' obj.fileIDNameArray{obj.fileNum}]);
				folderGlobalIdx = find(strcmp(obj.assay(obj.fileNum),globalIDFolders));
				if isempty(folderGlobalIdx)
					display('skipping...')
					continue
				end
				% obj.folderBaseSaveStr{obj.fileNum}
				% [rawSignalsTmp rawImagesTmp signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
				try
					[rawSignalsTmp rawImagesTmp signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filteredAndRegistered');
				catch
					continue
				end
				if ~isempty(rawSignalsTmp)
					inputSignals{end+1} = rawSignalsTmp;
					inputImages{end+1} = rawImagesTmp;
				end

				% globalIDFolders
				% obj.assay(obj.fileNum)
				folderGlobalIdx
				globalIDs(:,addNo) = globalIDsTmp(:,folderGlobalIdx);
				% globalIDCoords{idx} = obj.globalIDCoords.(thisSubjectStr){folderGlobalIdx};
				addNo = addNo + 1;
			end
			display(['global: ' num2str(size(globalIDs))])

			[~, ~] = openFigure(thisFigNo, '');
			% [xPlot yPlot] = getSubplotDimensions(length(subjectList));
			subplot(xPlot,yPlot,find(strcmp(thisSubjectStr,subjectList)));
				plotGlobalOverlap(inputImages,inputSignals,globalIDs,obj.globalIDCoords.(thisSubjectStr).globalCoords);
				title(thisSubjectStr)
				% box off
			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 20 10])
			obj.modelSaveImgToFile([],'globalOverlap','current',[]);
			continue;

			[matchedObjMaps euclideanStruct] = displayMatchingObjs(inputImages,globalIDs,'inputSignals',inputSignals,'globalIDCoords',obj.globalIDCoords.(thisSubjectStr).globalCoords);

			% % fileIdxArray = round(quantile(1:length(validFoldersIdx),0.5));
			% fileIdxArray = 1;
			% alignmentStruct = matchObjBtwnTrials(rawImages,'inputSignals',rawSignals,'trialToAlign',fileIdxArray,'additionalAlignmentImages',additionalAlignmentImages);
			% obj.globalIDs.(thisSubjectStr) = alignmentStruct.globalIDs;
			% obj.globalIDCoords.(thisSubjectStr) = alignmentStruct.coords;
			% % obj.globalIDImages.(thisSubjectStr) = alignmentStruct.inputImages;
			% obj.objectMapTurboreg.(thisSubjectStr) = alignmentStruct.objectMapTurboreg;
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	function plotGlobalOverlap(inputImages,inputSignals,globalIDs,globalIDCoords)
		if ~isempty(globalIDCoords)
		    % globalIDCoords = options.globalIDCoords;
		    nGlobals = size(globalIDs,1);
		    nObjPerGlobal = sum(globalIDs>0,2);
		    cropSize = 10;
		    globalOverlapImages = [];
		    reverseStr = '';
		    % thresholdImages(inputImages,'binary',1,'waitbarOn',0);
		    for globalNo = 1:nGlobals
		        nMatchedIDs = sum(globalIDs(globalNo,:)~=0);
		        if nMatchedIDs<2
		        	globalOverlapImages(:,:,globalNo) = NaN([2*cropSize+1 2*cropSize+1]);
		        	continue;
		        end
		        coords = globalIDCoords(globalNo,:);
		        xCoords = coords(1);
		        yCoords = coords(2);
		        [groupImages matchedSignals] = getGlobalData(inputImages,globalIDs,inputSignals,globalNo);
		        groupImages = squeeze(nansum(thresholdImages(groupImages,'binary',1,'waitbarOn',0),1))/nMatchedIDs*100;
		        % movieDims = size(inputMovie);
		        xLow = floor(xCoords - cropSize);
		        xHigh = floor(xCoords + cropSize);
		        yLow = floor(yCoords - cropSize);
		        yHigh = floor(yCoords + cropSize);
		        % % check that not outside movie dimensions
		        % xMin = 0;
		        % xMax = movieDims(2);
		        % yMin = 0;
		        % yMax = movieDims(1);
		        % % adjust for the difference in centroid location if movie is cropped
		        % xDiff = 0;
		        % yDiff = 0;
		        % if xLow<xMin xDiff = xLow-xMin; xLow = xMin; end
		        % if xHigh>xMax xDiff = xHigh-xMax; xHigh = xMax; end
		        % if yLow<yMin yDiff = yLow-yMin; yLow = yMin; end
		        % if yHigh>yMax yDiff = yHigh-yMax; yHigh = yMax; end
		        try
		            globalOverlapImages(:,:,globalNo) = groupImages(yLow:yHigh,xLow:xHigh);
		        catch
		            globalOverlapImages(:,:,globalNo) = NaN([2*cropSize+1 2*cropSize+1]);
		        end
		        reverseStr = cmdWaitbar(globalNo,nGlobals,reverseStr,'inputStr','getting global overlaps','displayEvery',5);
		    end
		    % playMovie(globalOverlapImages);
		    % [~, ~] = openFigure(thisFigNo, '');
		    	globalOverlapImages = squeeze(nanmean(globalOverlapImages,3));
		    	globalOverlapImages(1,1) = 0;
		    	globalOverlapImages(1,2) = 100;
		        imagesc(globalOverlapImages);
		        colormap(customColormap([]));
		        % title('heatmap of percent overlap object maps')
		        colorbar
		end
	end
end
function [groupImages matchedSignals] = getGlobalData(inputImages,globalIDs,inputSignals,globalNo)
    matchIDList = globalIDs(globalNo,:);
    matchIDIdx = matchIDList~=0;
    nMatchGlobalIDs = sum(matchIDIdx);
    if ~isempty(inputSignals)
        % get max length
        [nrows, ncols] = cellfun(@size, inputSignals);
        maxCols = max(ncols);
        matchedSignals = zeros(length(inputSignals),maxCols);
    end

    idxNo = 1;
    for j=1:length(inputImages)
        iIdx = globalIDs(globalNo,j);
        if iIdx==0
            nullImage = NaN(size(squeeze(inputImages{1}(1,:,:))));
            nullImage(1,1) = 1;
            groupImages(j,:,:) = nullImage;
        else
            % size(inputImages{j})
            % iIdx
            try
                groupImages(j,:,:) = squeeze(inputImages{j}(iIdx,:,:));
            catch
                display([num2str(j) ',' num2str(iIdx)])
            end
            if ~isempty(inputSignals)
                iSignal = inputSignals{j}(iIdx,:);
                matchedSignals(j,1:length(iSignal)) = iSignal;
            end
            idxNo = idxNo + 1;
        end
    end
end