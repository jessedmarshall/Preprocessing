function [outputStruct] = controllerAnalysis(runArg, folderListInfo, varargin)
	% batch wrapper function to control cell/trace finding, secondary trial analysis, and other analysis.
	% biafra ahanonu
	% started: 2013.10.09
	%
	% inputs
		% runArg - what analysis do yo want run?
		% folderListInfo - can be one of two things
			% path to folderList text file with newline for each file to analyze
			% structure with cell array fields for each file of: folderList, nPCs, nICs,fileFilterRegexp
				% e.g. folderList = {'path' 'path'}; nPCs = {700 700}; nICs = {500 500}; fileFilterRegexp = {'' ''}
		% folder to analyze
		% nPCs - number of starting PCs
		% runID - ID for this run, e.g. p92 for experiment 92
		% concatID - regexp for the split concat files
	% outputs
		% outputStruct - structure containing several fields that are sorted into cell arrays, each array containing information for the folder that was run
	% changelog
		% updated: 2013.10.xx
			% the controller now does the saving instead of the PCA/ICA and other functions, this is better from a compatibility standpoint
		% updated: 2013.11.04 [13:28:03]
			% altered how files are saved so it is more consistent and easier to change without problems arising
		% 2013.11.20 [21:23:42] haven't updated changelog in awhile, but here are some updates. It now looks for a tmpDecisions file in the directory in case the last run failed, you can load back where you started. There is now a ICApplyDecisions applet that can apply decisions to traces and filters. Several stability enhancements to check for empty directories and such.
		% 2013.11.23 [19:02:19] sometime this week...can now load old decisions into ICAChooser
		% 2013.11.24 [17:50:32] refactored code so now a bunch of sub-functions...(Need to convert runArg switch so it calls sub-functions instead of having an obnoxiously large switch-end. Easier to debug/maintain.)
		% 2013.12.02 [17:45:23] misc
		% 2013.12.16 [00:47:43] started integrating Lacey's EM code via a couple new wrappers. Hopefully can load the cell images and traces straight into the signalSorter without much modification.
	% TODO
		% Namespace (or package) everything. e.g. +gantis for the folder and gantis.controllerAnalysis for calling the main function. This would require an afternoon of refactoring all the functions to call the new namespaced functions. Might be worth it in the long run if compatability with other people's code is an issue.
		% Fix calling of sub-functions, currently not the most elegant design...
		% Make chunk size in EM scripts dynamic...

	% load necessary functions
	loadBatchFxns();
	% remove pre-compiled functions
	clear FUNCTIONS;
	%========================
	% old way of saving, only temporary until full switch
	options.oldSave = 0;
	% for future compatibility, add the feature to load options for project
	options.loadSettings = 0;
	options.nPCs = [];
	options.nICs = [];
	options.runID = '';
	options.protocol = '';
	options.fileFilterRegexp = 'concatenated_.*.h5';
	% number of frames to use in loaded movies, [] = use all frames
	options.frameList = [1:500];
	% name of the hierarchy in the hdf5 file
	options.datasetName = '1';
	% max size of chunk when doing large-scale analysis, in MBytes
	options.maxChunkSize = 10000;
	% hz of the movies used in analysis
	options.analysisFramerate = 5;
	% microns per pixel for analysis
	options.analysisPixelSize = 2.37;
	% size of a square chunck in Lacey's EM script, THIS SHOULD BE MADE DYNAMIC!!!
	options.sqSize = 30;
	options.emSaveRaw = '_emAnalysis';
	options.emSaveSorted = '_emAnalysis_sorted';
	% naming scheme for saved files
	options.rawPCfiltersSaveStr = '_PCAfilters.mat';
	options.rawPCtracesSaveStr = '_PCAtraces.mat';
	options.cleanedPCfiltersSaveStr = '_PCAfilters_sorted.mat';
	options.cleanedPCtracesSaveStr = '_PCAtraces_sorted.mat';
	options.rawICfiltersSaveStr = '_ICfilters.mat';
	options.rawICtracesSaveStr = '_ICtraces.mat';
	options.cleanedICfiltersSaveStr = '_ICfilters_sorted.mat';
	options.cleanedICtracesSaveStr = '_ICtraces_sorted.mat';
	options.cleanedICdecisionsSaveStr = '_ICdecisions.mat';
	options.neighborsSaveStr = '_neighbors.mat';
	% get options
	options = getOptions(options,varargin);
	display options
	options
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================
	% change handling depending on whether use gave a list of folders or a structure with info
	if strcmp(class(folderListInfo),'struct')
		outputStruct = folderListInfo;
	else
		outputStruct.null = nan;
	end
	%========================
	% read in the list of folders unless you have a structure with the info
	if strcmp(class(folderListInfo),'struct')
		nFiles = length(folderListInfo.folderList);
		folderList = folderListInfo;
	elseif strcmp(class(folderListInfo),'char')
		fid = fopen(folderListInfo, 'r');
		tmpData = textscan(fid,'%s','Delimiter','\n');
		folderList = tmpData{1,1};
		fclose(fid);
		nFiles = length(folderList);
	end
	%========================
	% get option from user
	if strcmp(runArg,'')
		controllerOptions = {'downsampleMovie','saveMovieTiff','compareEmLaceyToICA','pcaica','emLaceyAnalysis','emLaceySorter','emLaceyMovieView','pca','pcaChooser','ica','icaChooser','icaViewer','icaApplyDecisions','findSpikes','identifyNeighbors','compareSignalToMovie','convertToSpikeE','convertFromSpikeE', 'applyIcsMovie','cellmaps','playShortClip','getPeakToStdRelation'};
		[sel, ok] = listdlg('ListString',controllerOptions);
		% make sure selection chosen, else return
		if ok==0
			return
		end
		% select the option to run
		runArg = controllerOptions{sel};
	end
	display(runArg);
	%========================
	% loop over each folder (don't ask why it's called fileNum...)
	analysisStartTime = tic;
	for fileNum=1:nFiles
		commandwindow
		loopStartTime = tic;
		thisID = runID;

		% get information for this run
		[thisDir,nPCs,nICs,options] = getRunInformation(nFiles,folderList,folderListInfo,options,fileNum);

		% check if this directory has been commented out, if so, skip
		if strcmp(thisDir(1),'#')
			display('skipping...')
			continue;
		end

		% get list of movies
		movieList = getFileList(thisDir, options.fileFilterRegexp);
		% if only have filters, change what you look for, since you only want files to get information for the subject
		if isempty(movieList)
			movieList = getFileList(thisDir, rawICfiltersSaveStr);
		end

		% get the current directory and file info
		fileInfo = getFileInfo(movieList{1});
		% if user specifies protocol other than that found in the file
		if(exist('protocol','var')&~strcmp(protocol,''))
			fileInfo.protocol = protocol;
		end
		fileInfo
		% make save strings
		fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.subject '_' fileInfo.assay];
		if ~isempty(getFileList(thisDir, 'NULL000'))
			fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.subject '_' 'NULL000'];
		end
		thisDirSaveStr = [thisDir filesep fileInfoSaveStr '_' thisID];
		if oldSave==1
			thisDirSaveStr = [thisDir filesep thisID];
		end

		% outputStruct = cell2struct([struct2cell(outputStruct);struct2cell(fileInfo)]);
		outputStruct.subject{fileNum} = fileInfo.subject;
		outputStruct.assay{fileNum} = fileInfo.assay;

		% branch based on chosen option
		switch runArg
			% try
			case 'downsampleMovie'
				downsampleMovie(movieList,options)
			case 'saveMovieTiff'
				saveMovieTiff(movieList,options)
			case 'compareEmLaceyToICA'
				compareEmLaceyToICA(thisDir, thisDirSaveStr,thisID,fileInfo,options,movieList);
			case 'pcaica'
				PCAICA(thisDir, thisID, options.fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr);
			case 'emLaceyAnalysis'
				emLaceyAnalysis(thisDir, thisID, options.fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr);
			case 'emLaceySorter'
				emLaceySorter(thisDir, thisDirSaveStr,thisID,fileInfo,options);
			case 'emLaceyMovieView'
				emLaceyMovieView(thisDirSaveStr, options)
			case 'pca'
				% runPCA(thisDir, thisID, nPCs, fileFilterRegexp);
			case 'ica'
				% runICA(thisDir, thisID, days, nICs, '');
			case 'pcaChooser'
				PCAchooser(thisDir, thisID);
			case 'icaApplyDecisions'
				ICApplyDecisions(thisDirSaveStr,options);
			case 'icaChooser'
				ICAChooser(thisDir, thisDirSaveStr,thisID,fileInfo,options);
			case 'icaViewer'
				ICAChooser(thisDir, thisDirSaveStr,thisID,fileInfo,options,'viewer',1);
			case 'identifyNeighbors'
				[outputStruct] = identifyNeighbors(outputStruct,fileNum,thisDirSaveStr,options);
			case 'applyICsMovie'
				applyICsMovie(thisDir, thisID, options.fileFilterRegexp, '');
			case 'findSpikes'
				[outputStruct] = findSpikes(outputStruct, options, fileNum, nFiles, thisDirSaveStr);
			case 'compareSignalToMovie'
				compareSignalToMovie(thisDir, options.fileFilterRegexp,thisDirSaveStr,options);
			case 'convertToSpikeE'
				convertToSpikeE(thisDirSaveStr,options);
			case 'convertFromSpikeE'
				filterFilePath = [thisDirSaveStr '_ICfilters' '.mat'];
				traceFilePath = [thisDirSaveStr '_ICtraces' '.mat'];
				[filters, traces] = convertToSpikeE(filterFilePath, traceFilePath, 'fromSpikeE');
			case 'cellmaps'
				cellmaps(fileNum,nFiles,thisDir,thisDirSaveStr,options);
			case 'playShortClip'
				playShortClip(movieList,options);
			case 'getPeakToStdRelation'
				filesToLoad=strcat(thisDirSaveStr, {options.rawICtracesSaveStr});
				for i=1:length(filesToLoad)
					display(['loading: ' filesToLoad{i}]);
					load(filesToLoad{i})
				end
				[outputStruct.numSpikesVsStd{fileNum}] = getPeakToStdRelation(IcaTraces);
				numSpikes(:,fileNum) = outputStruct.numSpikesVsStd{fileNum};

				if fileNum==nFiles
					% numSpikes = reshape(cell2mat(outputStruct.numSpikesVsStd),[12 6]);
					figure(1111)
					subplot(1,2,1)
					plot(numSpikes);box off;
					title('std vs. num detected spikes');xlabel('std above baseline');ylabel('total number of spikes');
					subplot(1,2,2)
					plot(diff(numSpikes));box off;
					title('std vs. diff(num detected spikes)');xlabel('std above baseline');ylabel('diff(total number of spikes)');
					% legend(outputStruct.subject);
					drawnow;
				end
			otherwise
				display('Pick an option!');
		end
		toc(loopStartTime);
		% remove pre-compiled functions
		clear FUNCTIONS;
		% add controller directory and subdirectories to path
		addpath(genpath(pwd));
		% set default figure properties
		setFigureDefaults();
	end
	toc(analysisStartTime);
	commandwindow

	% path(pathdef);

