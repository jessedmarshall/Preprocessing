function obj = modelExtractSignalsFromMovie(obj)
% remove PCAs in a particular region or exclude from preprocessing, etc.

	scnsize = get(0,'ScreenSize');
	signalExtractionMethodStr = {'PCAICA','ROI','EM'};
	signalExtractionMethodDisplayStr = {'PCAICA','ROI - only run if have ICA or EM images','EM'};
	[fileIdxArray, ok] = listdlg('ListString',signalExtractionMethodDisplayStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which signal extraction method?');
	signalExtractionMethod = signalExtractionMethodStr{fileIdxArray};

	if strcmp(signalExtractionMethod,'PCAICA')
		% create expected PC/ICs signal structure if doesn't already exist
		subjectList = unique(obj.subjectStr);
		if isempty(obj.numExpectedSignals)
			for subjectNum = 1:length(subjectList)
				obj.numExpectedSignals.(subjectList{subjectNum}) = [];
			end
		end

		% create default [PCs ICs] list else empty
		defaultList = {};
		for subjectNum = 1:length(subjectList)
			if ~isempty(obj.numExpectedSignals.(subjectList{subjectNum}))
				defaultList{subjectNum} = num2str(obj.numExpectedSignals.(subjectList{subjectNum}));
			else
				defaultList{subjectNum} = '';
			end
		end

		% ask user for nPCs/ICs
		numExpectedSignalsArray = inputdlg(subjectList,'number of PCs/ICs to use [PCs ICs]',[1 100],defaultList);
		for subjectNum = 1:length(subjectList)
			obj.numExpectedSignals.(subjectList{subjectNum}) = str2num(numExpectedSignalsArray{subjectNum})
		end
	end

	% request folders to analyze, else do all of them
	% if obj.guiEnabled==1
	% 	scnsize = get(0,'ScreenSize');
	% 	[fileIdxArray, ok] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
	% else
	% 	if isempty(obj.foldersToAnalyze)
	% 		fileIdxArray = 1:length(obj.fileIDNameArray);
	% 	else
	% 		fileIdxArray = obj.foldersToAnalyze;
	% 	end
	% end
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	nFolders = length(fileIdxArray);
	for thisFileNumIdx = 1:length(fileIdxArray)
		try
			startTime = tic;
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			display(repmat('=',1,21))
			% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.fileIDNameArray{obj.fileNum}]);
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
			%
			fileFilterRegexp = obj.fileFilterRegexp;

			switch signalExtractionMethod
				case 'ROI'
					runROISignalFinder();
				case 'PCAICA'
					runPCAICASignalFinder();
				case 'EM'
					runEMSignalFinder();
				otherwise
					% body
			end
			toc(startTime)
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	function runROISignalFinder()
		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
		[inputMovie thisMovieSize Npixels Ntime] = loadMovieList(movieList);

		[inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw_images');
		[ROItraces] = applyImagesToMovie(inputImages,inputMovie);
		clear inputMovie inputImages;
		[figHandle figNo] = openFigure(1, '');
			ROItracesTmp = ROItraces;
			ROItracesTmp(ROItracesTmp<0.1) = 0;
			imagesc(ROItracesTmp);
			ylabel('filter number');xlabel('frame');
			colormap(obj.colormap);colorbar;
			title(obj.fileIDNameArray{obj.fileNum})
			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 30 10])
			obj.modelSaveImgToFile([],'ROItraces_','current',obj.fileIDArray{obj.fileNum});

		tracesSaveDimOrder = '[signalNo frameNo]';
		saveID = {obj.rawROItracesSaveStr}
		saveVariable = {'ROItraces'}
		thisDirSaveStr = [obj.inputFolders{obj.fileNum} filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			save(savestring,saveVariable{i},'tracesSaveDimOrder');
		end
	end

	function runPCAICASignalFinder()
		nPCsnICs = obj.numExpectedSignals.(obj.subjectStr{obj.fileNum})
		nPCs = nPCsnICs(1);
		nICs = nPCsnICs(2);
		%
		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
		% [inputMovie] = loadMovieList(movieList,'convertToDouble',0,'frameList',[]);

		[PcaFilters PcaTraces] = runPCA(movieList, '', nPCs, fileFilterRegexp);

		if isempty(PcaTraces)
			display('PCs are empty, skipping...')
		else
			display('+++')
			[IcaFilters IcaTraces] = runICA(PcaFilters, PcaTraces, '', nICs, '');
			% reorder if needed
			options.IcaSaveDimOrder = 'zxy';
			if strcmp(options.IcaSaveDimOrder,'xyz')
				IcaFilters = permute(IcaFilters,[2 3 1]);
				imageSaveDimOrder = 'xyz';
			else
				imageSaveDimOrder = 'zxy';
			end
			% save ICs
			options.rawICfiltersSaveStr = '_ICfilters.mat';
			options.rawICtracesSaveStr = '_ICtraces.mat';
			saveID = {options.rawICfiltersSaveStr,options.rawICtracesSaveStr}
			saveVariable = {'IcaFilters','IcaTraces'}
			thisDirSaveStr = [obj.inputFolders{obj.fileNum} filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
			for i=1:length(saveID)
				savestring = [thisDirSaveStr saveID{i}];
				display(['saving: ' savestring])
				save(savestring,saveVariable{i},'imageSaveDimOrder','nPCs','nICs');
			end
		end
	end
	function runEMSignalFinder()
		oldEM = 0;
		if oldEM==1
			% load the PC filters and traces
			filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
			for i=1:length(filesToLoad)
				display(['loading: ' filesToLoad{i}]);
				load(filesToLoad{i})
			end

			[thisMovie thisMovieSize Npixels Ntime] = loadMovieList(movieList);
			display('removing NaNs...');drawnow
			thisMovie(isnan(thisMovie)) = 0;
			inputOptions.normalizationType = 'imfilter';
			thisMovie = normalizeMovie(thisMovie,'options',inputOptions);

			display(['class: ' class(thisMovie) ' | min: ' num2str(min(min(min(thisMovie)))) ' | max: ' num2str(max(max(max(thisMovie)))) ' | dims: ' num2str(size(thisMovie))])
			% pause()

			emOptions.suppressProgressFig = options.EM.suppressProgressFig;
			emOptions.suppressOutput = options.EM.suppressOutput;
			if ~isempty(IcaFilters)
				display('removing IC NaNs...');drawnow
				IcaFilters(isnan(IcaFilters)) = 0;
				emOptions.icImgs = permute(IcaFilters,[2 3 1]);
				display(['dims ica filters: ' num2str(size(emOptions.icImgs))])
				emOptions.icTraces = IcaTraces;
			end
			emOptions.initWithICsOnly = 1;

			% [emAnalysis.allCellImages, emAnalysis.allCellTraces, emAnalysis.allCellParams, emAnalysis.noiseSigma, emAnalysis.eventTimes, emAnalysis.eventTrigImages] = EM_main(thisMovie, options.EM.analysisFramerate, options.EM.analysisPixelSize, options.EM.sqSize,emOptions);

			% [emAnalysis.allCellImages, emAnalysis.allCellTraces, emAnalysis.allCellParams, emAnalysis.noiseSigma, emAnalysis.eventTimes, emAnalysis.eventTrigImages] = EM_main(thisMovie, options.EM.analysisFramerate, options.EM.analysisPixelSize, options.EM.sqSize,emOptions);
		end

		% emOptions.dsMovieDatasetName = options.datasetName;
		% emOptions.movieDatasetName = options.datasetName;
		movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);

		% emOptions.dsMovieFilename='/Users/Lacey/Data/dsDFOF.h5';
		emOptions.dsMovieDatasetName=obj.inputDatasetName;
		emOptions.useParallel = 1;
		emOptions.useOldEventDetect = 2; %don't use any event detection, do that later
		% emOptions.EMoptions.initMethod = 'ica';
		emOptions.dsFactor=obj.DOWNSAMPLE_FACTOR;
		emOptions.eventOptions.framerate=obj.FRAMES_PER_SECOND;
		emOptions.EMoptions.minIters = 10;
		emOptions.EMoptions.gridSpacing=7; % spacing of initialization grid, in pixels
		emOptions.EMoptions.gridWidth=8;
		emOptions.EMoptions.inputSizeManual = 0;
		emOptions.EMoptions.maxSqSize = 60;
		emOptions.EMoptions.sqOverlap = 10;

		movieFilename=[];

		% upsampledMovieList = getFileList(thisDir, fileFilterRegexp);
		[emAnalysisOutput, ~] = EM_CellFind_Wrapper(movieList{1},[],'options',emOptions);

		% output.cellImages : images representing sources found (candidate cells). not all will be cells. Size is [x y numCells]
		% output.centroids : centroids of each cell image, x (horizontal) and then y (vertical). Size is [numCells 2]
		% output.convexHulls : convex hull (line tracing around edge) of each cell, in x then y. Cell Array, Size is [numCells 1], each entry is hull of one cell.
		% output.dsEventTimes : event timings on the down sampled probability traces.
		% output.dsScaledProbabilities : a scaled probability trace for each cell, from the downsampled movie. Can be used as a denoised fluorescence trace.
		% output.dsCellTraces : fluorescence traces for each cell, from the temporally downsampled movie. Size is [numCells numFrames] for numFrames of downsampled movie
		% output.cellTraces : fluorescence traces for each cell, from the full temporal resolution movie. Size is [numCells numFrames] for numFrames of full movie
		% output.eventTimes : event timings as output by detectEvents.
		% output.EMoptions : options that EM was run with. Good to keep for recordkeeping purposes.


		% save ICs
		saveID = {obj.rawEMStructSaveStr};
		saveVariable = {'emAnalysisOutput'};
		thisDirSaveStr = [obj.inputFolders{obj.fileNum} filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			% save(savestring,saveVariable{i},'-v7.3','emOptions');
			save(savestring,saveVariable{i},'emOptions');
		end
	end
end