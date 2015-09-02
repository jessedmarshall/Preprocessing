function obj = modelVerifyDataIntegrity(obj)
	% get information for each folder
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

	scnsize = get(0,'ScreenSize');
	signalExtractionMethodStr = {'movies_signals','duplicates'};
	[fileIdxArray, ok] = listdlg('ListString',signalExtractionMethodStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which signal extraction method?');
	analysisType = signalExtractionMethodStr{fileIdxArray};
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	switch analysisType
		case 'stimulusIndex'
			for idNumIdx = 1:length(idNumIdxArray)
				idNum = idNumIdxArray(idNumIdx);
				obj.stimNum = idNum;
				try
					% =====================
					display(repmat('=',1,7))
					display([num2str(idNum) '/' num2str(nIDs) ': analyzing ' nameArray{idNum}])

					% ===============================================================
					% obtain stimulus information
					idArray(idNum)
					stimVector = obj.modelGetStim(idArray(idNum));
					if isempty(stimVector); continue; end;
					framesToAlign = find(stimVector);
					% maxTrials = 100;
					if length(framesToAlign)>=maxTrials
						% framesToAlign = framesToAlign(1:20);
						framesToAlign = framesToAlign(randperm(length(framesToAlign),maxTrials));
					end
					nPoints = size(IcaTraces,2);
					timeVector = [-preOffset:postOffset];
					framesToAlign(find((framesToAlign<preOffset))) = [];
					framesToAlign(find((framesToAlign>(nPoints-postOffset)))) = [];
					[~, ~] = openFigure(776, '');
						options.videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
						vidList = getFileList(obj.videoDir,options.videoTrialRegExp);
						[xPlot yPlot] = getSubplotDimensions(length(framesToAlign));
						downsampleFactor = 4;
						length(framesToAlign)
						for trialNo = 1:length(framesToAlign)
							% subplot(xPlot,yPlot,trialNo)
							% behaviorMovie2 = loadMovieList(vidList,'convertToDouble',0,'frameList',bsxfun(@plus,framesToAlign(trialNo),0:2)*downsampleFactor,'treatMoviesAsContinuous',1);
							thisMovie1 = convertInputMovieToCell(loadMovieList(vidList,'convertToDouble',0,'frameList',bsxfun(@plus,framesToAlign(trialNo),-2:2)*downsampleFactor,'treatMoviesAsContinuous',1));
							thisMovie1 = cat(2,thisMovie1{:});
							imagesc(thisMovie1);
							ginput(1);
						end
						continue
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
			end
		case 'movies_signals'
			nFolders = length(obj.dataPath);
			for folderNo = 1:nFolders
				display('==========')
				display([num2str(folderNo) '/' num2str(nFolders) ': ' obj.dataPath{folderNo}])
				filesToLoad = getFileList(obj.dataPath{folderNo},'_ICfilters.mat');
				if isempty(filesToLoad)
					display(['missing ICs: ' obj.dataPath{folderNo}])
				end
				filesToLoad = getFileList(obj.dataPath{folderNo},'crop');
				if isempty(filesToLoad)
					display(['missing dfof: ' obj.dataPath{folderNo}])
					filesToLoad = getFileList(obj.dataPath{folderNo},'concat');
					[movieDims] = loadMovieList(filesToLoad,'getMovieDims',1);
					display(['raw movie length: ' num2str(sum(movieDims.z))]);
				else
					filesToLoad = getFileList(obj.dataPath{folderNo},'crop');
					[movieDims] = loadMovieList(filesToLoad,'getMovieDims',1);
					display(['processed movie length: ' num2str(movieDims.z)]);
				end
			end
		case 'duplicates'
			for thisSubjectStr=subjectList
				display(repmat('=',1,21))
				thisSubjectStr = thisSubjectStr{1};
				display(thisSubjectStr);

				validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
				% filter for folders chosen by the user
				validFoldersIdx = intersect(validFoldersIdx,fileIdxArray);
				if isempty(validFoldersIdx)
					continue;
				end
				subjAssays = obj.assay(validFoldersIdx);
				size(subjAssays)
				size(unique(subjAssays))
				[~,idx] = unique(subjAssays);
				subjAssays(setdiff(1:length(subjAssays),idx))
				validFoldersIdx(setdiff(1:length(subjAssays),idx))
			end
			return
			% body
		otherwise
			body
	end
	return
end