function downsampleMovie(movieList,options)

	inputFilePath = movieList{1};

	downsampleHdf5Movie(inputFilePath, 'inputDatasetName', options.datasetName, 'maxChunkSize', options.maxChunkSize);

function saveMovieTiff(movieList,options)

	inputFilePath = movieList{1};
	options.movieType = 'hdf5';
	thisMovie = loadMovieList(movieList,'movieType',options.movieType);
	for i=1:length(thisMovie)
		imwrite(thisMovie(:,:,i),[inputFilePath(1:end-3) '.tif'],'WriteMode', 'append','Compression','none');
	end

function playShortClip(movieList,options)
	% plays a short clip

	movieList{1}

	% get the movie
	[thisMovie options] = getCurrentMovie(movieList,options);

	figure(564);playMovie(thisMovie,'fps',60);

function [thisMovie options] = getCurrentMovie(movieList,options)
	% get the list of movies to load

	[pathstr,name,ext] = fileparts(movieList{1});
	if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
		options.movieType = 'hdf5';
		% use the faster way to read in image data, especially if only need a subset
		if isempty(options.frameList)
			thisMovie = loadMovieList(movieList,'movieType',options.movieType);
		else
			inputFilePath = movieList{1};
			hinfo = hdf5info(inputFilePath);
			% hReadInfo = hinfo.GroupHierarchy.Datasets(1);
			datasetNames = {hinfo.GroupHierarchy.Datasets.Name};
			thisDatasetName = strmatch(options.datasetName,datasetNames);
			hReadInfo = hinfo.GroupHierarchy.Datasets(thisDatasetName);
			xDim = hReadInfo.Dims(1);
			yDim = hReadInfo.Dims(2);
			thisMovie = readHDF5Subset(inputFilePath,[0 0 options.frameList(1)-1],[xDim yDim length(options.frameList)-1],'datasetName',options.datasetName);
		end
    elseif strcmp(ext,'.tif')|strcmp(ext,'.tiff')
		options.movieType = 'tiff';
		thisMovie = loadMovieList(movieList,'movieType',options.movieType);
		% get substack if requested
		if isempty(options.frameList)
		else
			display('getting substack...');
			thisMovie = thisMovie(:,:,options.frameList);
		end
	end
	% movieList = {concatenated_2013_10_05_p111_m728_vonfrey1.h5'};
	% readHDF5Subset(inputFilePath,[0 0 0],[xDim yDim 1]);

function [thisDir,nPCs,nICs,options] = getRunInformation(nFiles,folderList,folderListInfo,options,fileNum)
	% obtains some information about the run given the name of the folder and other info
	% if folder is structure obtain from controllerProprocessMovie()
	if strcmp(class(folderListInfo),'struct')
		% [thisDir,~,~] = fileparts(folderListInfo.folderList{fileNum});
		thisDir = folderListInfo.folderList{fileNum};
		nPCs = folderListInfo.nPCs{fileNum};
		nICs = folderListInfo.nICs{fileNum};
		options.fileFilterRegexp = folderListInfo.fileFilterRegexp{fileNum};
	% if folder is from the text file
	elseif strcmp(class(folderListInfo),'char')
		thisDir = folderList{fileNum,1};
		% text file should be folderDir,nPCs,nICs
		dirInfo = regexp(folderList{fileNum,1},',','split');
		thisDir = dirInfo{1};
		if ~isempty(options.nPCs)
			% if user forces the PC/IC#s, ignore those given in the file
			nPCs = options.nPCs;
			nICs = options.nICs;
		elseif(length(dirInfo)>=2)
			% obtain the PC/IC#s from the text file
			nPCs = str2num(dirInfo{3});
			nICs = str2num(dirInfo{2});
		else
			% otherwise, use the default PC/ICs
			nPCs = options.nPCs;
			nICs = options.nICs;
		end
	end

	display('++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
	display([num2str(fileNum) '/' num2str(nFiles) ': ' thisDir]);
	% nPCs is 1.5*nExpectedCells, so nICs is 2/3 nPCs
	display(['number of PCs:' num2str(nPCs)]);
	display(['number of ICs:' num2str(nICs)]);

function compareEmLaceyToICA(thisDir, thisDirSaveStr,thisID,fileInfo,options,movieList)
	% compare IC to EM

	[thisMovie thisMovieSize Npixels Ntime] = loadMovieList(movieList);

	% load the PC filters and traces
	filesToLoad=strcat(thisDirSaveStr, {options.emSaveRaw,options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

	notZeroIdx = find(sum(emAnalysis.allCellTraces,2)>0);

	compareToICAresults(thisMovie, permute(IcaFilters, [2 3 1]), IcaTraces, emAnalysis.allCellImages(:,:,notZeroIdx), emAnalysis.allCellParams(notZeroIdx,:),emAnalysis.allCellTraces(notZeroIdx,:), 20, 1);


function emLaceyAnalysis(thisDir, thisID, fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr)
	% mini-wrapper to run Lacey's EM code
	%get the list of movies to load
	movieList = getFileList(thisDir, fileFilterRegexp);
	% skip if folder is empty
	if isempty(movieList)
		display('empty folder, skipping...')
		return;
	end

	[thisMovie thisMovieSize Npixels Ntime] = loadMovieList(movieList);

	['class: ' class(thisMovie) ' | min: ' num2str(min(min(min(thisMovie)))) ' | max: ' num2str(max(max(max(thisMovie))))]
	% pause()

	[emAnalysis.allCellImages, emAnalysis.allCellTraces, emAnalysis.allCellParams] = EM_main(thisMovie, options.analysisFramerate, options.analysisPixelSize, options.sqSize);

	% save ICs
	saveID = {options.emSaveRaw};
	saveVariable = {'emAnalysis'};
	for i=1:length(saveID)
		savestring = [thisDirSaveStr saveID{i}];
		display(['saving: ' savestring])
		save(savestring,saveVariable{i});
	end

function emLaceySorter(thisDir, thisDirSaveStr,thisID,fileInfo,options)
	% sorting of Lacey's output cells

	% load the PC filters and traces
	filesToLoad=strcat(thisDirSaveStr, {options.emSaveRaw});
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end
	% check if the folder has temporary decisions to load (e.g. if a crash occured)
	tmpDecisionList = getFileList(thisDir, 'tmpDecision');
	if(~isempty(tmpDecisionList))
		display(['loading temp decisions: ' tmpDecisionList{1}])
		load(tmpDecisionList{1});
	else
		valid = [];
	end

	notZeroIdx = find(sum(emAnalysis.allCellTraces,2)>0);

	[IcaFilters IcaTraces valid] = signalSorter(permute(emAnalysis.allCellImages(:,:,notZeroIdx),[3 1 2]), emAnalysis.allCellTraces(notZeroIdx,:), thisID, [],'inputStr',[' ' fileInfo.subject '\_' fileInfo.assay],'valid',valid);
	commandwindow;


function emLaceyMovieView(thisDirSaveStr, options)
	% uses Lacey's movie viewer, different from the cell sorter

	% load the PC filters and traces
	filesToLoad=strcat(thisDirSaveStr, {options.emSaveRaw});
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

	makeResultsMovie(emAnalysis.allCellImages, emAnalysis.allCellParams, emAnalysis.allCellTraces,0,1,0);

function PCAICA(thisDir, thisID, fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr)
	%get the list of movies to load
	movieList = getFileList(thisDir, fileFilterRegexp);
	% skip if folder is empty
	if isempty(movieList)
		display('empty folder, skipping...')
		return;
	end

	[DFOF DFOFsize Npixels Ntime] = loadMovieList(movieList);

	% run PCA
	[PcaFilters PcaTraces] = runPCA(DFOF, thisID, nPCs, fileFilterRegexp);

	% save PCs
	% saveID = {rawPCfiltersSaveStr,rawPCtracesSaveStr}
	% saveVariable = {'PcaFilters','PcaTraces'}
	% for i=1:length(saveID)
	%     savestring = [thisDirSaveStr saveID{i}];
	%     display(['saving: ' savestring])
	%     save(savestring,saveVariable{i});
	% end

	% verify that runPCA ended correctly, if so, initiate runICA
	if ~isempty(PcaTraces)
		display('+++')
		[IcaFilters IcaTraces] = runICA(PcaFilters, PcaTraces, thisID, nICs, '');
		% save ICs
		saveID = {options.rawICfiltersSaveStr,options.rawICtracesSaveStr}
		saveVariable = {'IcaFilters','IcaTraces'}
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			save(savestring,saveVariable{i});
		end
	end

function ICApplyDecisions(thisDirSaveStr,options)
	% loads raw filters and traces then removes the bad filters
	filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr,options.cleanedICdecisionsSaveStr});
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end
	if(max(valid)==1)
		valid=logical(valid);
	end
	% filter out bad ICs
	IcaFilters = IcaFilters(valid,:,:);
	IcaTraces = IcaTraces(valid,:);

	% save sorted ICs
	saveID = {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr}
	saveVariable = {'IcaFilters','IcaTraces'}
	for i=1:length(saveID)
		savestring = [thisDirSaveStr saveID{i}];
		display(['saving: ' savestring])
		save(savestring,saveVariable{i});
	end

function ICAChooser(thisDir, thisDirSaveStr,thisID,fileInfo,options, varargin)
	options.viewer = 0;
	% get options
	options = getOptions(options,varargin);

	% load the PC filters and traces
	filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end
	% check if the folder has temporary decisions to load (e.g. if a crash occured)
	tmpDecisionList = getFileList(thisDir, 'tmpDecision');
	if(~isempty(tmpDecisionList))
		display(['loading temp decisions: ' tmpDecisionList{1}])
		load(tmpDecisionList{1});
	else
		valid = [];
	end

	[IcaFilters IcaTraces valid] = signalSorter(IcaFilters, IcaTraces, thisID, [],'inputStr',[' ' fileInfo.subject '\_' fileInfo.assay],'valid',valid);
	commandwindow;

	% save sorted ICs
	if options.viewer==0
		saveID = {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr,options.cleanedICdecisionsSaveStr}
		saveVariable = {'IcaFilters','IcaTraces','valid'}
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			save(savestring,saveVariable{i});
		end
	end

function [outputStruct] = identifyNeighbors(outputStruct,fileNum,thisDirSaveStr,options)
	% load the PC filters and traces
	% filesToLoad=strcat(thisDirSaveStr, {cleanedICfiltersSaveStr,cleanedICtracesSaveStr});
	filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

	if exist([thisDirSaveStr options.neighborsSaveStr],'file')
		filesToLoad=strcat(thisDirSaveStr, {options.neighborsSaveStr});
		for i=1:length(filesToLoad)
			display(['loading: ' filesToLoad{i}]);
			load(filesToLoad{i})
		end
	else
		outputStruct.neighborsCell{fileNum} = identifyNeighborsAuto(IcaFilters, IcaTraces);

		neighborsToSave = outputStruct.neighborsCell{fileNum};
		saveID = {options.neighborsSaveStr};
		saveVariable = {'neighborsToSave'};
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			save(savestring,saveVariable{i});
		end
	end

	viewNeighborsAuto(IcaFilters, IcaTraces, neighborsToSave);

function [outputStruct] = findSpikes(outputStruct, options, fileNum, nFiles, thisDirSaveStr)
	% filesToLoad=strcat(thisDirSaveStr, {cleanedICfiltersSaveStr,cleanedICtracesSaveStr});
	filesToLoad=strcat(thisDirSaveStr, {options.cleanedICtracesSaveStr});
	% if bad ICs haven't been removed yet, use the raw
	if(~exist(filesToLoad{1}, 'file'))
		% filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
		filesToLoad=strcat(thisDirSaveStr, {options.rawICtracesSaveStr});
	end
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

	% only take top 50% of ICs
	% filterNum = round(quantile(1:size(IcaTraces,1),0.5));
	% IcaTraces = IcaTraces(1:filterNum,:);

	[signalSpikes, signalSpikesArray] = controllerSpikeDetection(IcaTraces, 'makePlots', 0,'makeSummaryPlots',1);

	[peakOutputStat] = getPeakStatistics(IcaTraces);

	signalSpikesSum = sum(signalSpikes,1);
	outputStruct.signalSpikes{fileNum} = signalSpikes;
	outputStruct.signalMatrix{fileNum} = IcaTraces;
	outputStruct.fwhmSignal{fileNum} = peakOutputStat.fwhmSignal;

	figure(142)
	subplot(5,ceil(nFiles/5),fileNum);
		hist(fwhmSignal,[0:nanmax(fwhmSignal)]); box off;
		% xlabel('FWHM (frames)'); ylabel('count');
		% title('full-width half-maximum for detected spikes');
		% title([outputStruct.subject{fileNum} '\_' outputStruct.assay{fileNum}])
		title([outputStruct.subject{fileNum}])
		h = findobj(gca,'Type','patch');
		set(h,'FaceColor',[0 0 0],'EdgeColor',[0 0 0])
		set(gca,'xlim',[0 nanmax(fwhmSignal)]);

	if fileNum==nFiles
		outputStruct.signalMean = cell2mat(arrayfun(@(x) mean(sum(x),2), outputStruct.signalSpikes, 'UniformOutput', false));
		outputStruct.signalStd = cell2mat(arrayfun(@(x) std(sum(x),2), outputStruct.signalSpikes, 'UniformOutput', false));
		figure(105);
			plot(outputStruct.signalMean); hold on; box off;
			plot(outputStruct.signalStd,'r');
			title('spikes per cell over entire trial');
			xlabel('trialNum');ylabel('mean/std of trial spikes');
			legend({'mean', 'std'});
			drawnow
	end

function compareSignalToMovie(thisDir, fileFilterRegexp,thisDirSaveStr, options)
	%get the list of movies to load
	movieList = getFileList(thisDir, fileFilterRegexp);

	% load movies
	[DFOF DFOFsize Npixels Ntime] = loadMovieList(movieList);

	% load traces and filters
	filesToLoad=strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr});
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

	compareSignalToMovie(DFOF, IcaFilters, IcaTraces);

function convertToSpikeE(thisDirSaveStr,options)
	% convert to SpikeE data format
	filterFilePath = [thisDirSaveStr options.cleanedICfiltersSaveStr];
	traceFilePath = [thisDirSaveStr options.cleanedICtracesSaveStr];
	[SpikeImageData, SpikeTraceData] = convertToSpikeE(filterFilePath, traceFilePath, 'toSpikeE');
	save([thisDir filesep thisID '_ICfilters_SpikeE.mat'], 'SpikeImageData');
	save([thisDir filesep thisID '_ICtraces_SpikeE.mat'], 'SpikeTraceData');

function cellmaps(fileNum,nFiles,thisDir,thisDirSaveStr,options)
	if fileNum==1
		fig1 = figure(32);
		colormap gray;
	end
	thisCellmap = createCellMap([thisDirSaveStr options.rawICfiltersSaveStr]);
	subplot(round(nFiles/4),4,fileNum);
	imagesc(thisCellmap);
	title(regexp(thisDir,'m\d+', 'match'));
	box off; axis off;
	drawnow;