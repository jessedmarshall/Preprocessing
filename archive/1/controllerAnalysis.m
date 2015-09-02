function [outputStruct] = controllerAnalysis(runArg, folderListInfo, varargin)
	% batch PCA/ICA controller
	% biafra ahanonu, 2013.10.09
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
	%
	% example: controller_PCA_ICA('PCAChooser', 'folderList2.txt', 800, 'p92','split');
	%
	% changelog
		% updated: 2013.10.xx
			% the controller now does the saving instead of the PCA/ICA and other functions, this is better from a compatibility standpoint
		% updated: 2013.11.04 [13:28:03]
			% altered how files are saved so it is more consistent and easier to change without problems arising

	% add controller directory and subdirectories to path
	addpath(genpath(pwd));
	% set default figure properties
	setFigureDefaults();
	% remove pre-compiled functions
	clear FUNCTIONS;
	%========================
	% old way of saving, only temporary until full switch
	options.oldSave = 0;
	options.nPCs = [];
	options.nICs = [];
	options.runID = '';
	options.protocol = '';
	options.fileFilterRegexp = 'concatenated_.*.h5';
	% get options
	options = getOptions(options,varargin);
	options
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================
	if strcmp(class(folderListInfo),'struct')
		outputStruct = folderListInfo;
	else
		outputStruct.null = nan;
	end
	%========================
	% read in the list of folders unless you have a structure with the info
	if strcmp(class(folderListInfo),'struct')
		nFiles = length(folderListInfo.folderList);
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
		controllerOptions = {'PCAICA','PCA','PCAChooser','ICA','ICAChooser','findSpikes','identifyNeighbors','compareSignalToMovie','convertToSpikeE','convertFromSpikeE', 'applyICsMovie','cellmaps'};
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
	% naming scheme for saved files
	rawPCfiltersSaveStr = '_PCAfilters.mat';
	rawPCtracesSaveStr = '_PCAtraces.mat';
	cleanedPCfiltersSaveStr = '_PCAfilters_sorted.mat';
	cleanedPCtracesSaveStr = '_PCAtraces_sorted.mat';
	rawICfiltersSaveStr = '_ICfilters.mat';
	rawICtracesSaveStr = '_ICtraces.mat';
	cleanedICfiltersSaveStr = '_ICfilters_sorted.mat';
	cleanedICtracesSaveStr = '_ICtraces_sorted.mat';
	cleanedICdecisionsSaveStr = '_ICdecisions.mat';
	%========================
	analysisStartTime = tic;
	for fileNum=1:nFiles
		commandwindow
		loopStartTime = tic;
		thisID = runID;
		if strcmp(class(folderListInfo),'struct')
			% [thisDir,~,~] = fileparts(folderListInfo.folderList{fileNum});
			thisDir = folderListInfo.folderList{fileNum};
			nPCs = folderListInfo.nPCs{fileNum};
			nICs = folderListInfo.nICs{fileNum};
			options.fileFilterRegexp = folderListInfo.fileFilterRegexp;
		elseif strcmp(class(folderListInfo),'char')
			thisDir = folderList{fileNum,1};
			% should be folderDir,nPCs,nICs
			dirInfo = regexp(folderList{fileNum,1},',','split');
			thisDir = dirInfo{1};
			if(length(dirInfo)>=2)
				nPCs = str2num(dirInfo{3});
				nICs = str2num(dirInfo{2});
			else
				nPCs = options.nPCs;
				% nICs = round((2/3)*nPCs);
				nICs = options.nICs;
			end
		end

		display('++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
		display([num2str(fileNum) '/' num2str(nFiles) ': ' thisDir]);
		% nPCs is 1.5*nExpectedCells, so nICs is 2/3 nPCs
		display(['number of PCs:' num2str(nPCs)]);
		display(['number of ICs:' num2str(nICs)]);

		% check if this directory has been commented out, if so, skip
		if strcmp(thisDir(1),'#')
			display('skipping...')
			continue;
		end
		% get list of movies
		movieList = getFileList(thisDir, fileFilterRegexp);
		% if only have filters, change what you look for, since you only want files to get information for the mouse
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
		fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.mouse '_' fileInfo.assay];
		thisDirSaveStr = [thisDir filesep fileInfoSaveStr '_' thisID];
		if oldSave==1
			thisDirSaveStr = [thisDir filesep thisID];
		end

		% branch based on chosen option
		switch runArg
			case 'PCAICA'
				%get the list of movies to load
				movieList = getFileList(thisDir, fileFilterRegexp);

				[pathstr,name,ext] = fileparts(movieList{1});
				if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
					options.movieType = 'hdf5';
					% use the faster way to read in image data, especially if only need a subset
					[DFOF DFOFsize Npixels Ntime] = loadMovieList(movieList,'movieType',options.movieType);
					% thisMovie = readHDF5Subset(inputFilePath,[0 0 options.frameList(1)],[xDim yDim length(options.frameList)]);
				elseif strcmp(ext,'.tif')|strcmp(ext,'.tiff')
					options.movieType = 'tiff';
					[DFOF DFOFsize Npixels Ntime] = loadMovieList(movieList,'movieType',options.movieType);
				end

				% load movies
				% [DFOF DFOFsize Npixels Ntime] = loadMovieList(movieList);

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
					saveID = {rawICfiltersSaveStr,rawICtracesSaveStr}
					saveVariable = {'IcaFilters','IcaTraces'}
					for i=1:length(saveID)
						savestring = [thisDirSaveStr saveID{i}];
						display(['saving: ' savestring])
						save(savestring,saveVariable{i});
					end
				end
			case 'PCA'
				% runPCA(thisDir, thisID, nPCs, fileFilterRegexp);
			case 'ICA'
				% runICA(thisDir, thisID, days, nICs, '');
			case 'PCAChooser'
				PCAchooser(thisDir, thisID);
			case 'ICAChooser'
				% load the PC filters and traces
				filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
				for i=1:length(filesToLoad)
					display(['loading: ' filesToLoad{i}]);
					load(filesToLoad{i})
				end

				[IcaFilters IcaTraces valid] = ICAchooser(IcaFilters, IcaTraces, thisID, []);
				commandwindow;

				% save sorted ICs
				saveID = {cleanedICfiltersSaveStr,cleanedICtracesSaveStr,cleanedICdecisionsSaveStr}
				saveVariable = {'IcaFilters','IcaTraces','valid'}
				for i=1:length(saveID)
					savestring = [thisDirSaveStr saveID{i}];
					display(['saving: ' savestring])
					save(savestring,saveVariable{i});
				end
			case 'identifyNeighbors'
				% load the PC filters and traces
				filesToLoad=strcat(thisDirSaveStr, {cleanedICfiltersSaveStr,cleanedICtracesSaveStr});
				for i=1:length(filesToLoad)
					display(['loading: ' filesToLoad{i}]);
					load(filesToLoad{i})
				end

				outputStruct.neighborsCell = identifyNeighborsAuto(IcaFilters, IcaTraces);
			case 'applyICsMovie'
				applyICsMovie(thisDir, thisID, fileFilterRegexp, '');
			case 'findSpikes'
				filesToLoad=strcat(thisDirSaveStr, {cleanedICfiltersSaveStr,cleanedICtracesSaveStr});
				% if bad ICs haven't been removed yet, use the raw
				if(~exist(filesToLoad{1}, 'file'))
					filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
				end
				for i=1:length(filesToLoad)
					display(['loading: ' filesToLoad{i}]);
					load(filesToLoad{i})
				end

				[signalSpikes, signalSpikesArray] = controllerSpikeDetection(IcaTraces, 'makePlots', 0);

				signalSpikesSum = sum(signalSpikes,1);
				outputStruct.avgFiringTimeBin(fileNum,:)=[sum(signalSpikesSum(:,1:1500))/1500 sum(signalSpikesSum(:,1500:4500))/3000 sum(signalSpikesSum(:,4500:end))/length(signalSpikesSum(:,4500:end))]./sum(signalSpikesSum(:,1:1500))/1500;
				if fileNum==nFiles
					figure(105);
					bar(outputStruct.avgFiringTimeBin');
					title('avg firing rate during formalin phases: avg firing rate vs. time bin')
					xlabel('mins');ylabel('avg rate (relative to first bin)');
					legend({'m728', 'm805'});
					set(gca,'XTickLabel',{'1-5', '5-10', '10-end'})
				end
			case 'compareSignalToMovie'
				%get the list of movies to load
				movieList = getFileList(thisDir, fileFilterRegexp);

				% load movies
				[DFOF DFOFsize Npixels Ntime] = loadMovieList(movieList);

				filesToLoad=strcat(thisDirSaveStr, {cleanedICfiltersSaveStr,cleanedICtracesSaveStr});
				for i=1:length(filesToLoad)
					display(['loading: ' filesToLoad{i}]);
					load(filesToLoad{i})
				end

				compareSignalToMovie(DFOF, IcaFilters, IcaTraces);
			case 'convertToSpikeE'
				filterFilePath = [thisDirSaveStr '_ICfilters_sorted.mat'];
				traceFilePath = [thisDirSaveStr '_ICtraces_sorted.mat'];
				[SpikeImageData, SpikeTraceData] = convertToSpikeE(filterFilePath, traceFilePath, 'toSpikeE');
				save([thisDir filesep thisID '_ICfilters_SpikeE.mat'], 'SpikeImageData');
				save([thisDir filesep thisID '_ICtraces_SpikeE.mat'], 'SpikeTraceData');
			case 'convertFromSpikeE'
				filterFilePath = [thisDirSaveStr '_ICfilters' '.mat'];
				traceFilePath = [thisDirSaveStr '_ICtraces' '.mat'];
				[filters, traces] = convertToSpikeE(filterFilePath, traceFilePath, 'fromSpikeE');
			case 'cellmaps'
				if fileNum==1
					fig1 = figure(32);
					colormap gray;
				end
				thisCellmap = createCellMap([thisDirSaveStr '_ICfilters' '.mat']);
				subplot(round(nFiles/4),4,fileNum);
				imagesc(thisCellmap);
				title(regexp(thisDir,'m\d+', 'match'));
				box off; axis off;
				drawnow;
			otherwise
				display('Pick an option!');
		end
		toc(loopStartTime);
	end
	toc(analysisStartTime);

	% path(pathdef);