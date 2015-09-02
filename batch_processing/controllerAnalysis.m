function [ostruct] = controllerAnalysis(varargin)
	% batch wrapper function to control cell/trace finding, secondary trial analysis, and other analysis.
	% biafra ahanonu
	% started: 2013.10.09
	%
	% inputs
		% varargin
		% depreciated args
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
		% ostruct - structure containing several fields that are sorted into cell arrays, each array containing information for the folder that was run

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
		% 2014.01.03 [16:35:55] didn't update changelog, but the gist of the changes: changed how controller is launched by having the user select the file with folders, else they have the option to input a file, same goes for the run argument. finished integrating Lacey's code into the controller, added ability to downsample HDF5 files (should be in controllerPreprocessMovie, but here for the moment), improved how list dialog is shown.
		% 2014.01.03 [22:02:01] added try...catch to the main folder loop, long overdue
		% 2014.01.04 [15:54:14] added side-by-side to the pipeline
		% 2014.01.23 [21:11:44] integrated controllerPreprocessMovie into this controller, central location for end-to-end
		% 2014.04.23 [17:17:28] now allow folder to be an inputs for folderListInfo
	% TODO
		% Namespace (or package) everything. e.g. +gantis for the folder and gantis.controllerAnalysis for calling the main function. This would require an afternoon of refactoring all the functions to call the new namespaced functions. Might be worth it in the long run if compatability with other people's code is an issue.
		% Fix calling of sub-functions, currently not the most elegant design...
		% Make chunk size in EM scripts dynamic...
		% allow loading of options file somewhere

	% remove pre-compiled functions
	clear FUNCTIONS;
	% load necessary functions
	loadBatchFxns();
	%========================
	% input structure or file pointing to directories, empty for manual selection
	options.folderListInfo = 'manual';
	% argument to decide which command to run, if empty then manual, else batch mode
	options.runArg = '';
	% old way of saving, only temporary until full switch
	options.oldSave = 0;
	% for future compatibility, add the feature to load options for project
	options.loadSettings = 0;
	% short-hand list of trial IDs, used in regexp of getFileInfo.m to extract assay info
	options.assayList = {'MAG|PAV(|-PROBE)|(Q|)EXT|REN|REINST|S(HC|CH)|SUL(|P)|SAL|TROP|epmaze|OFT|HAL|D','formalin|hcplate|vonfrey|acetone|pinprick|habit|','OFT|roto|oft|openfield|check|groombox|socialcpp|REVTRAIN|reversalPre|reversalPost|reversalAcq|reversalRevOne|reversalRevTwo|reversalRevThree|reversalTraining|revTrain|normal|highpass'};
	%===
	% the id for this particular run, depreciated at the moment
	options.runID = '';
	% protocol number, ignore if you don't have these
	options.protocol = '';
	% regular expression used to find movie files
	options.fileFilterRegexp = 'concat_.*.h5';
	% number of frames to use in loaded movies, [] = use all frames
	options.frameList = [];
	% name of the input hierarchy in the hdf5 file
	options.datasetName = '/1';
	% output dataset name (for when saving hdf5 files)
	options.outputDatasetName = '/1';
	% where pictures should be saved
	options.picsSavePath = 'private\pics\';
	% should the movie be converted to double?
	options.convertToDouble = 0;
	% max size of chunk when doing large-scale analysis, in MBytes
	options.maxChunkSize = 25000;
    % how much to downsample raw movie by (spatially)
    options.downsampleFactor = 4;
    % path to folder for downsample, trailing \
    options.downsampleSaveFolder = [];
    % number of pixels to crop around movie
    options.pxToCrop = 4;
    % type of video player to use, 'matlab' or 'imagej'
    options.videoPlayer = [];
    %===
    % EM OPTIONS
	% several EM options
	options.EM.suppressProgressFig = 0;
	options.EM.suppressOutput = 1;
	% hz of the movies used in analysis
	options.EM.analysisFramerate = 5;
	% microns per pixel for analysis
	options.EM.analysisPixelSize = 2.37;
	% size of a square chunck in Lacey's EM script, THIS SHOULD BE MADE DYNAMIC!!!
	options.EM.sqSize = 30;
	% for compareToICAresults
	options.EM.playbackFramerate = 20;
	% if 1, side-by-side of IC to em
	options.EM.playTwoMoviesWithContours = 1;
	% save names of EM data
	options.emSaveRaw = '_emAnalysis';
	options.emSaveSorted = '_emAnalysis_sorted';
	%===
    % DIRECTORIES
	% directory to search for tracking files
	options.trackingDir = '';
	% directory where behavior videos are
	options.videoDir = '';
    % location to save side by side, blank is the original videos directory
    options.sideBySideDir = [];
    %===
    % BEHAVIOR OPTIONS
	% location of the table containing information about the subject
	options.subjectTablePath = [];
	options.delimiter = 'tab';
	% skip collection of subject info into ostruct.data
	options.skipSubjData = 0;
	% cell array containing the name of each stimuli to align signal peaks to
	options.stimNameArray = [];
	% matrix containing numbers in the subjectTablePath that correspond to the stims in stimNameArray
	options.stimIdNumArray = [];
	% 0 all stim, 1 = stim onset, 2 = stim offset
	options.stimTriggerOnset = 0;
	% rate of neural data
	options.framesPerSecond = 5;
	% frames before/after to perform operations
	options.timeSeq = [-60:60];
	% fix for problems finding US stimuli
	options.usTimeAfterCS = 10;
	%===
    % PCAICA OPTIONS
	% number of ICs and PCs
	options.nPCs = [];
	options.nICs = [];
	% user can input a pcaica list with subjects to reduce typing in parse file
	% should be a structure with field names corresponding to subject id (e.g. pcaicaList.('m901') = [PCs ICs])
	options.pcaicaList = [];
	options.useAppliedICs = 0;
	%===
    % NAME SCHEME
    % side by side name
    options.sideBySideName = '_sideBySide.h5';
	% naming scheme for saved files
	options.rawPCfiltersSaveStr = '_PCAfilters.mat';
	options.rawPCtracesSaveStr = '_PCAtraces.mat';
	%
	options.cleanedPCfiltersSaveStr = '_PCAfilters_sorted.mat';
	options.cleanedPCtracesSaveStr = '_PCAtraces_sorted.mat';
	%
	options.rawICfiltersSaveStr = '_ICfilters.mat';
	options.rawICtracesSaveStr = '_ICtraces.mat';
	options.rawICtracesAppliedSaveStr = '_ICtraces_applied.mat';
	%
	options.cleanedICfiltersSaveStr = '_ICfilters_sorted.mat';
	options.cleanedICtracesSaveStr = '_ICtraces_sorted.mat';
	options.cleanedICdecisionsSaveStr = '_ICdecisions.mat';
	%
	options.autoICfiltersSaveStr = '_ICfilters_automated.mat';
	options.autodICtracesSaveStr = '_ICtraces_automated.mat';
	options.autoICdecisionsSaveStr = '_ICdecisions_automated.mat';
	%
	options.neighborsSaveStr = '_neighbors.mat';
	options.alignmentSaveName = '_alignmentStruct.mat';
	%===
    % CLASSIFIER OPTIONS
	% location to save the classifier in
	options.classifierFilepath = 'private\classifier\classifier.mat';
    % 'nnet' 'svm' 'glm'
	options.classifierType = 'glm';
	options.trainingOrClassify = 'training';
	%===
	% get options
	options = getOptions(options,varargin);
	options
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================
	% change handling depending on whether use gave a list of folders or a structure with info
	if strcmp(class(folderListInfo),'struct')
		ostruct = folderListInfo;
	else
		ostruct.null = nan;
	end
	%========================
	% make a custom colormap to be used
	if ~any(strcmp('colormap',fieldnames(ostruct)))
		% gradient from white to red
		% ostruct.colormap = customColormap({[1 1 1],[1 0 0]});
		ostruct.colormap = customColormap([]);
	end
	%========================
	% read in the list of folders unless you have a structure with the info
	if strcmp(options.folderListInfo,'manual')
		[folderListInfo,folderPath,~] = uigetfile('*.*','select text file that points to analysis folders','example.txt');
		% exit if user picks nothing
		if folderListInfo==0; return; end
		folderListInfo = [folderPath folderListInfo];
	end

	if strcmp(class(folderListInfo),'struct')
		nFiles = length(folderListInfo.folderList);
		folderList = folderListInfo;
	elseif strcmp(class(folderListInfo),'char')

		if isempty(regexp(folderListInfo,'.txt'))&exist(folderListInfo,'dir')==7
			% user just inputs a single directory
			folderList = {folderListInfo};
		else
			fid = fopen(folderListInfo, 'r');
			tmpData = textscan(fid,'%s','Delimiter','\n');
			folderList = tmpData{1,1};
			fclose(fid);
		end
		nFiles = length(folderList);
	end
    %========================
    % make folders
    if ~isempty(options.picsSavePath)
    	mkdir(options.picsSavePath)
    end
    if ~isempty(options.sideBySideDir)
    	mkdir(options.sideBySideDir)
    end
	%========================
	% get option from user
	sep = repmat('-',1,7);
	if strcmp(runArg,'')
		controllerOptions = {...
		'fullPipeline',sep,...
		'downsampleInscopix','moveFiles','preprocessInscopix','cropInscopix','pcaicaInscopix',sep,...
        'convertToHDF5','saveMovieSlice','downsampleMovie','preprocessMovie','cropMovies',sep,...
        'saveMovieAvi','saveMovieRaw','saveMovieTiff',sep,...
		'compareEmLaceyToICA','emLaceyAnalysis','emLaceySorter','emLaceyViewer','emLaceyMovieView',sep,...
		'pcaica','pca','ica','pcaChooser','icaChooser','icaViewer','icaApplyDecisions','applyImagesToMovie',sep,...
		'trainClassifier','testClassifier',sep,...
		'viewPeakMontages','computePeaks','objectMaps','computePeakToStdRelation',sep,...
		'matchObjAcrossTrials','identifyNeighbors',sep,...
		'signalToMovement','stimTriggeredAverage',sep,...
		'compareSignalToMovie','stimulusTriggeredMovie','stimTriggeredMovie',sep,...
		'getMovieStatistics','playMovie','playShortClip','playSideBySide','createSideBySide',sep,...
		'removeFiles','convertToSpikeE','convertFromSpikeE'...
		};
		scnsize = get(0,'ScreenSize');
		[sel, ok] = listdlg('ListString',controllerOptions,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.75]);
		% make sure selection chosen, else return
		if ok==0; return; end
		% select the option to run
		runArg = controllerOptions{sel};
	end
	display(runArg);

    % ========================
    % change options based on user input
    switch runArg
    	case 'downsampleInscopix'
    		% assume normal inscopix output, to be abstracted
	        options.fileFilterRegexp = 'recording.*.hdf5';
	        % inscopix HDF5 files use this hierarchy name
	        options.datasetName = '/images';
	        runArg = 'downsampleMovie';
    	case 'preprocessInscopix'
    		options.fileFilterRegexp = 'concat_.*.h5';
    		runArg = 'preprocessMovie';
    	case 'cropInscopix'
    		options.fileFilterRegexp = 'downsample';
    		runArg = 'cropMovies';
    	case 'pcaicaInscopix'
    		options.fileFilterRegexp = 'crop';
    		runArg = 'pcaica';
    	otherwise
    end
    options.fileFilterRegexp

	% ========================
	% loop over each folder (don't ask why it's called fileNum...)
	analysisStartTime = tic;
	% start full pipeline at downsampling
	fullPipelineBranch = 1;
	% used to cycle through file list
	fileNum = 0;
	ostruct.counter = 1;
	% number of folders that actually need to be analyzed
	ostruct.nAnalyzeFolders = 0;

	% ========================
	display('gathering file information...');display(repmat('+',1,7))
	while fileNum<nFiles
			fileNum = fileNum+1;
			% get information for this run
			[thisDir,nPCs,nICs,options] = getRunInformation(nFiles,folderList,folderListInfo,options,fileNum);

			% check if this directory has been commented out, if so, skip
			if strmatch('#',thisDir)
				% display(['skipping: ' thisDir])
				ostruct.subjInfo.assay{fileNum} = ' ';
				continue;
			end

			fileInfo = getFileInfo(folderList{fileNum},'assayList',options.assayList);
			ostruct.subjInfo.subject{fileNum} = fileInfo.subject;
			ostruct.subjInfo.assay{fileNum} = fileInfo.assay;
			ostruct.nAnalyzeFolders = ostruct.nAnalyzeFolders + 1;
	end
	emptyIdx = ~cellfun('isempty',ostruct.subjInfo.assay);
	% ostruct.subjInfo.subjectType = mat2cell(strcat(ostruct.subjInfo.subject,'+',ostruct.subjInfo.assay));
	% ostruct.subjInfo.subjectType = mat2cell(strcat('+',ostruct.subjInfo.assay));
	ostruct.subjInfo.subjectType = regexp(ostruct.subjInfo.assay,'\D+','match');
	ostruct.subjInfo.subjectType = cat(1,ostruct.subjInfo.subjectType{:});
	% return;
	% ostruct.subjInfo.subjectType = ostruct.subjInfo.subjectType{1,1};
	display(repmat('+',1,7))

	% ========================
	fileNum = 1;
	while fileNum<=nFiles
		try
            startCounter = ostruct.counter;
            display('++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
			% change some options if doing the full-pipeline, assuming inscopix normal output formula
			if strcmp(runArg,'fullPipeline')
				options.fileFilterRegexp = 'recording.*.hdf5';
			end

			% commandwindow
			loopStartTime = tic;
			thisID = runID;

			% get information for this run
			[thisDir,nPCs,nICs,options] = getRunInformation(nFiles,folderList,folderListInfo,options,fileNum);
			options.thisDir = thisDir;

			% check if this directory has been commented out, if so, skip
			if strmatch('#',thisDir)
				fileNum = fileNum+1;
				% display(['skipping: ' thisDir])
				continue;
			end
			%
            display([num2str(ostruct.counter) '/' num2str(ostruct.nAnalyzeFolders)]);

			% use a file in directory to extract trial info; if only have filters, change what you look for, since you only want files to get information for the subject
			movieList = getFileList(thisDir, options.fileFilterRegexp);
			if isempty(movieList)
				movieList = getFileList(thisDir, rawICfiltersSaveStr);
			end
			options.movieList = movieList;

			% get the current directory and file info
			if isempty(movieList)
				fileInfo = getFileInfo(thisDir,'assayList',options.assayList);
			else
				fileInfo = getFileInfo(movieList{1},'assayList',options.assayList);
			end
			% if user specifies protocol other than that found in the file
			if(exist('protocol','var')&~strcmp(protocol,''))
				fileInfo.protocol = protocol;
			end
			fileInfo
			% make save strings
			fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.subject '_' fileInfo.assay];
			fileInfoSaveStr
			trialRegExp = fileInfoSaveStr;
			if ~isempty(getFileList(thisDir, 'NULL000'))
				fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.subject '_' 'NULL000'];
			end
			thisDirSaveStr = [thisDir filesep fileInfoSaveStr '_' thisID];
			if oldSave==1
				thisDirSaveStr = [thisDir filesep thisID];
			end

			% ask user for format of behavior videos
			if isempty(strmatch(runArg,{'createSideBySide','stimTriggeredMovie'}))
				videoTrialRegExp = trialRegExp;
			else
				if ~exist('videoTrialRegExpIdx','var')
					videoTrialRegExpList = {'yyyy_mm_dd_pNNN_mNNN_assayNN','yymmdd-mNNN-assayNN'};
					[videoTrialRegExpIdx] = pulldown('video string type (N = number)',videoTrialRegExpList);
				end
				switch videoTrialRegExpIdx
					case 1
						videoTrialRegExp = trialRegExp
					case 2
						videoTrialRegExp = [strrep(strrep(fileInfo.date,'20',''),'_','') '-' fileInfo.subject '-' fileInfo.assay]
					otherwise
						% do nothing
				end
			end

			% save subject/assay info into multi-loop structure
			% ostruct = cell2struct([struct2cell(ostruct);struct2cell(fileInfo)]);
			% legacy, slowly eliminate
			ostruct.subject{fileNum} = fileInfo.subject;
			ostruct.assay{fileNum} = fileInfo.assay;
			% new
			ostruct.info.date{fileNum} = fileInfo.date;
			ostruct.info.protocol{fileNum} = fileInfo.protocol;
			ostruct.info.subject{fileNum} = fileInfo.subject;
			ostruct.info.assay{fileNum} = fileInfo.assay;
			ostruct.info.assayType{fileNum} = fileInfo.assayType;
			ostruct.info.assayNum{fileNum} = fileInfo.assayNum;

			% ============================
			% hash table (struct in matlab case) of subj PCAICAs
			if ~isempty(options.pcaicaList)
				% get the pc ic for this subject
				pcaicaSubj = pcaicaList.(fileInfo.subject)
				nPCs = pcaicaSubj(1);
				nICs = pcaicaSubj(2);
			end
			% ============================
			[ostruct] = getSubjectInfo(ostruct,nFiles,options,fileNum);
			% ============================
			% branch based on chosen option
			switch runArg
				case 'fullPipeline'
					% implements the full pre-processing + cell finding pipeline for a set of folders
					% if a folder contains multiple movies, they will be combined during the controllerPreprocessMovie step
					switch fullPipelineBranch
						case 1
							% assume normal inscopix output, to be abstracted
							options.fileFilterRegexp = 'recording.*.hdf5';
							% inscopix HDF5 files use this hierarchy name
							options.datasetName = '/images';
							downsampleHDFMovieFxn(movieList,options);
							if fileNum==nFiles
								fullPipelineBranch=2;
								fileNum = 0;
							end
						case 2
							% downsampleHDFMovie outputs with concat appended to the filename
							options.fileFilterRegexp = 'concat.*.h5';
							% scripts default to /1
							options.datasetName = '/1';
							% if user ran with downsample algorithm, assume that instead
							try
							ostruct.preprocess{fileNum} = controllerPreprocessMovie('folderListPath',folderListInfo,'fileFilterRegexp','concat.*.h5','datasetName',options.datasetName,'frameList',options.frameList);
							catch
							end
							% if fileNum==nFiles
								fullPipelineBranch=3;
								fileNum = 0;
							% end
						case 3
							% controllerPreprocessMovie outputs to dfof
							options.fileFilterRegexp = 'dfof';
							options.datasetName = '/1';
							% grab the nPCs and nICs from the controllerPreprocessMovie structure
							nPCs = ostruct.preprocess{fileNum}.nPCs{fileNum};
							nICs = ostruct.preprocess{fileNum}.nICs{fileNum};
							PCAICA(thisDir, thisID, options.fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr);
							% automatically throw out bad ICs based on SNR
							% placeholder
							% run the EM analysis after PCA ICA
							% emLaceyAnalysis(thisDir, thisID, options.fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr);
							%
							if fileNum==nFiles
								fullPipelineBranch=4;
								fileNum = 0;
							end
						case 4
							% view the resulting ICs
							ICAChooser(thisDir, thisDirSaveStr,thisID,fileInfo,options,ostruct,'viewer',1);
						otherwise
							return
					end
                case 'saveMovieSlice'
                    saveMovieSlice(movieList,options,thisDirSaveStr)
				case 'downsampleMovie'
                    try
                        downsampleHDFMovieFxn(movieList,options);
                    catch err
						display(repmat('@',1,7))
						display(getReport(err,'extended','hyperlinks','on'));
						display(repmat('@',1,7))
                        % assume normal inscopix output, to be abstracted
                        options.fileFilterRegexp = 'recording.*.hdf5';
                        % inscopix HDF5 files use this hierarchy name
                        options.datasetName = '/images';
                        downsampleHDFMovieFxn(movieList,options);
                    end
				case 'convertToHDF5'
	                try
	                    convertToHDF5Fxn(movieList,options);
	                catch
	                    % % assume normal inscopix output, to be abstracted
	                    % options.fileFilterRegexp = 'recording.*.hdf5';
	                    % % inscopix HDF5 files use this hierarchy name
	                    % options.datasetName = '/images';
	                    % downsampleHDFMovieFxn(movieList,options);
	                end

                case 'preprocessMovie'
                    % prevent looping since preprocessing handles all folders
                    fileNum=nFiles+1;
                    try
                        controllerPreprocessMovie2('folderListPath',folderListInfo,'fileFilterRegexp',options.fileFilterRegexp,'datasetName',options.datasetName,'frameList',options.frameList);
                    catch
                        % if user ran with downsample algorithm, assume that instead
                        controllerPreprocessMovie2('folderListPath',folderListInfo,'fileFilterRegexp','concat.*.h5','datasetName',options.datasetName,'frameList',options.frameList);
                    end
                case 'cropMovies'
                	inputFilePath = movieList{1};
                	[pathstr,name,ext] = fileparts(inputFilePath);
                	savePath = [pathstr '\' name '_cropped.h5'];
                	% check whether already exists
                	primaryMovie = loadMovieList(movieList,'convertToDouble',options.convertToDouble,'frameList',options.frameList);
                	% [inputMatrix] = cropMatrix(primaryMovie,'pxToCrop',options.pxToCrop);
                	[primaryMovie] = cropMatrix(primaryMovie);
                	% assume HDF5 for now, FIX!!!
                	writeHDF5Data(primaryMovie,savePath);
				case 'saveMovieRaw'
					saveMovieRaw(movieList,options)
				case 'saveMovieTiff'
					saveMovieTiff(movieList,options)
				case 'saveMovieAvi'
					saveMovieAvi(movieList,options)
				case 'compareEmLaceyToICA'
					compareEmLaceyToICA(thisDir, thisDirSaveStr,thisID,fileInfo,options,movieList);
				case 'emLaceyAnalysis'
					emLaceyAnalysis(thisDir, thisID, options.fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr);
				case 'emLaceySorter'
					emLaceySorter(thisDir, thisDirSaveStr,thisID,fileInfo,options);
                case 'emLaceyViewer'
                    options.viewer = 1;
                    emLaceySorter(thisDir, thisDirSaveStr,thisID,fileInfo,options);
				case 'emLaceyMovieView'
					emLaceyMovieView(thisDirSaveStr, options)
				case 'pca'
					% runPCA(thisDir, thisID, nPCs, fileFilterRegexp);
				case 'ica'
					% runICA(thisDir, thisID, days, nICs, '');
				case 'pcaica'
					PCAICA(thisDir, thisID, options.fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr);
				case 'pcaChooser'
					PCAchooser(thisDir, thisID);
				case 'icaApplyDecisions'
					ICApplyDecisions(thisDirSaveStr,options);
				case 'icaChooser'
					ICAChooser(thisDir, thisDirSaveStr,thisID,fileInfo,options,ostruct);
				case 'icaViewer'
					% uiwait(msgbox('press OK to view a snippet of analyzed movies','Success','modal'));
					ICAChooser(thisDir, thisDirSaveStr,thisID,fileInfo,options,ostruct,'viewer',1);
				case 'trainClassifier'
					options.trainingOrClassify = 'training';
					[ostruct] = trainClassifier(ostruct,thisDir, fileFilterRegexp,thisDirSaveStr, options,fileNum)
				case 'testClassifier'
					options.trainingOrClassify = 'classify';
					[ostruct] = trainClassifier(ostruct,thisDir, fileFilterRegexp,thisDirSaveStr, options,fileNum)
				case 'identifyNeighbors'
					[ostruct] = identifyNeighbors(ostruct,fileNum,thisDirSaveStr,options);
				case 'applyImagesToMovie'
					applyImagesToMovieController(thisDir, thisID, options.fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr);
					% applyImagesToMovieController(thisDir, thisID, options.fileFilterRegexp, '');
				case 'viewPeakMontages'
					[ostruct] = viewPeakMontages(ostruct, options, movieList, fileNum, nFiles, thisDirSaveStr)
				case 'computePeaks'
					[ostruct] = computePeaks(ostruct, options, fileNum, nFiles, thisDirSaveStr);
				case 'signalToMovement'
					[ostruct] = signalToMovement(ostruct, options, fileNum, nFiles, thisDirSaveStr,trialRegExp);
				case 'stimTriggeredMovie'
					if fileNum==1|~any(strcmp('tables',fieldnames(ostruct)))|~any(strcmp('subjectTable',fieldnames(ostruct.tables)))
							% ostruct.tables.subjectTable = readtable(options.subjectTablePath,'Delimiter','comma','FileType','text');
					        % display(['loading subj table: ' options.subjectTablePath])
							% ostruct.tables.subjectTable = readtable(options.subjectTablePath,'Delimiter',options.delimiter,'FileType','text');
							% ostruct.counter = 1;
					end
					ostruct.tables.subjectTable = unique(ostruct.tables.subjectTable);
					nameArray = options.stimNameArray;
					idArray = options.stimIdNumArray;
					nIDs = length(idArray);
					colorArray = hsv(nIDs);
					for idNum = 1:nIDs
						try
				            display(['analyzing ' nameArray{idNum}])

							assayTable = ostruct.tables.subjectTable;
							thisSubj = ostruct.subject{fileNum};
							tmpMatch = regexp(thisSubj,'(m|M|f|F)\d+', 'tokens');
							subject = str2num(char(strrep(thisSubj,tmpMatch{1},'')));
							assay = ostruct.assay{fileNum};
							% assayTable
							% if ~any(strcmp('trial',fieldnames(assayTable)))
							% 	assayTable.trial = assayTable.trialSet;
							% end
							if strfind(assay,'10')
								assayIdx = strcmp(assay,assayTable.trial);
							else
								assayIdx = strcmp(strrep(assay,'0',''),strrep(assayTable.trial,'0',''));
							end
							subjIdx = assayTable.subject==subject;
							stimIDIdx = assayTable.events==idArray(idNum);
							subjectTable = assayTable(find(assayIdx&subjIdx&stimIDIdx),:);
							% subjectTable
							% subjectTable.frame
							% head(subjectTable)
							framesToAlign = subjectTable.frame;
							% for those times when the US isn't present
							% framesToAlign
							if isempty(framesToAlign)&idArray(idNum)==31
								display('refinding US')
								usTimeAfterCS = 10;
								framesPerSecond = 5;
								assayTableTmp = assayTable(find(assayTable.events==30&assayIdx&subjIdx),:);
								assayTableTmp2.time = assayTableTmp.time + usTimeAfterCS;
								framesToAlign = assayTableTmp.frame + usTimeAfterCS*framesPerSecond;
								% subjectTable.frame = framesToAlign;
							end
							% framesToAlign
							[success] = createStimTrigMovie(movieList,framesToAlign,[options.sideBySideDir '\' fileInfoSaveStr '_' nameArray{idNum}],'videoDir',options.videoDir,'videoTrialRegExp',videoTrialRegExp,'outputMovie',1);

						catch err
							display(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							display(repmat('@',1,7))
						end
					end

					% playShortClip(movieList,options,trialRegExp,thisDirSaveStr);
					ostruct.counter = ostruct.counter + 1;
				case 'stimulusTriggeredMovie'
					[ostruct] = stimulusTriggeredMovie(ostruct, options, fileNum, nFiles, thisDirSaveStr,trialRegExp,movieList);
				case 'stimTriggeredAverage'
					[ostruct] = stimTriggeredAverage(ostruct, options, fileNum, nFiles, thisDirSaveStr,trialRegExp);
				case 'compareSignalToMovie'
					compareSignalToMovieController(thisDir, options.fileFilterRegexp,thisDirSaveStr,options);
				case 'matchObjAcrossTrials'
					[ostruct] = matchObjAcrossTrials(ostruct, options, fileNum, nFiles, thisDir,thisDirSaveStr)
				case 'convertToSpikeE'
					convertToSpikeEFxn(thisDirSaveStr,options);
				case 'convertFromSpikeE'
					filterFilePath = [thisDirSaveStr '_ICfilters_spikeE.mat'];
					traceFilePath = [thisDirSaveStr '_ICtraces_spikeE.mat'];
					[IcaFilters, IcaTraces] = convertToSpikeE(filterFilePath, traceFilePath, 'fromSpikeE');
					%
					options.IcaSaveDimOrder = 'zxy';
					if strcmp(options.IcaSaveDimOrder,'xyz')
						IcaFilters = permute(IcaFilters,[2 3 1]);
						imageSaveDimOrder = 'xyz';
					else
						imageSaveDimOrder = 'zxy';
					end
					saveID = {options.rawICfiltersSaveStr,options.rawICtracesSaveStr}
					saveVariable = {'IcaFilters','IcaTraces'}
					for i=1:length(saveID)
						savestring = [thisDirSaveStr saveID{i}];
						display(['saving: ' savestring])
						save(savestring,saveVariable{i},'imageSaveDimOrder');
					end
				case 'objectMaps'
					objectMaps(ostruct,fileNum,nFiles,thisDir,thisDirSaveStr,options);
				case 'getMovieStatistics'
					if isempty(options.frameList)&ostruct.counter==1
                        usrIdxChoice = inputdlg('select frame range (e.g. 1:1000), leave blank for all frames');
						% options.frameList = [1:500];
                        options.frameList = str2num(usrIdxChoice{1});
					end
					getMovieStatistics(movieList,options,trialRegExp,thisDirSaveStr);
				case 'playMovie'
					[options] = playShortClip(movieList,options,trialRegExp,thisDirSaveStr);
				case 'playShortClip'
					if isempty(options.frameList)&ostruct.counter==1
                        usrIdxChoice = inputdlg('select frame range (e.g. 1:1000), leave blank for all frames');
						% options.frameList = [1:500];
                        options.frameList = str2num(usrIdxChoice{1});
					end
					[options] = playShortClip(movieList,options,trialRegExp,thisDirSaveStr);
				case 'playSideBySide'
                    if isempty(options.frameList)&ostruct.counter==1
                        usrIdxChoice = inputdlg('select frame range (e.g. 1:1000), leave blank for all frames');
                        % options.frameList = [1:500];
                        options.frameList = str2num(usrIdxChoice{1});
                    end
                    ostruct.counter = ostruct.counter + 1;
                    [options] = playShortClip(movieList,options,trialRegExp,thisDirSaveStr);
                case 'removeFiles'
                	% confirm the user wants to delete files
                	% usrIdxChoiceStr = {'NOOOOOO, mistake.','YES, give me space!'};
                	% scnsize = get(0,'ScreenSize');
                	% [sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','ARE YOU SURE YOU WANT TO DELETE FILES!!!????');
                	% if sel==1
                	% 	return
                	% end
                	answer = inputdlg({'ARE YOU SURE YOU WANT TO DELETE FILES!!!???? type "yes" else hit cancel'},'',1)
                	if isempty(answer)
                		return;
                	else
                		answer = inputdlg({'Just double checking -_-'},'',1)
                		if isempty(answer)
                			return;
                		end
                	end

                	filesToRemove = getFileList(thisDir, options.fileFilterRegexp);
                	fileToCheck = getFileList(thisDir, 'downsample');
                	% filesToRemove'
                	if ~isempty(filesToRemove)
	                	for fileToDelete = filesToRemove
	                		% char(fileToDelete)
		                	% if exist(char(fileToDelete),'file')
	                		if ~isempty(fileToCheck)
	                			display(['folder has: ' char(fileToCheck{1})])
		                		display(['going to delete: ' char(fileToDelete)])
		                		delete(char(fileToDelete))
		                	else
		                		display('missing DFOF @@@@@@@@@@@@@@@@@@@@@@@@@@')
		                		display('missing DFOF @@@@@@@@@@@@@@@@@@@@@@@@@@')
		                		display('missing DFOF @@@@@@@@@@@@@@@@@@@@@@@@@@')
		                	end
		                end
		            else
		            	display(['no files with: ' options.fileFilterRegexp])
		            end
                case 'createSideBySide'
                    if isempty(options.frameList)&ostruct.counter==1
                        usrIdxChoice = inputdlg('select frame range (e.g. 1:1000), leave blank for all frames');
                        % options.frameList = [1:500];
                        options.frameList = str2num(usrIdxChoice{1});
                    end
                    ostruct.counter = ostruct.counter + 1;
                    if ~isempty(options.videoDir)
                        vidList = getFileList(options.videoDir,videoTrialRegExp);
                        if isempty(vidList)
                            display(['cannot find movie: ' options.videoDir '\' videoTrialRegExp]);
                            continue;
                        else
                            [outputMovie] = createSideBySide(movieList,vidList,'frameList',options.frameList,'downsampleFactorFinal',2);
                            % [outputMovie] = createSideBySide(movieList,vidList,'frameList',options.frameList);
                            % display(['going to load: ' options.videoDir '\' trialRegExp]);
		                    % save movie
		                    if isempty(options.sideBySideDir)
		                        [success] = writeHDF5Data(outputMovie,[thisDirSaveStr options.sideBySideName]);
		                    else
		                        saveDir = [options.sideBySideDir '\' fileInfoSaveStr options.sideBySideName];
		                        [success] = writeHDF5Data(outputMovie,saveDir);
		                    end
		                    % playMovie(outputMovie);
                        end
                    end
				case 'computePeakToStdRelation'
					fileToLoad = {strcat(thisDirSaveStr, {options.cleanedICtracesSaveStr}),strcat(thisDirSaveStr, {options.rawICtracesSaveStr})};
					variableStruct = loadFileToVariables(fileToLoad,options);
					if any(strcmp('null',fieldnames(variableStruct))); return; else; fn=fieldnames(variableStruct); end;
					for i=1:length(fn); eval([fn{i} '=variableStruct.' fn{i} ';']); end

					[ostruct.numSpikesVsStd{fileNum}] = computePeakToStdRelation(IcaTraces);
					numSpikes(:,fileNum) = ostruct.numSpikesVsStd{fileNum};

					if fileNum==nFiles
						% numSpikes = reshape(cell2mat(ostruct.numSpikesVsStd),[12 6]);
						figure(1111)
						subplot(1,2,1)
						plot(numSpikes);box off;
						title('std vs. num detected spikes');xlabel('std above baseline');ylabel('total number of spikes');
						subplot(1,2,2)
						plot(diff(numSpikes));box off;
						title('std vs. diff(num detected spikes)');xlabel('std above baseline');ylabel('diff(total number of spikes)');
						% legend(ostruct.subject);
						drawnow;
					end
				otherwise
					display('Pick an option!');
			end
			toc(loopStartTime);drawnow
			% remove pre-compiled functions
			% clear FUNCTIONS;
			% add controller directory and subdirectories to path
			% addpath(genpath(pwd));
			% set default figure properties
			% setFigureDefaults();
            % some sub-functions do not increment the counter
            if startCounter==ostruct.counter
                ostruct.counter = ostruct.counter + 1;
            end
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
		fileNum = fileNum+1;
	end
	toc(analysisStartTime);
	% commandwindow

	% path(pathdef);

function [outputTable] = readSubjectTable(options)
	% read in table, decides whether to do a single or multiple tables
	% if multiple tables, should have the same column names
	% TODO: make separate function
	if isempty(options.delimiter)
		delimiter = 'tab';
	end
	pathClass = class(options.subjectTablePath);
	switch pathClass
		case 'char'
			outputTable = readtable(options.subjectTablePath,'Delimiter',options.delimiter,'FileType','text');
		case 'cell'
			nPaths = length(options.subjectTablePath);
			for i=1:nPaths
				thisTablePath = options.subjectTablePath{i};
				if(exist(thisTablePath, 'file'))
					display(['loading: ' thisTablePath])
					if ~exist('outputTable')
						outputTable = readtable(char(options.subjectTablePath(i)),'Delimiter',options.delimiter,'FileType','text');
					else
						tmpTable = readtable(char(options.subjectTablePath(i)),'Delimiter',options.delimiter,'FileType','text');
						outputTable = [outputTable;tmpTable];
					end
				end
			end
		otherwise
	end
	outputTable = unique(outputTable);
	% outputTable

function [outputTable] = readMultipleTables(tablePaths,delimiter)
	% read in table, decides whether to do a single or multiple tables
	% if multiple tables, should have the same column names
	% TODO: make separate function
	if isempty(delimiter)
		delimiter = 'tab';
	end
	pathClass = class(tablePaths);
	switch pathClass
		case 'char'
			outputTable = readtable(tablePaths,'Delimiter',delimiter,'FileType','text');
		case 'cell'
			nPaths = length(tablePaths);
			for i=1:nPaths
				thisTablePath = tablePaths{i};
				if(exist(thisTablePath, 'file'))
					display(['loading: ' thisTablePath])
					if ~exist('outputTable')
						outputTable = readtable(char(tablePaths(i)),'Delimiter',delimiter,'FileType','text');
					else
						tmpTable = readtable(char(tablePaths(i)),'Delimiter',delimiter,'FileType','text');
						outputTable = [outputTable;tmpTable];
					end
				end
			end
		otherwise
	end
	% outputTable


function saveMovieSlice(movieList,options,thisDirSaveStr)
    % gets a slice of the movie and saves as a tif

    display(movieList)
    inputOptions.frameList = 50:51;
    inputOptions.convertToDouble = options.convertToDouble;
    movieSlice = loadMovieList(movieList{1},'options',inputOptions);
    imwrite(movieSlice(:,:,1),[thisDirSaveStr '_baseImg.tif']);

function downsampleHDFMovieFxn(movieList,options)
    % downsamples an HDF5 movie, normally the raw recording files

	display(movieList)
    nMovies = length(movieList);
	for i=1:nMovies
        display(repmat('+',1,21))
        display(['downsampling ' num2str(i) '/' num2str(nMovies)])
		inputFilePath = movieList{i};
		display(['input: ' inputFilePath]);
        [pathstr,name,ext] = fileparts(inputFilePath);
        downsampleFilename = [pathstr '\concat_' name '.h5']
        srcFilenameTxt = [pathstr filesep name '.txt']
        srcFilenameXml = [pathstr filesep name '.xml']
        try
	        if ~exist(downsampleFilename,'file')
	        	if isempty(options.downsampleSaveFolder)
	        		downsampleHdf5Movie(inputFilePath, 'inputDatasetName', options.datasetName, 'maxChunkSize', options.maxChunkSize,'downsampleFactor',options.downsampleFactor);
	        	else
	        		downsampleHdf5Movie(inputFilePath, 'inputDatasetName', options.datasetName, 'maxChunkSize', options.maxChunkSize,'saveFolder',options.downsampleSaveFolder,'downsampleFactor',options.downsampleFactor);
	        		destFilenameTxt = [options.downsampleSaveFolder filesep name '.txt']
	        		destFilenameXml = [options.downsampleSaveFolder filesep name '.xml']
		        	if exist(srcFilenameTxt,'file')
		        		copyfile(srcFilenameTxt,destFilenameTxt)
		        	elseif exist(srcFilenameXml,'file')
		        		copyfile(srcFilenameXml,destFilenameXml)
	        		end
	        	end
	        elseif ~isempty(options.downsampleSaveFolder)&~exist([options.downsampleSaveFolder '\concat_' name '.h5'],'file')
	        	downsampleHdf5Movie(inputFilePath, 'inputDatasetName', options.datasetName, 'maxChunkSize', options.maxChunkSize,'saveFolder',options.downsampleSaveFolder,'downsampleFactor',options.downsampleFactor);
	        	destFilenameTxt = [options.downsampleSaveFolder filesep name '.txt']
	        	destFilenameXml = [options.downsampleSaveFolder filesep name '.xml']
	        	if exist(srcFilenameTxt,'file')
	        		copyfile(srcFilenameTxt,destFilenameTxt)
	        	elseif exist(srcFilenameXml,'file')
	        		copyfile(srcFilenameXml,destFilenameXml)
        		end
	        else
	            display(['skipping: ' inputFilePath])
	        end
        catch err
        	display(repmat('@',1,7))
        	disp(getReport(err,'extended','hyperlinks','on'));
        	display(repmat('@',1,7))
        end
	end

function convertToHDF5Fxn(movieList,options)
    % saves list of movie files to hdf5
	display(movieList)
    nMovies = length(movieList);
	for i=1:nMovies
        display(repmat('+',1,21))
        display(['converting to hdf5: ' num2str(i) '/' num2str(nMovies)])
		inputFilePath = movieList{i};
		display(['input: ' inputFilePath]);
        [pathstr,name,ext] = fileparts(inputFilePath);
        hdf5Filename = [pathstr '\' name '.h5'];
        % options.movieType = 'hdf5';
        thisMovie = loadMovieList(inputFilePath,'convertToDouble',0);
        if isempty(thisMovie)
        	display(['movie not loaded: ' inputFilePath])
        else
	        if ~exist(downsampleFilename,'file')
	        	writeHDF5Data(thisMovie,hdf5Filename);
	        else
	            display(['skipping: ' inputFilePath])
	        end
	    end
	end

function saveMovieRaw(movieList,options)
    % loads movies in movie list and saves them as raw data

	% g = loadMovieList('B:\data\pav\p104\m999\131003-M999-PAV01\concatenated_recording_20131003_154007.h5','convertToDouble',0);

	inputFilePath = movieList{1};
	options.movieType = 'hdf5';
	thisMovie = loadMovieList(movieList,'movieType',options.movieType,'convertToDouble',0);
    % thisMovie = single(thisMovie);
    %thisMovie = uint16(thisMovie);
    %playMovie(thisMovie);
    savePath = [inputFilePath(1:end-3) '.raw'];

    display(['saving raw: ' savePath]);
	fid = fopen(savePath, 'w');
		fwrite(fid, thisMovie, class(thisMovie));
		fclose(fid);

function saveMovieAvi(movieList,options)

	inputFilePath = movieList{1};
	options.movieType = 'hdf5';
	thisMovie = loadMovieList(movieList,'movieType',options.movieType);

	[pathstr,name,ext] = fileparts(inputFilePath);
	savePath = [pathstr filesep name '.avi'];
	display(['saving as: ' savePath])

	writerObj = VideoWriter(savePath,'Indexed AVI');
	open(writerObj);

	reverseStr = '';
    display(['# frames: ' num2str(length(thisMovie))])
	for iframe=1:length(thisMovie)
		% writeVideo(writerObj,getframe(fig1));
		writeVideo(writerObj,thisMovie(:,:,iframe));

		reverseStr = cmdWaitbar(iframe,nFrames,reverseStr,'inputStr','save avi','waitbarOn',options.waitbarOn,'displayEvery',50);
    end

	close(writerObj);

function saveMovieTiff(movieList,options)
    % loads movies in movie list and saves them as tifs

	inputFilePath = movieList{1};
	options.movieType = 'hdf5';
	thisMovie = loadMovieList(movieList,'movieType',options.movieType);
    thisMovie = single(thisMovie);
    %thisMovie = uint16(thisMovie);
    %playMovie(thisMovie);
    savePath = [inputFilePath(1:end-3) '.tif'];

    TifFile = Tiff(savePath,'w8');
    tagstruct.SampleFormat=3;
    tagstruct.BitsPerSample=32;
    tagstruct.Compression=1;
    tagstruct.ImageLength = size(thisMovie,1);
    tagstruct.ImageWidth = size(thisMovie,2);
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.SamplesPerPixel = 1;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';

    reverseStr = '';
    display(['# frames: ' num2str(length(thisMovie))])
	for i=1:length(thisMovie)
        TifFile.setTag(tagstruct);
        TifFile.write(thisMovie(:,:,i));
        TifFile.writeDirectory();%move ID to next stack image
		%imwrite(uint16(thisMovie(:,:,i)),,'WriteMode', 'append','Compression','none');

        % reduce waitbar access
		reverseStr = cmdWaitbar(iframe,nFrames,reverseStr,'inputStr','save tif','waitbarOn',options.waitbarOn,'displayEvery',50);
    end
    TifFile.close();

function getMovieStatistics(movieList,options,trialRegExp,thisDirSaveStr)
	% plays a movie clip or a side-by-side
	% TODO: should determine which video is longer and downsample that one rather than assume just the video file is the one - DONE

	if ~isempty(options.videoDir)
		vidList = getFileList(options.videoDir,trialRegExp);
		if isempty(vidList)
			display(['cannot find movie: ' options.videoDir '\' trialRegExp]);
			return
        else
            display(['going to load: ' options.videoDir '\' trialRegExp]);
        end
    end

    % get the movie
    primaryMovie = loadMovieList(movieList{1},'convertToDouble',options.convertToDouble,'frameList',options.frameList);
	% [primaryMovie options] = getCurrentMovie(movieList,options);
	lengthMovie = size(primaryMovie,3);

	[~, ~] = openFigure(1776, '');
	subplot(2,1,1)
	plot(squeeze(nanmean(nanmean(primaryMovie,1),2)),'k')
	% title(['mean']);
	ylabel('mean'); box off;
	set(gca,'xlim',[0 lengthMovie]);
	subplot(2,1,2)
	plot(squeeze(nanvar(nanvar(single(primaryMovie),[],1),[],2)),'k')
	% title('variance');
	ylabel('variance');xlabel('frame'); box off;
	set(gca,'xlim',[0 lengthMovie]);
	% suptitle(thisDirSaveStr);
	supHandle = suptitle(trialRegExp);
	set(supHandle, 'Interpreter', 'none');

	% save images
	tmpDirPath = strcat(options.picsSavePath,filesep,'movieStatistics',filesep);
	mkdir(tmpDirPath);
	saveFile = char(strrep(strcat(tmpDirPath,trialRegExp,'.png'),'/',''));
	saveas(gcf,saveFile);

function [options] = playShortClip(movieList,options,trialRegExp,thisDirSaveStr)
	% plays a movie clip or a side-by-side
	% TODO: should determine which video is longer and downsample that one rather than assume just the video file is the one - DONE

	if isempty(options.videoPlayer)
		usrIdxChoiceStr = {'matlab','imagej'};
		scnsize = get(0,'ScreenSize');
		[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which video player to use?');
		options.videoPlayer = usrIdxChoiceStr{sel};
	end

	if ~isempty(options.videoDir)
		vidList = getFileList(options.videoDir,trialRegExp);
		if isempty(vidList)
			display(['cannot find movie: ' options.videoDir '\' trialRegExp]);
			return
        else
            display(['going to load: ' options.videoDir '\' trialRegExp]);
        end
    end

    % get the movie
    primaryMovie = loadMovieList(movieList{1},'convertToDouble',options.convertToDouble,'frameList',options.frameList);
	% [primaryMovie options] = getCurrentMovie(movieList,options);

	if ~isempty(options.videoDir)
		fileToLoad = {strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr}),strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr})};
		variableStruct = loadFileToVariables(fileToLoad,options);
		if any(strcmp('null',fieldnames(variableStruct))); return; else; fn=fieldnames(variableStruct); end;
		for i=1:length(fn); eval([fn{i} '=variableStruct.' fn{i} ';']); end

		% load secondary movie
		secondMovie = loadMovieList(vidList{1},'convertToDouble',options.convertToDouble,'frameList',options.frameList);

		% determine which (and whether) to downsample the movies
		lengthPrimary = size(primaryMovie,3);
		lengthSecond = size(secondMovie,3);
		if lengthPrimary>lengthSecond
			% display(['downsampling: ' movieList{1}]);
			downsampleFactor = lengthPrimary/lengthSecond;
			primaryMovie = downsampleMovie(primaryMovie,'downsampleDimension','time','downsampleFactor',downsampleFactor);
		elseif lengthSecond>lengthPrimary
			% display(['downsampling: ' vidList{1}]);
			downsampleFactor = lengthSecond/lengthPrimary;
			secondMovie = downsampleMovie(secondMovie,'downsampleDimension','time','downsampleFactor',downsampleFactor);
		end

        if exist('IcaTraces','var')
            [signalPeaks, signalPeaksArray] = computeSignalPeaks(IcaTraces, 'makePlots', 0,'makeSummaryPlots',1);
            signalPeaks = sum(spreadSignal(signalPeaks),1);
            [exitSignal movieStruct] = playMovie(primaryMovie,'extraMovie',secondMovie,'extraLinePlot',signalPeaks);
        else
            [exitSignal movieStruct] = playMovie(primaryMovie,'extraMovie',secondMovie);
        end
	else
		switch options.videoPlayer
			case 'matlab'
				[exitSignal movieStruct] = playMovie(primaryMovie,'extraTitleText',thisDirSaveStr);
			case 'imagej'
				Miji;
				MIJ.createImage('result', primaryMovie, true);
				clear primaryMovie;
				uiwait(msgbox('press OK to move onto next movie','Success','modal'));
				MIJ.run('Close');
				MIJ.exit;
			otherwise
				% body
		end
	end


    if exist('movieStruct','var')&any(strcmp('labelArray',fieldnames(movieStruct)))
        labelTable = struct2table(movieStruct.labelArray);
        labelTable
    end

function concatDfofMovies(movieList,trialRegExp,options)
	% concats two movies together by scaling the second to be the same size as the other and reducing their

	% get the movie
	[thisMovie options] = getCurrentMovie(movieList,options);

	% load movement data
	[options.videoDir '\' trialRegExp]
	movList = getFileList(options.trackingDir,trialRegExp)
	if isempty(movList)
		return
	end
	[thisMovie options] = getCurrentMovie(movieList,options);

	figure(564);playMovie(thisMovie,'fps',60);

function [thisMovie options] = getCurrentMovie(movieList,options)
	% get the list of movies to load

	[pathstr,name,ext] = fileparts(movieList{1});
	if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
		options.movieType = 'hdf5';
		% use the faster way to read in image data, especially if only need a subset
		if isempty(options.frameList)
			thisMovie = loadMovieList(movieList,'movieType',options.movieType,'convertToDouble',options.convertToDouble);
		else
			inputFilePath = movieList{1};
			display(['loading: ' inputFilePath]);
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
			nPCs = str2num(dirInfo{2});
			nICs = str2num(dirInfo{3});
		else
			% otherwise, use the default PC/ICs
			nPCs = options.nPCs;
			nICs = options.nICs;
		end
	end

	if strcmp(thisDir(1),'#')
		display([num2str(fileNum) '/' num2str(nFiles) ': skipping: ' thisDir]);
	else
		display([num2str(fileNum) '/' num2str(nFiles) ': ' thisDir ' | ' '# PCs/ICs: ' num2str(nPCs) '/' num2str(nICs)]);
		% nPCs is 1.5*nExpectedCells, so nICs is 2/3 nPCs
		% display(['# PCs/ICs: ' num2str(nPCs) '/' num2str(nICs)])

	end

function [ostruct] = getSubjectInfo(ostruct,nFiles,options,fileNum)
	% obtain information about the subject from a table of subject metadata

	% table should contain columns with names
	% subject (e.g. m756), type (e.g. Drd1a), date (YYYY.MM.DD), pxToCm (e.g. 0.66)
	thisSubj = ostruct.subject{fileNum};
	tmpMatch = regexp(thisSubj,'(m|M|f|F)\d+', 'tokens');
	thisSubjNum = str2num(char(strrep(thisSubj,tmpMatch{1},'')));
	ostruct.data.subject{fileNum,1} = thisSubj;
	if ~isempty(options.subjectTablePath)
        display('extracting table information')
		% get the current subject's information
		if options.skipSubjData==1
			if fileNum==1|~any(strcmp('tables',fieldnames(ostruct)))|~any(strcmp('subjectTable',fieldnames(ostruct.tables)))
	            display(['loading table: ' options.subjectTablePath])
				ostruct.tables.subjectTable = readSubjectTable(options);
			end
			return
		end
		if fileNum==1|~any(strcmp('tables',fieldnames(ostruct)))|~any(strcmp('subjectTable',fieldnames(ostruct.tables)))
            display(['loading table: ' options.subjectTablePath])
			ostruct.tables.subjectTable = readtable(options.subjectTablePath,'Delimiter','comma','FileType','text');
			class(ostruct.tables.subjectTable.trialSet)
			if strcmp(class(ostruct.tables.subjectTable.trialSet),'cell')
            	subjectSetType = strcat(ostruct.tables.subjectTable.type,' ',ostruct.tables.subjectTable.trialSet);
        	else
            	subjectSetType = strcat(ostruct.tables.subjectTable.type,' ',cellfun(@num2str,num2cell(ostruct.tables.subjectTable.trialSet),'uniformoutput',0));
            end
            subjectSetType = ostruct.tables.subjectTable.type;
			% get a unique list of all subject types
            ostruct.lists.subjectType = unique(subjectSetType);
			% ostruct.lists.subjectType = unique(ostruct.tables.subjectTable.type);
			% construct a pseudo-hash table for type to color
			ostruct.lists.typeColors = hsv(length(ostruct.lists.subjectType));
		end
		subjectTable = ostruct.tables.subjectTable;
		% get indicies where subject is present in table
		subjectIdx = subjectTable.subject==thisSubjNum;
		% locate subject type from table
		try
			ostruct.data.subjectType(fileNum,1) = unique(subjectTable.type(subjectIdx));
		catch
			ostruct.data.subjectType(fileNum,1) = unique(subjectTable.type(subjectIdx));
		end
		% get the index of the current trial based on the date
		currentTrialIdx = (subjectTable.subject==thisSubjNum)&(strcmp(strrep(ostruct.info.date{fileNum},'_','.'),subjectTable.date));
		currentTable = subjectTable(currentTrialIdx,:);
		% currentTable.pxToCm(1)
		currentTable = currentTable(1,:);
		% get the current pxToCm conversion
		if strcmp(class(currentTable.pxToCm),'cell')
			ostruct.data.pxToCm(fileNum,1) = str2num(cell2mat(currentTable.pxToCm));
		else
			ostruct.data.pxToCm(fileNum,1) = currentTable.pxToCm(1);
		end

		if strcmp(class(currentTable.trialSet),'cell')
	    	ostruct.data.subjectType(fileNum,1) = strcat(currentTable.type,' ',currentTable.trialSet);
		else
	    	ostruct.data.subjectType(fileNum,1) = strcat(currentTable.type,' ',cellfun(@num2str,num2cell(currentTable.trialSet),'uniformoutput',0));
	    end
	    ostruct.data.type(fileNum,1) = currentTable.type;
	    ostruct.data.trialSet(fileNum,1) = currentTable.trialSet;
	    ostruct.data.subjectType(fileNum,1) = currentTable.type;

	    % SUMMARY_STATS_ADD
	    ostruct.summaryStats.subject{fileNum,1} = ostruct.data.subject{fileNum,1};
	    ostruct.summaryStats.subjectType(fileNum,1) = ostruct.data.subjectType(fileNum,1);
	    ostruct.summaryStats.pxToCm(fileNum,1) = ostruct.data.pxToCm(fileNum,1);
	    ostruct.summaryStats.type(fileNum,1) = currentTable.type;
	    ostruct.summaryStats.trialSet(fileNum,1) = currentTable.trialSet;
	    ostruct.summaryStats.subjectType(fileNum,1) = currentTable.type;
	else
		% ostruct.data.subjectType(fileNum,1) = {ostruct.subjInfo.subjectType{fileNum}};
		% ostruct.data.pxToCm(fileNum,1) = NaN;

		% ostruct.summaryStats.subjectType(fileNum,1) = {ostruct.subjInfo.subjectType{fileNum}};
		ostruct.info.subjectType(fileNum,1) = {ostruct.subjInfo.subjectType{fileNum}};
		% ostruct.summaryStats.pxToCm(fileNum,1) = NaN;

		% if fileNum==1|~any(strcmp('lists',fieldnames(ostruct)))
			emptyIdx = cellfun('length',ostruct.subjInfo.subjectType);
			emptyIdx = emptyIdx>1;
			ostruct.lists.subjectType = unique(ostruct.subjInfo.subjectType(emptyIdx));
			ostruct.lists.typeColors = hsv(length(ostruct.lists.subjectType));
		% end
	end

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
	emOptions.playbackFramerate = options.EM.playbackFramerate;
	emOptions.playTwoMoviesWithContours = options.EM.playTwoMoviesWithContours;

	% compareToICAresults(thisMovie, permute(IcaFilters, [2 3 1]), IcaTraces, emAnalysis.allCellImages(:,:,notZeroIdx), emAnalysis.allCellParams(notZeroIdx,:),emAnalysis.allCellTraces(notZeroIdx,:), emOptions);

	% compareToICAresultsEdit(thisMovie, permute(IcaFilters, [2 3 1]), IcaTraces, emAnalysis.allCellImages(:,:,notZeroIdx), emAnalysis.allCellParams(notZeroIdx,:),emAnalysis.allCellTraces(notZeroIdx,:), emOptions);

    [xCoords yCoords] = findCentroid(IcaFilters);
    iOption.primaryPoint = [xCoords(:) yCoords(:)];
    [xCoords yCoords] = findCentroid(permute(emAnalysis.allCellImages(:,:,notZeroIdx),[3 1 2]));
    iOption.secondaryPoint = [xCoords(:) yCoords(:)];
    iOption.extraMovie = thisMovie;
    playMovie(thisMovie,'options',iOption);

function emLaceyAnalysis(thisDir, thisID, fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr)
	% mini-wrapper to run Lacey's EM code
	%get the list of movies to load
	movieList = getFileList(thisDir, fileFilterRegexp);
	% skip if folder is empty
	if isempty(movieList)
		display('empty folder, skipping...')
		return;
	end

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

	emOptions.dsMovieDatasetName = options.datasetName;
	emOptions.movieDatasetName = options.datasetName;
	movieList = getFileList(thisDir, fileFilterRegexp);
	% upsampledMovieList = getFileList(thisDir, fileFilterRegexp);
	[emAnalysis] = EM_CellFind_Wrapper(movieList{1},[],'options',emOptions);

	% save ICs
	saveID = {options.emSaveRaw};
	saveVariable = {'emAnalysis'};
	for i=1:length(saveID)
		savestring = [thisDirSaveStr saveID{i}];
		display(['saving: ' savestring])
		save(savestring,saveVariable{i},'-v7.3');
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

    %
    % load movie?
    usrIdxChoiceStr = {'do not load movie','load movie'};
    [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
    usrIdxChoiceList = {1,2};
    usrIdxChoice = usrIdxChoiceList{sel};
    if usrIdxChoice==2
        %get the list of movies to load
        movieList = getFileList(thisDir, options.fileFilterRegexp);
        % load movies
        [iOptions.inputMovie o m n] = loadMovieList(movieList);
    else

    end

	notZeroIdx = find(sum(emAnalysis.allCellTraces,2)>0);

    iOptions.inputStr = [' ' fileInfo.subject '\_' fileInfo.assay];
    iOptions.valid = valid;
    iOptions.sortBySNR = 1;
    inputImages = permute(emAnalysis.eventTrigImages,[3 1 2]);
    % inputImages = permute(emAnalysis.allCellImages,[3 1 2]);
    inputImages(isnan(inputImages)) = 0;
	[emAnalysis.allCellImages emAnalysis.allCellTraces emAnalysis.valid] = signalSorter(inputImages, emAnalysis.allCellTraces, thisID, [],'options',iOptions);
    % convert back to normal
    emAnalysis.allCellImages = permute(emAnalysis.allCellImages, [2 3 1]);
	% commandwindow;

    % save sorted
    if options.viewer==0
        saveID = {options.emSaveSorted}
        saveVariable = {'emAnalysis'}
        for i=1:length(saveID)
            savestring = [thisDirSaveStr saveID{i}];
            display(['saving: ' savestring])
            save(savestring,saveVariable{i});
        end
    end

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

	% [thisMovie movieDims Npixels Ntime] = loadMovieList(movieList);

	% normalize movie
	% inputOptions.normalizationType = 'imfilter';
	% thisMovie = normalizeMovie(thisMovie,'options',inputOptions);
	% ioptions.freqLow = 7;
	% ioptions.freqHigh = 500;
	% ioptions.normalizationType = 'fft';
	% ioptions.bandpassType = 'highpass';
	% ioptions.showImages = 0;
	% [thisMovie] = normalizeMovie(thisMovie,'options',ioptions);

	nPCs
	nICs

	% run PCA
	% [PcaFilters PcaTraces] = runPCA(thisMovie, thisID, nPCs, fileFilterRegexp);
	[PcaFilters PcaTraces] = runPCA(movieList, thisID, nPCs, fileFilterRegexp);

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
		% reorder if needed
		options.IcaSaveDimOrder = 'zxy';
		if strcmp(options.IcaSaveDimOrder,'xyz')
			IcaFilters = permute(IcaFilters,[2 3 1]);
			imageSaveDimOrder = 'xyz';
		else
			imageSaveDimOrder = 'zxy';
		end
		% save ICs
		saveID = {options.rawICfiltersSaveStr,options.rawICtracesSaveStr}
		saveVariable = {'IcaFilters','IcaTraces'}
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			save(savestring,saveVariable{i},'imageSaveDimOrder','nPCs','nICs');
		end
	end

function applyImagesToMovieController(thisDir, thisID, fileFilterRegexp, options, nPCs, nICs, thisDirSaveStr)

	%get the list of movies to load
	movieList = getFileList(thisDir, fileFilterRegexp);
	% skip if folder is empty
	if isempty(movieList)
		display('empty folder, skipping...')
		return;
	end
	[inputMovie movieDims Npixels Ntime] = loadMovieList(movieList);

	filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr});
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

	[IcaTraces] = applyImagesToMovie(IcaFilters,inputMovie);
	% save sorted ICs
	saveID = {options.rawICtracesAppliedSaveStr}
	saveVariable = {'IcaTraces'}
	for i=1:length(saveID)
		savestring = [thisDirSaveStr saveID{i}];
		display(['saving: ' savestring])
		save(savestring,saveVariable{i});
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

function ICAChooser(thisDir, thisDirSaveStr,thisID,fileInfo,options,ostruct, varargin)
	options.viewer = 0;
	% get options
    options = getOptions(options,varargin);

    usrIdxChoiceStr = {'load movie','do not load movie'};
    [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
    usrIdxChoiceList = {2,1};
    usrIdxChoiceMovie = usrIdxChoiceList{sel};

    usrIdxChoiceStr = {'do not classify','classify'};
    [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
    usrIdxChoiceList = {1,2};
    usrIdxChoiceClassification = usrIdxChoiceList{sel};

    % load the PC filters and traces
    if options.useAppliedICs==1
        filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesAppliedSaveStr});
    else
        filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
    end

    for i=1:length(filesToLoad)
        display(['loading: ' filesToLoad{i}]);
        load(filesToLoad{i})
    end

    % load movie?
    if usrIdxChoiceMovie==2
        %get the list of movies to load
        movieList = getFileList(thisDir, options.fileFilterRegexp);
        % load movies
        [iOptions.inputMovie o m n] = loadMovieList(movieList);
    else

    end

	% check if the folder has temporary decisions to load (e.g. if a crash occured)
	tmpDecisionList = getFileList(thisDir, 'tmpDecision');
	previousDecisionList = getFileList(thisDir, options.cleanedICdecisionsSaveStr);
	if ~isempty(tmpDecisionList)&isempty(previousDecisionList)
		display(['loading temp decisions: ' tmpDecisionList{1}])
		load(tmpDecisionList{1});
	elseif ~isempty(previousDecisionList)
		display(['loading previous decisions: ' previousDecisionList{1}])
		load(previousDecisionList{1});
	else
		valid = [];
	end

    ostruct.inputImages{ostruct.counter} = IcaFilters;
    ostruct.inputSignals{ostruct.counter} = IcaTraces;
    ostruct.validArray{ostruct.counter} = valid;

    if exist(options.classifierFilepath, 'file')&usrIdxChoiceClassification==2
        display(['loading: ' options.classifierFilepath]);
        load(options.classifierFilepath)
        options.trainingOrClassify = 'classify';
        ioption.classifierType = options.classifierType;
        ioption.trainingOrClassify = options.trainingOrClassify;
        ioption.inputTargets = {ostruct.validArray{ostruct.counter}};
        ioption.inputStruct = classifierStruct;
        [ostruct.classifier] = classifySignals({ostruct.inputImages{ostruct.counter}},{ostruct.inputSignals{ostruct.counter}},'options',ioption);
        valid = ostruct.classifier.classifications;
        % originalValid = valid;
        validNorm = normalizeVector(valid,'normRange','oneToOne');
        validDiff = [0 diff(valid')];
        %
        figure(100020);close(100020);figure(100020);
        plot(valid);hold on;
        plot(validDiff,'g');
        %
        % validQuantiles = quantile(valid,[0.4 0.3]);
        % validHigh = validQuantiles(1);
        % validLow = validQuantiles(2);
        validHigh = 0.7;
        validLow = 0.5;
        %
        valid(valid>=validHigh) = 1;
        valid(valid<=validLow) = 0;
        valid(isnan(valid)) = 0;
        % questionable classification
        valid(validDiff<-0.3) = 2;
        valid(valid<validHigh&valid>validLow) = 2;
        %
        plot(valid,'r');
        plot(validNorm,'k');box off;
        legend({'scores','diff(scores)','classification','normalized scores'})
        % valid
    else
        display(['no classifier at: ' options.classifierFilepath])
    end

    iOptions.inputStr = [' ' fileInfo.subject '\_' fileInfo.assay];
    iOptions.valid = valid;
    % iOptions.classifierFilepath = options.classifierFilepath;
    % iOptions.classifierType = options.classifierType;
	[IcaFilters IcaTraces valid] = signalSorter(IcaFilters, IcaTraces, thisID, [],'options',iOptions);
	% commandwindow;

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
    ostruct.counter = ostruct.counter + 1;

function [ostruct] = identifyNeighbors(ostruct,fileNum,thisDirSaveStr,options)
	% load the PC filters and traces
	% filesToLoad=strcat(thisDirSaveStr, {cleanedICfiltersSaveStr,cleanedICtracesSaveStr});
	filesToLoad=strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr});
	% if bad ICs haven't been removed yet, use the raw
	if(~exist(filesToLoad{1}, 'file'))
		% filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
		filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
		if(~exist(filesToLoad{1}, 'file'))
			return
		end
	end
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
		ostruct.neighborsCell{fileNum} = identifyNeighborsAuto(IcaFilters, IcaTraces);

		neighborsToSave = ostruct.neighborsCell{fileNum};
		saveID = {options.neighborsSaveStr};
		saveVariable = {'neighborsToSave'};
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			save(savestring,saveVariable{i});
		end
	end

	viewNeighborsAuto(IcaFilters, IcaTraces, neighborsToSave);

function [ostruct] = viewPeakMontages(ostruct, options, movieList, fileNum, nFiles, thisDirSaveStr)
	filesToLoad=strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr});
	% if bad ICs haven't been removed yet, use the raw
	if(~exist(filesToLoad{1}, 'file'))
		% filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
		filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
		if(~exist(filesToLoad{1}, 'file'))
			return
		end
	end
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

	primaryMovie = loadMovieList(movieList{1},'convertToDouble',options.convertToDouble,'frameList',options.frameList);

	nSignals = size(IcaTraces,1);
	minValTraces = min(IcaTraces(:));
	if minValTraces<-0.05
	    minValTraces = -0.05;
	end
	maxValTraces = max(IcaTraces(:));
	if maxValTraces>0.4|maxValTraces<0.3
	    maxValTraces = 0.35;
	end
	[signalSpikes, signalSpikesArray] = computeSignalPeaks(IcaTraces, 'makePlots', 0,'makeSummaryPlots',0);
	for i = 1:nSignals
		thisTrace = IcaTraces(i,:);
		testpeaks = signalSpikesArray{i};
		croppedPeakImages = compareSignalToMovie(primaryMovie, IcaFilters(i,:,:), thisTrace,'getOnlyPeakImages',1,'waitbarOn',0,'extendedCrosshairs',0);
		% display cropped images
		% figure(3)
			% imagesc(croppedPeakImages(:,:,1))
		figure(2);
		subplot(2,1,1)
			croppedPeakImages2(:,:,:,1) = croppedPeakImages;
			warning off
			montage(permute(croppedPeakImages2(:,:,:,1),[1 2 4 3]))
			croppedPeakImages2 = getimage;
			% change zeros to ones, fixes range of image display
			croppedPeakImages2(croppedPeakImages2==0)=NaN;
		subplot(2,1,1)
			imagesc(croppedPeakImages2); colormap jet; title([ num2str(i) '/' num2str(nSignals) ' frames at signal peaks, first is image filter']); axis off
			customColors = customColormap([]);
			colormap(customColors);
		subplot(2,1,2)
			% plots a signal along with test peaks
			hold off;
			plot(thisTrace, 'r');
			hold on;
			scatter(testpeaks, thisTrace(testpeaks), 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0])
			% title(['signal ' cellIDStr instructionStr])
			xlabel('frames');ylabel('df/f');
			axis([0 length(thisTrace) minValTraces maxValTraces]);
			box off;
			hold off;
		% close(2);figure(mainFig);
		clear croppedPeakImages2
		warning on
		ginput(1);
	end

function [ostruct] = computePeaks(ostruct, options, fileNum, nFiles, thisDirSaveStr)
	filesToLoad=strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr});
	% if bad ICs haven't been removed yet, use the raw
	if(~exist(filesToLoad{1}, 'file'))
		% filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
		filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
		if(~exist(filesToLoad{1}, 'file'))
			return
		end
	end
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

	[IcaFilters, IcaTraces, valid, imageSizes] = filterImages(IcaFilters, IcaTraces);
	if sum(strcmp('subjectType',fieldnames(ostruct.data)))>0
		thisID = strcat(ostruct.subject{fileNum},'\_',ostruct.data.subjectType(fileNum),'\_',ostruct.assay{fileNum});
		% thisFileID = 'all';
	else
		thisID = strcat(ostruct.subject{fileNum},'\_',ostruct.assay{fileNum});
	end
	thisFileID = strrep('thisID','\','');
	% only take top 50% of ICs
	% filterNum = round(quantile(1:size(IcaTraces,1),0.5));
	% IcaTraces = IcaTraces(1:filterNum,:);
	[signalSpikes, signalSpikesArray] = computeSignalPeaks(IcaTraces, 'makePlots', 0,'makeSummaryPlots',1);
	nSignals = size(signalSpikes,1);

	[peakOutputStat] = computePeakStatistics(IcaTraces,'testpeaks',signalSpikes,'testpeaksArray',signalSpikesArray);
	[signalSnr a] = computeSignalSnr(IcaTraces,'testpeaks',signalSpikes,'testpeaksArray',signalSpikesArray);
	% =====================
	% make separate function
	% [signalSpikes, signalSpikesArray] = computeSignalPeaks(IcaTraces, 'makePlots', 0,'makeSummaryPlots',1);
	[r p] = corrcoef(signalSpikes(1:end,:)');
	corrLinkage = linkage(r,'average','euclidean');
	% corrLinkage
	% dendrogram(corrLinkage);
	% pause
	maxNumClusters = 10;
	% spikeCorrClusters = cluster(corrLinkage,'maxclust',maxNumClusters);
	spikeCorrClusters = cluster(corrLinkage,'cutoff',1.445,'criterion','distance');
	nSpikeCorrClusters = length(unique(spikeCorrClusters));
	[Y,idx] = sort(spikeCorrClusters,1,'ascend');
	correlationMatrixSorted = r(idx,idx);
	correlationMatrixSorted(correlationMatrixSorted==1) = NaN;
	[objmapSpikeCorrClusters] = groupImagesByColor(IcaFilters,spikeCorrClusters);
	objmapSpikeCorrClusters = createObjMap(objmapSpikeCorrClusters);
	objmapSpikeCorrClusters(1,1) = maxNumClusters;
	% imagesc(tmpR);colorbar
	% =====================
	signalSpikesSum = sum(signalSpikes,1);
	ostruct.signalSpikes{fileNum} = signalSpikes;
	ostruct.signalMatrix{fileNum} = IcaTraces;
	ostruct.fwhmSignal{fileNum} = peakOutputStat.fwhmSignal;
	ostruct.signalSnr{fileNum} = signalSnr;
	% =====================
	% smooth signal by a frame for simultaneous firing
	class(signalSpikes)
	signalSpikesSpread = spreadSignal(signalSpikes,'timeSeq',[-2:2]);
	display('shuffling signal matrix');
	signalSpikesSpreadShuffled = spreadSignal(shuffleMatrix(signalSpikes),'timeSeq',[-2:2]);
	% =====================
	% firing rate grouped images
	numPeakEvents = sum(signalSpikes,2);
	numPeakEvents = numPeakEvents/size(signalSpikes,2)*options.framesPerSecond;
	[objmapNumPeakEvents] = groupImagesByColor(IcaFilters,numPeakEvents);
	objmapNumPeakEvents = createObjMap(objmapNumPeakEvents);
	% to normalize across animals
	objmapNumPeakEvents(1,1) = 0.035;
	% =====================
	% save summmary statistics
	if ~any(strcmp('summaryStats',fieldnames(ostruct)))|~any(strcmp('subject',fieldnames(ostruct.summaryStats)))
		ostruct.summaryStats.subject{1,1} = nan;
		ostruct.summaryStats.assay{1,1} = nan;
		ostruct.summaryStats.assayType{1,1} = nan;
		ostruct.summaryStats.assayNum{1,1} = nan;
		ostruct.summaryStats.firingRateMean{1,1} = nan;
		ostruct.summaryStats.firingRateMedian{1,1} = nan;
		ostruct.summaryStats.firingRateStd{1,1} = nan;
		ostruct.summaryStats.meanSpikesCell{1,1} = nan;
		ostruct.summaryStats.syncActivityMean{1,1} = nan;
		ostruct.summaryStats.syncActivityMax{1,1} = nan;
		ostruct.summaryStats.fwhmMean{1,1} = nan;
		ostruct.summaryStats.numObjs{1,1} = nan;
		ostruct.summaryStats.nSpikeCorrClusters{1,1} = nan;
	end
	ostruct.summaryStats.subject{end+1,1} = ostruct.info.subject{fileNum};
	ostruct.summaryStats.assay{end+1,1} = ostruct.info.assay{fileNum};
	ostruct.summaryStats.assayType{end+1,1} = ostruct.info.assayType{fileNum};
	ostruct.summaryStats.assayNum{end+1,1} = ostruct.info.assayNum{fileNum};
	ostruct.summaryStats.firingRateMean{end+1,1} = nanmean(sum(signalSpikes,2)/size(signalSpikes,2)*options.framesPerSecond);
	ostruct.summaryStats.firingRateMedian{end+1,1} = median(sum(signalSpikes,2)/size(signalSpikes,2)*options.framesPerSecond);
	ostruct.summaryStats.firingRateStd{end+1,1} = nanstd(sum(signalSpikes,2)/size(signalSpikes,2)*options.framesPerSecond);
	ostruct.summaryStats.meanSpikesCell{end+1,1} = nanmean(sum(signalSpikes,2));
	ostruct.summaryStats.syncActivityMean{end+1,1} = nanmean(sum(signalSpikesSpread,1));
	ostruct.summaryStats.syncActivityMax{end+1,1} = nanmax(sum(signalSpikesSpread,1));
	ostruct.summaryStats.fwhmMean{end+1,1} = nanmean(ostruct.fwhmSignal{fileNum});
	ostruct.summaryStats.numObjs{end+1,1} = nSignals;
	ostruct.summaryStats.nSpikeCorrClusters{end+1,1} = nSpikeCorrClusters;


	% ostruct.summaryStats
	movTable = struct2table(ostruct.summaryStats);
	writetable(movTable,char(['private\data\' ostruct.info.protocol{fileNum} '_summary_peaks.tab']),'FileType','text','Delimiter','\t');
	% =====================
	% save big data statistics
	ostruct.counter
	if ostruct.counter==1
	    ostruct.bigData.frame = [];
	    ostruct.bigData.value = [];
	    ostruct.bigData.varType = {};
	    % ostruct.bigData.subjectType = {};
	    ostruct.bigData.subject = {};
	    ostruct.bigData.assay = {};
	    ostruct.bigData.assayType = {};
	    ostruct.bigData.assayNum = {};
	end
	maxH = max(sum(signalSpikesSpread,1));
	histBins = [0:maxH];
	histCountsShuffle = hist(sum(signalSpikesSpreadShuffled,1),histBins);
	histCountsShuffleNorm = histCountsShuffle/sum(histCountsShuffle);

	histCounts = hist(sum(signalSpikesSpread,1),histBins)-histCountsShuffle;
	histHNorm = histCounts/sum(histCounts(histCounts>0));

	% tmpSubjInfo = [ostruct.info.subject{fileNum} ostruct.info.assayType{fileNum} ostruct.info.assayNum{fileNum}];
	frame = histBins;
	value = histHNorm;
	varType = 'simultaneousfiringEventsDist';
	numPtsToAdd = length(frame(:));
	ostruct.bigData.frame(end+1:end+numPtsToAdd,1) = frame(:);
	ostruct.bigData.value(end+1:end+numPtsToAdd,1) = value(:);
	ostruct.bigData.varType(end+1:end+numPtsToAdd,1) = {varType};
	% ostruct.bigData.subjectType(end+1:end+numPtsToAdd,1) = subjectType;
	ostruct.bigData.subject(end+1:end+numPtsToAdd,1) = {ostruct.info.subject{fileNum}};
	ostruct.bigData.assay(end+1:end+numPtsToAdd,1) = {ostruct.info.assay{fileNum}};
	ostruct.bigData.assayType(end+1:end+numPtsToAdd,1) = {ostruct.info.assayType{fileNum}};
	ostruct.bigData.assayNum(end+1:end+numPtsToAdd,1) = {ostruct.info.assayNum{fileNum}};
	% =====================
	% look at the pairwise correlation between the neurons
	% z=xcorr(signalSpikes');
	% z0 = zeros(size(signalSpikes',2));
	% zMax = max(z);
	% z0 = reshape(zMax, [size(z0)]);
	% figure(9000)
	% 	imagesc(z0); colormap jet;

	% z=xcorr(IcaTraces');
	% z0 = zeros(size(IcaTraces',2));
	% zMax = max(z);
	% z0 = reshape(zMax, [size(z0)]);
	% figure(90001)
	% 	imagesc(z0); colormap jet;
	% =====================
	if sum(strcmp('subjectType',fieldnames(ostruct.data)))>0
		colorIdx = strcmp(ostruct.data.subjectType(fileNum,1),ostruct.lists.subjectType);
		subjColor = ostruct.lists.typeColors(colorIdx,:);
		subjectTypeList = ostruct.lists.subjectType;
		typeColorsList = ostruct.lists.typeColors;
	else
		ostruct.lists.assayType = unique(ostruct.subjInfo.subjectType);
		subjectTypeList = ostruct.lists.assayType;
		ostruct.lists.typeColors = hsv(length(ostruct.lists.assayType));
		typeColorsList = ostruct.lists.typeColors;
		colorIdx = strcmp(ostruct.subjInfo.subjectType{fileNum},ostruct.lists.assayType);
		subjColor = ostruct.lists.typeColors(colorIdx,:);
		% subjectTypeList = {ostruct.subject{fileNum}};
		% typeColorsList = hsv(1);
	end
	% subjColor

	figNo = 139;
	if ostruct.counter==1|~any(strcmp('plots',fieldnames(ostruct)))
		ostruct.plots.figCount = 0;
		ostruct.plots.plotCount = 1;
		ostruct.plots.sheight = 3;
		ostruct.plots.swidth = 3;
	end
	[figHandle2 figNo2] = openFigure(91000+ostruct.plots.figCount, '');
		subplot(ostruct.plots.sheight,ostruct.plots.swidth,ostruct.plots.plotCount);
		imagesc(objmapNumPeakEvents); axis off; box off;
		colormap(ostruct.colormap);
		if ostruct.plots.plotCount==1
			cb = colorbar;
		end
		% cb = colorbar('location','southoutside');
		% if ostruct.plots.plotCount==1
			% colorbar
		% end
		title(thisID);
		hold on;
		suptitle('object maps: firing rate');
		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_cellmaps',num2str(ostruct.plots.figCount),'.png'),'/',''));
		saveas(gcf,saveFile);

	[figHandle2 figNo2] = openFigure(92000+ostruct.plots.figCount, '');
		subplot(ostruct.plots.sheight,ostruct.plots.swidth,ostruct.plots.plotCount);
		imagesc(objmapSpikeCorrClusters); axis off; box off;
		colormap(ostruct.colormap);
		if ostruct.plots.plotCount==1
			cb = colorbar;
		end
		title(thisID);
		hold on;
		suptitle('object maps: spike correlation clusters');
		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_cluster_cellmaps',num2str(ostruct.plots.figCount),'.png'),'/',''));
		saveas(gcf,saveFile);

	[figHandle2 figNo2] = openFigure(93000+ostruct.plots.figCount, '');
		subplot(ostruct.plots.sheight,ostruct.plots.swidth,ostruct.plots.plotCount);
		imagesc(correlationMatrixSorted);
		axis off; box off;
		colormap(ostruct.colormap);
		if ostruct.plots.plotCount==1
			cb = colorbar;
		end
		title(thisID);
		hold on;
		suptitle('spike correlation clusters');
		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_correlations',num2str(ostruct.plots.figCount),'.png'),'/',''));
		saveas(gcf,saveFile);

	[figHandle figNo] = openFigure(figNo, '');
		for i = 1:2
			subplot(2,1,i);
			if i==1
				[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
			end
			% signalStd = std(sum(signalSpikes,2));
			% signalMean = mean(sum(signalSpikes,2));
			if i==1
				histBins = 30;
				allSignalsHz = sum(signalSpikes,2)/size(signalSpikes,2)*options.framesPerSecond;
				[histCounts histBins] = hist(allSignalsHz,histBins);
				histCounts = histCounts/sum(histCounts);
				phandle = plot(histBins, histCounts, 'Color',subjColor);box off;
				title(['firing rate distribution']);
				xlabel('firing rate (spikes/second)');ylabel('count');
			else
				histBins = [0:5:100];
				histCounts = hist(sum(signalSpikes,2),histBins);
				phandle = plot(histBins, histCounts, 'Color',subjColor);box off;
				title(['distribution total peaks']);
				xlabel('total spikes per cell');ylabel('count');
			end
			% title(['distribution total peaks, individual signals: std=' num2str(signalStd) ', mean=' num2str(signalMean)]);
			hold on;
		end
		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_firingRate.png'),'/',''));
		saveas(gcf,saveFile);

	[figHandle figNo] = openFigure(figNo, '');
		% subplot(5,ceil(nFiles/5),fileNum);
		for i = 1:4
			subplot(2,2,i);
			if i==1
				[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
			end
			maxFWHM = max(ostruct.fwhmSignal{fileNum});
			histFWHM = hist(ostruct.fwhmSignal{fileNum},[0:nanmax(ostruct.fwhmSignal{fileNum})]); box off;
			if i==3|i==4
				histFWHM = histFWHM/sum(histFWHM);
			end
			phandle = plot([0:nanmax(ostruct.fwhmSignal{fileNum})], histFWHM, 'Color',subjColor);box off;
			xlabel('fwhm (frames)'); ylabel('count');
			if i==2|i==4
				set(gca,'YScale','log');
			end
			hold on;
			title('spike full-width half-maximums')
		end
		% suptitle('full-width half-maximum for detected spikes'); hold on;
		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_fwhm.png'),'/',''));
		saveas(gcf,saveFile);

	[figHandle figNo] = openFigure(figNo, '');
		[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
		phandle = plot(ostruct.signalSnr{fileNum}, 'Color',subjColor);box off;
		% phandle = plot([0:nanmax(ostruct.fwhmSignal{fileNum})], histFWHM, 'Color',subjColor);box off;
		xlabel('rank'); ylabel('SNR');
		hold on;
		title('signal SNR')
		% suptitle('full-width half-maximum for detected spikes'); hold on;
		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_SNR.png'),'/',''));
		saveas(gcf,saveFile);

	maxH = max(sum(signalSpikesSpread,1));
	histBins = [0:maxH];

	histCountsShuffle = hist(sum(signalSpikesSpreadShuffled,1),histBins);
	histCountsShuffleNorm = histCountsShuffle/sum(histCountsShuffle);

	histCounts = hist(sum(signalSpikesSpread,1),histBins)-histCountsShuffle;
	histHNorm = histCounts/sum(histCounts(histCounts>0));
	[figHandle figNo] = openFigure(figNo, '');
		for i = 1:2
			subplot(1,2,i);
			if i==1
				[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
			end
			phandle = plot(histBins, histCounts, 'Color',subjColor);box off;
			% plot shuffle
			% plot(histBins, histCountsShuffle, 'Color',subjColor,'LineStyle','--');box off;
			title('simultaneous firing events (counts), dashed = randomly shift spike trains');
			xlabel('simultaneous spikes');ylabel('count');
			if i==2
				set(gca,'YScale','log');
			end
			hold on;
		end
		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_simSpikesUnorm.png'),'/',''));
		saveas(gcf,saveFile);
		% suptitle('simultaneous firing events (counts), dashed = randomly shift spike trains'); hold on;
	[figHandle figNo] = openFigure(figNo, '');
		for i = 1:2
			subplot(1,2,i);
			if i==1
				[legendHandle] = groupColorLegend(subjectTypeList,typeColorsList);
			end
			phandle = plot(histBins, histHNorm, 'Color',subjColor);box off;
			% plot shuffle
			% plot(histBins, histCountsShuffleNorm, 'Color',subjColor,'LineStyle','--');box off;
			title('simultaneous firing events (normalized), dashed = randomly shift spike trains');
			xlabel('simultaneous spikes');ylabel('%');
			if i==2
				set(gca,'YScale','log');
			end
			hold on;
		end
		saveFile = char(strrep(strcat(options.picsSavePath,thisFileID,'_simSpikesNorm.png'),'/',''));
		saveas(gcf,saveFile);
		% suptitle('simultaneous firing events (normalized), dashed = randomly shift spike trains'); hold on;
		% if fileNum==nFiles
			% saveFile = char(strrep(strcat(options.picsSavePath,'all_cumMovement_.png'),'/',''));
			% saveas(gcf,saveFile);
		% end
		% signalSpikesMore

	if mod(ostruct.plots.plotCount,ostruct.plots.sheight*ostruct.plots.swidth)==0
	   ostruct.plots.figCount = ostruct.plots.figCount+1;
	   ostruct.plots.plotCount = 1;
	else
	   ostruct.plots.plotCount = ostruct.plots.plotCount+1;
	end

	[figHandle figNo] = openFigure(figNo, '');
	if fileNum==nFiles
		ostruct.signalMean = cell2mat(arrayfun(@(x) mean(sum(x{1},2)), ostruct.signalSpikes, 'UniformOutput', false));
		ostruct.signalStd = cell2mat(arrayfun(@(x) std(sum(x{1},2)), ostruct.signalSpikes, 'UniformOutput', false));
			plot(ostruct.signalMean); hold on; box off;
			plot(ostruct.signalStd,'r');
			title('spikes per cell over entire trial');
			xlabel('trialNum');ylabel('mean/std of trial spikes');
			legend({'mean', 'std'});
			drawnow
	end

function [vs] = loadFileToVariables(fileToLoad,options)
	% fileToLoad = cell array of cell arrays containing strings of paths to files, first cell is primary, secondary is loaded if primary don't exist, and so on

	% look for clean filters
	filesToLoad=fileToLoad{1};
	rawFiles = 0;
	vs.null = [];
	% if bad ICs haven't been removed yet, use the raw
	if(~exist(filesToLoad{1}, 'file'))
	    % filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
	    filesToLoad=fileToLoad{2};
	    rawFiles = 1;
	    if(~exist(filesToLoad{1}, 'file'))
	    	display('no files');
	        return
	    end
	end
	for i=1:length(filesToLoad)
	    display(['loading: ' filesToLoad{i}]);
	    tmpStruct = load(filesToLoad{i});
	    [vs] = mergeStructs(tmpStruct,vs,0);
	end
	vs = rmfield(vs,'null')

	% if ~exist('IcaFilters','var')
	% should make this dynamic....
	if any(strcmp('IcaFilters',fieldnames(vs)))&any(strcmp('IcaTraces',fieldnames(vs)))
		% check that files are real
		if ~isreal(vs.IcaFilters)|~isreal(vs.IcaTraces)
			display('complex matrix, exiting...')
			vs = 0;
			return
		end
		if rawFiles==1
			% [vs.IcaFilters, vs.IcaTraces, vs.valid, vs.imageSizes] = filterImages(vs.IcaFilters, vs.IcaTraces);
		end
        % =====================
		% get signal peaks
		[vs.signalPeaks, vs.signalPeakIdx] = computeSignalPeaks(vs.IcaTraces,'makePlots',0,'makeSummaryPlots',0);
		vs.signalPeaksShuffled = shuffleMatrix(vs.signalPeaks);
	end


function [ostruct] = stimTriggeredAverage(ostruct, options, fileNum, nFiles, thisDirSaveStr,trialRegExp)
	% gets the average of a stimulus input, specific to pavlovian conditioning for the moment, to be generalized

	if ostruct.counter==1
        usrIdxChoiceStr = {'dF/F analysis','spike analysis'};
        [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
        usrIdxChoiceList = {1,0};
        options.dfofAnalysis = usrIdxChoiceList{sel};
        ostruct.options.dfofAnalysis = options.dfofAnalysis;
    else
    	options.dfofAnalysis = ostruct.options.dfofAnalysis;
	end

	% get the current subject's information
	if fileNum==1|~any(strcmp('tables',fieldnames(ostruct)))|~any(strcmp('subjectTable',fieldnames(ostruct.tables)))
		% ostruct.tables.subjectTable = readtable(options.subjectTablePath,'Delimiter','comma','FileType','text');
        display(['loading subj table: ' options.subjectTablePath])
		ostruct.tables.subjectTable = readSubjectTable(options);
		ostruct.counter = 1;
	end
	% for each stimuli, align to data and save the figure
	try
		% =======
		ostruct.lists.assay{ostruct.counter} = ostruct.assay{fileNum};
		ostruct.curentSubject = ostruct.subject{fileNum};
		% information to use in this run
		thisID = strcat(ostruct.subject{fileNum},'\_',ostruct.assay{fileNum});
		thisFileID = strcat(ostruct.subject{fileNum},'_',ostruct.assay{fileNum});
		nameArray = strrep(options.stimNameArray,'_',' ');
		saveNameArray = options.stimNameArray;
		idArray = options.stimIdNumArray;
		% get subject and assay
		thisSubj = ostruct.subject{fileNum};
		tmpMatch = regexp(thisSubj,'(m|M|f|F)\d+', 'tokens');
		subject = str2num(char(strrep(thisSubj,tmpMatch{1},'')));
		assay = ostruct.assay{fileNum};
		% some info specific to this run
		framesPerSecond = options.framesPerSecond;
		timeSeq = options.timeSeq;
		% timeSeq = [-200:200];
		timeSeq = [-50:50];
		usTimeAfterCS = options.usTimeAfterCS;
		assayTable = ostruct.tables.subjectTable;
        assayTable(end-1:end,:)
        if ~any(strcmp('subject',fieldnames(assayTable)))
            assayTable.subject = assayTable.mouse;
        end
        if ~any(strcmp('trial',fieldnames(assayTable)))
            assayTable.trial = assayTable.pav;
        end
		% =====================
		% make figures
		if fileNum==1|~any(strcmp('loopFig',fieldnames(ostruct)))
			ostruct.loopFig = figure(1);
			ostruct.endFig = figure(2);
		end
		% =====================
		% loop over all types of stimuli, align signals to them
		nIDs = length(idArray);
		colorArray = hsv(nIDs);
		idNumCounter = 1;
		for idNum = 1:nIDs
			display(repmat('=',1,21))
            display(['analyzing ' nameArray{idNum}])
            % ===============================================================
			% fix for assay notation differences
			if strfind(assay,'10')
				assayIdx = strcmp(assay,assayTable.trial);
			else
				assayIdx = strcmp(strrep(assay,'0',''),strrep(assayTable.trial,'0',''));
			end
			% ===============================================================
			% obtain the table containing information about the subject
			subjIdx = assayTable.subject==subject;
			subjectTable = assayTable(find(assayTable.events==idArray(idNum)&assayIdx&subjIdx),:);
			% hack for pavlovian conditioning
			if isempty(subjectTable)&idArray(idNum)==31
				subjectTable = assayTable(find(assayTable.events==30&assayIdx&subjIdx),:);
				subjectTable.time = subjectTable.time + usTimeAfterCS;
				subjectTable.frame = subjectTable.frame + usTimeAfterCS*framesPerSecond;
			end
            if ~any(strcmp('frame',fieldnames(subjectTable)))
                subjectTable.frame = round(subjectTable.time*framesPerSecond);
            end
            % check values
            if isempty(subjectTable.frame)
            	display(['no stimuli in trial, skipping...'  nameArray{idNum}])
            	continue
            else
            	display('loaded trial stimulus data')
            end
            % ===============================================================
            % GET TRACES
            if ~exist('IcaFilters','var')
	            fileToLoad = {strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr}),strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr})};
	            variableStruct = loadFileToVariables(fileToLoad,options);
	            if any(strcmp('null',fieldnames(variableStruct))); return; else; fn=fieldnames(variableStruct); end;
	            for i=1:length(fn); eval([fn{i} '=variableStruct.' fn{i} ';']); end
	    	end
            % ===============================================================
            if options.dfofAnalysis==1
            	signalPeaksTwo = IcaTraces;
            else
            	signalPeaksTwo = signalPeaks;
            end
			nTrialPts = size(signalPeaksTwo,2)
			stimVector = zeros(1,nTrialPts);
			% remove zeros
			% subjectTable.frame
			% subjectTable
			stimFrames = subjectTable.frame;
			subjectTable = subjectTable(stimFrames~=0,:);
			stimVector(subjectTable.frame) = 1;
			display('created stimulus vector')
			% ===============================================================
			% cascade through stim onset, offset, etc.
			offset = 5;
			display('cleaning up stimulus vector')
			if options.stimTriggerOnset==1
				stimVectorSpread = spreadSignal(stimVector,'timeSeq',[0:offset]);
				stimVectorSpread = diff(stimVectorSpread);
				stimVectorSpread(stimVectorSpread<0) = 0;
				stimVector = [0; stimVectorSpread(:)]';
				options.stimTriggerOnset = 2;
			elseif options.stimTriggerOnset==2
				stimVectorSpread = spreadSignal(stimVector,'timeSeq',[-offset:0]);
				stimVectorSpread = diff(stimVectorSpread);
				stimVectorSpread(stimVectorSpread>0) = 0;
				stimVectorSpread(stimVectorSpread<0) = 1;
				stimVector = [0; stimVectorSpread(:)]';
				% exit loop
				options.stimTriggerOnset = 4
			elseif options.stimTriggerOnset==3
				% FINISH THISSSS
				% convert point frames to continuous data
				stimVector = cumsum(stimVector);
			elseif options.stimTriggerOnset==0
				options.stimTriggerOnset = 1;
			end
			stimVectorAll{idNum} = stimVector;
			% options.stimTriggerOnset
			% ===============================================================
			% get signal modulation via t-test for 5 frames post
			display('calculating p-values for signals....')
			ttestSpreadIdx = 0:5;
			stimVectorSpreadTtest = spreadSignal(stimVector,'timeSeq',ttestSpreadIdx);
			notStimVectorSpreadTtest = ~stimVectorSpreadTtest;
			stimulusSignalPeaks = alignSignal(signalPeaks,stimVectorSpreadTtest,0,'returnFormat','perSignalStimResponseCount');
			notStimulusSignalPeaks = alignSignal(signalPeaks,notStimVectorSpreadTtest,0,'returnFormat','perSignalStimResponseCount');

			% figure(222)
			% subplot(2,1,1)
			% plot(stimVectorSpreadTtest, 'Color', 'red');
			% subplot(2,1,2)
			% plot(notStimVectorSpreadTtest, 'Color', 'green')
			% % legend({'stimulus','not stimulus'});

			% figure(221);
			% maxH = max(stimulusSignalPeaks(:));
			% histH = hist(stimulusSignalPeaks(:),[0:maxH]);
			% plot([0:maxH], histH/max(histH), 'Color', 'red');box off;
			% hold on;
			% maxH = max(notStimulusSignalPeaks(:));
			% histH = hist(notStimulusSignalPeaks(:),[0:maxH]);
			% plot([0:maxH], histH/max(histH), 'Color', 'black');box off;
			% legend({'stimulus','not stimulus'});
			% hold off;

			[h,p] = ttest2(stimulusSignalPeaks',notStimulusSignalPeaks');
			ttestSignSignals = p<0.05;
			% figure(222);
			% hist(log10(p),30);

			size(stimulusSignalPeaks)
			size(notStimulusSignalPeaks)
			size(ttestSignSignals)
			% pause;
			% ===============================================================
			% calculate mutual information
			display('smoothing signals')
			spreadSignalPeaks = spreadSignal(signalPeaks);
			% miScores = MutualInformation(stimVector,spreadSignalPeaks);
			miScoresShuffled = mutualInformationShuffle(stimVector,spreadSignalPeaks);
			tmpDirPath = strcat(options.picsSavePath,filesep,'MIShuffleScores',filesep);
			if (~exist(tmpDirPath,'dir')) mkdir(tmpDirPath); end;
			saveFile = char(strrep(strcat(tmpDirPath,thisFileID,'_',saveNameArray{idNum},'.png'),'/',''));
			saveas(gcf,saveFile);
			sigModSignals = miScoresShuffled(:,1)>(miScoresShuffled(:,2)+1.96*miScoresShuffled(:,3));
			nSignals = size(miScoresShuffled,1);
			pieNums = [sum(sigModSignals)/nSignals sum(~sigModSignals)/nSignals];
			[groupedImagesMI] = groupImagesByColor(IcaFilters,sigModSignals);
			groupedImagesMI = createObjMap(groupedImagesMI);
			if idNumCounter==1
				sigModSignalsAll = sigModSignals(:);
			else
				sigModSignalsAll = [sigModSignalsAll sigModSignals(:)];
			end
			% pieLabels = strcat({'not-significant','significant'},' : ',num2str(pieNums));
			% ===============================================================
			% signals sorted by response to stimulus
			nStims = sum(stimVector);
			% get the aligned signal, sum over all input signals
			alignSignalAll = alignSignal(signalPeaksTwo,stimVector,timeSeq);
			% sort by cells most responsive right after stimuli
			alignSignalAllSum = sum(alignSignalAll((round(end/2):(round(end/2)+10)),:),1);
			[responseN reponseScoreIdx] = sort(alignSignalAllSum,'descend');
			signalPeaksTwoSorted = signalPeaksTwo(reponseScoreIdx,:);
			nSignals = size(signalPeaksTwo,1);
			% alignSetsIdx = {1:nSignals,[1:10],[nSignals-10:nSignals],find(sigModSignals(reponseScoreIdx))};
			% size(ttestSignSignals)
			% size(sigModSignals)
			% size(reponseScoreIdx)
			alignSetsIdx = {1:nSignals,find(ttestSignSignals(reponseScoreIdx)),find(~ttestSignSignals(reponseScoreIdx)),find(sigModSignals(reponseScoreIdx))};
			numAlignSets = length(alignSetsIdx);
			reverseStr = '';
			thisFigNo = 9999000;
			titleSubplot = {'all cells','t-test p<0.05','t-test p>0.05','mutually informative'};
			[~, ~] = openFigure(thisFigNo, '');
				subplotX = 4;
				subplotY = 3;
				imgSubplotLoc = {[1 5],[2 6],[3 7],[4 8]};
				plotSubplotLoc = {[9],[10],[11],[12]};
				signalPeaksTwoSorted = signalPeaksTwo(reponseScoreIdx,:);
				alignSignalAllSorted = alignSignalAll(:,reponseScoreIdx);
				clear alignSignalImg alignedSignalArray alignedSignalArray
				maxValAll = 0; minValAll = 0;
				for alignNo = 1:numAlignSets
					display([num2str(alignNo) '\' num2str(numAlignSets) ' | aligning and shuffling: ' titleSubplot{alignNo}])
					nAlignSignals = length(alignSetsIdx{alignNo});
					alignSignalImg{alignNo} = alignSignalAllSorted(:,alignSetsIdx{alignNo})';
					thisSignal = signalPeaksTwoSorted(alignSetsIdx{alignNo},:);
					% make dummy vector if empty
					if isempty(thisSignal)
						display('using empty dummy vector')
						thisSignal = zeros([1 size(signalPeaksTwoSorted,2)]);
					end
					alignedSignalArray{alignNo} = alignSignal(thisSignal, stimVector,timeSeq,'overallAlign',1);
					% alignedSignalArray{alignNo} = alignSignal(thisSignal, stimVector,timeSeq,'returnFormat','totalStimResponseMean');
					alignedSignalArray{alignNo} = alignedSignalArray{alignNo}/nStims;
					% nShuffles = 20;
					% for i=1:nShuffles
					% 	alignedSignalShuffled(:,i) = alignSignal(shuffleMatrix(thisSignal,'waitbarOn',0), stimVector,timeSeq,'overallAlign',1)';
					% 	% alignedSignalStimShuffled(:,i) = alignSignal(signalPeaks, shuffleMatrix(stimVector,'waitbarOn',0),timeSeq,'overallAlign',1)';
					% 	reverseStr = cmdWaitbar(i,nShuffles,reverseStr,'inputStr','shuffling alignment','waitbarOn',1,'displayEvery',1);
					% end
					% alignedSignalShuffledMeanArray{alignNo} = mean(alignedSignalShuffled/nStims,2);
					% alignedSignalShuffledStdArray{alignNo} = std(alignedSignalShuffled/nStims,0,2);
					ttestSpreadIdx = 0:5;
					stimVectorSpreadTtest = spreadSignal(stimVector,'timeSeq',ttestSpreadIdx);
					notStimVectorSpreadTtest = ~stimVectorSpreadTtest;
					notStimulusSignalPeaks = alignSignal(thisSignal,notStimVectorSpreadTtest,0,'returnFormat','totalStimResponseCount');
					alignedSignalShuffledMeanArray{alignNo} = repmat(nanmean(notStimulusSignalPeaks),[length(alignedSignalArray{alignNo}) 1]);
					alignedSignalShuffledStdArray{alignNo} = repmat(nanstd(notStimulusSignalPeaks),[length(alignedSignalArray{alignNo}) 1]);
					% maxDisplayValue = max(alignSignalImg{1}(:));
					% minDisplayValue = min(alignSignalImg{1}(:));
					alignSignalImg{alignNo}(1,1) = max(alignSignalImg{1}(:));
					alignSignalImg{alignNo}(1,2) = min(alignSignalImg{1}(:));
					%
					subplot(subplotY,subplotX,imgSubplotLoc{alignNo})
						imagesc(alignSignalImg{alignNo}/nStims);
						% =======
						% tmpTraces = alignSignal(IcaTraces(alignSetsIdx{alignNo},:),stimVector,timeSeq);
						% plotSignalsGraph(tmpTraces(:,1:10)','LineWidth',2.5);
						% =======
						box off;axis off; set(gca,'xtick',[],'xticklabel',[]);
						ylabel('cells')
						colormap(customColormap([]));
						cb = colorbar('location','southoutside');
						if options.dfofAnalysis==1
							xlabel(cb, '\DeltaF/F/stimulus');
						else
							xlabel(cb, 'spikes/stimulus');
						end
						title(titleSubplot{alignNo});
					subplot(subplotY,subplotX,plotSubplotLoc{alignNo})
						viewLineFilledError(alignedSignalShuffledMeanArray{alignNo},alignedSignalShuffledStdArray{alignNo},'xValues',timeSeq);
						hold on;
						% ========
						% FREEZE ADDED
							plot(timeSeq, alignedSignalArray{alignNo},'k','LineWidth',2); hold on;
							tmpAlignSignalAll = alignSignal(thisSignal,stimVector,timeSeq);
							tmpAlignSignalAllSum = sum(tmpAlignSignalAll((round(end/2):(round(end/2)+10)),:),1)-sum(tmpAlignSignalAll((round(end/2)-10:(round(end/2))),:),1);
							% tmpAlignSignalAllSum
							updownArray = {tmpAlignSignalAllSum>=0,tmpAlignSignalAllSum<0};
							updownColorArray = {'g','r'};
							for updownIdx = 1:length(updownArray)
								tmpAlignedSignalArray = alignSignal(thisSignal(updownArray{updownIdx},:), stimVector,timeSeq,'overallAlign',1);
								tmpAlignedSignalArray = tmpAlignedSignalArray/nStims;
								if ~isempty(tmpAlignedSignalArray)
									plot(timeSeq, tmpAlignedSignalArray,updownColorArray{updownIdx},'LineWidth',2); hold on;
								end
							end
							box off;
						% ========
						if alignNo==1
							if options.dfofAnalysis==1
								ylabel('\DeltaF/F');
							else
								ylabel('spikes/stimulus');

							end
						end
						if options.dfofAnalysis==1

						else
							kkk = [alignedSignalArray{alignNo} alignedSignalShuffledMeanArray{alignNo}+1.96*alignedSignalShuffledStdArray{alignNo}];
							kkk = nanmax(kkk(:))*1.1;
							y=ylim;
							try
								ylim([0 kkk]);
							catch

							end
						end
						xlabel('frames')
						hold off;
					% calculate max if want all plots to have same axes
					biMean = alignedSignalShuffledMeanArray{alignNo};
					biStd = alignedSignalShuffledStdArray{alignNo};
					biAll = alignedSignalArray{alignNo};
					biMax = [biMean+1.96*biStd biAll];
					biMin = [biMean-1.96*biStd biAll];
					maxVal = max(biMax(:));
					minVal = min(biMin(:));
					if (maxVal>maxValAll) maxValAll = maxVal; end;
					if (minVal<minValAll) minValAll = minVal; end;
				end
				for alignNo = 1:numAlignSets
					subplot(subplotY,subplotX,plotSubplotLoc{alignNo})
						ylim([minValAll-0.1*abs(minValAll),maxValAll+0.1*maxValAll])
				end
				suptitle([num2str(subject) ' ' assay ' ' nameArray{idNum} ' | all trials'])
			thisFigName = 'stimTriggeredPerCell_'
			tmpDirPath = strcat(options.picsSavePath,filesep,thisFigName,filesep);
			if (~exist(tmpDirPath,'dir')) mkdir(tmpDirPath); end;
			saveFile = char(strrep(strcat(tmpDirPath,thisFileID,'_',saveNameArray{idNum},''),'/',''));
			saveFile
			set(thisFigNo,'PaperUnits','inches','PaperPosition',[0 0 10 10])
			figure(thisFigNo)
			print('-dpng','-r100',saveFile)
			print('-dmeta','-r100',saveFile)
			% store the aligned signal in output structure
			ostruct.aggregate.stimTriggered{idNum}(ostruct.counter,:) = alignedSignalArray{1};
			% ===============================================================
			% thisFigNo = 9999001;
			% [~, ~] = openFigure(thisFigNo, '');
			% for alignNo = 1:numAlignSets
			% 	alignedSignalArray{alignNo}
			% end
			% ===============================================================
			% get centroid locations along with distance matrix
			[xCoords yCoords] = findCentroid(IcaFilters);
			dist = pdist([xCoords(:) yCoords(:)]);
			npts = length(xCoords);
			distanceMatrix = diag(realmax*ones(1,npts))+squareform(dist);
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
			% nSignals
			% nSignificantSignals
			for shuffleNo=1:nShuffles
				groupIdx = randsample(nSignals,nSignificantSignals,false);
				minDistances = min(distanceMatrix(groupIdx,groupIdx));
				for i=1:50
					gfunctionShuffled(i,shuffleNo)=sum(minDistances<=i)/length(minDistances);
				end
			end
			gfunctionShuffledMean = mean(gfunctionShuffled,2);
			gfunctionShuffledStd = std(gfunctionShuffled,0,2);

			% for i=1:(nGroups-1)
			% 	[ktestReject(i) ktestPval(i) ktestStat(i)]  = kstest2(gfunction(:,nGroups),gfunction(:,i),'Tail','unequal');
			% end
			% % use the fisher to combine p-values
			% ostruct.data.gfunctionFisher(fileNum,1) = -2*nansum(log(ktestPval));
			%
			% ktestReject = [ktestReject NaN];
			% ktestStatStr = arrayfun(@(x) sprintf('p<0.05 = %d',x),ktestReject,'un',0);
			% ===============================================================
			% ===============================================================
			% ===============================================================
			% use the t-test cells
			alignIdxToUse = 1;
			alignedSignal = alignedSignalArray{alignIdxToUse};
			alignedSignalShuffledMean = alignedSignalShuffledMeanArray{alignIdxToUse};
			alignedSignalShuffledStd = alignedSignalShuffledStdArray{alignIdxToUse};
			% to avoid focus stealing
			figNoAll = 1;
			figNames{figNoAll} = 'stimTriggeredAvg_signal_';
         	[figNo{figNoAll}, figNoAll] = openFigure(figNoAll, '');
	            if idNumCounter==1
					suptitle([num2str(subject) '\_' assay ' '  ' | triggered firing rate over entire trial, frames/sec = ' num2str(framesPerSecond),10,10])
				end
				[xPlot yPlot] = getSubplotDimensions(nIDs+1);
	            subplot(xPlot,yPlot,idNum)
		            a = gca(figNo{1}); % get the axes from the figure
		            cla(a); % clear the axes
					viewLineFilledError(alignedSignalShuffledMean,alignedSignalShuffledStd,'xValues',timeSeq);
					hold on;
					% viewLineFilledError(alignedSignalStimShuffledMean,alignedSignalStimShuffledStd,'xValues',timeSeq);
					% hold on;
					plot(timeSeq, alignedSignal,'r');box off;
					% plot(timeSeq,alignedSignalShuffled/nStims,'k');
					% plot(timeSeq,alignedSignalStimShuffled/nStims,'b');
					title([nameArray{idNum}]);
					if idNum==nIDs
						xlabel('frames');
					end
					axisMax = max(alignedSignal)*1.1;
					axisMaxShuffle = max(alignedSignalShuffledMean+1.96*alignedSignalShuffledStd);
					if axisMaxShuffle>axisMax
						axisMax = axisMaxShuffle;
					end
					ylim([min(alignedSignal)-std(alignedSignal),axisMax]);
					if idNumCounter==1
						if options.dfofAnalysis==1
							ylabel('\DeltaF/F');
						else
							ylabel('spikes/stimulus');
						end
						% make legend
						[xPlot yPlot] = getSubplotDimensions(nIDs+1);
			            subplot(xPlot,yPlot,nIDs+1)
						viewLineFilledError([1 1],[1 1],'xValues',1:2);
						hold on;
						plot([1 2], [1 1],'r');box off;
						h_legend = legend('2\sigma(shuffle)','mean(shuffle)','actual','2\sigma(shuffle stim)','mean(shuffle stim)','Location','Best','Orientation','horizontal');
						h_legend = legend('2\sigma(shuffle)','mean(shuffle)','actual','2\sigma(shuffle stim)','mean(shuffle stim)','Location','Best','Orientation','vertical');
						% set(h_legend,'FontSize',10);
					end
					drawnow
			% =====================
			figNames{figNoAll} = 'stimTriggeredAvg_cellmaps_';
         	[figNo{figNoAll}, figNoAll] = openFigure(figNoAll, '');
            % [figNo{2}, ~] = openFigure(2, '');
	            if idNumCounter==1
					suptitle([num2str(subject) '\_' assay ' | stimulus triggered cell maps',10,10])
				end
    			[xPlot yPlot] = getSubplotDimensions(nIDs+1);
                subplot(xPlot,yPlot,idNum)
	            	alignedSignalCells = alignSignal(signalPeaks, stimVector,[-15:15],'overallAlign',0);
	            	alignedSignalCellsSum = sum(alignedSignalCells,1)/sum(stimVector);
		            % add in fake filter for normalizing across trials
		            IcaFiltersTmp = IcaFilters;
		            % IcaFiltersTmp(end+1,:,:) = 0;
		            % IcaFiltersTmp(end,1,1) = 1;
		            % alignedSignalCellsSum(end+1) = 20;
		            % =====================
		            [groupedImagesRates] = groupImagesByColor(IcaFiltersTmp,alignedSignalCellsSum);
		            groupedImageCellmapRates = createObjMap(groupedImagesRates);
		            imagesc(groupedImageCellmapRates);
		            axis square; box off; axis off;
		            colormap(ostruct.colormap);
		            cb = colorbar('location','southoutside');
		            if options.dfofAnalysis==1
		            	xlabel(cb, '\DeltaF/F/stimulus');
		            else
		            	xlabel(cb, 'spikes/stimulus');
		            end
		            title([nameArray{idNum}]);
		            set(gcf, 'PaperUnits', 'centimeters');
		            set(gcf, 'PaperPosition', [0 0 25 9]); %x_width=10cm y_width=15cm
            % =====================
			figNames{figNoAll} = 'stimTriggeredAvg_MIpiecharts_';
         	[figNo{figNoAll}, figNoAll] = openFigure(figNoAll, '');
	            if idNumCounter==1
					suptitle([num2str(subject) '\_' assay ' | % mutually informative cells',10,10])
				end
    			[xPlot yPlot] = getSubplotDimensions(nIDs+1);
                subplot(xPlot,yPlot,idNum)
		            pieLabels = {'significant','not-significant'};
		            h = pie(pieNums,pieLabels);
		            % adjPieLabels(h);
		            title([nameArray{idNum}]);
		            % title(['2\sigma significance threshold']);
            % =====================
			figNames{figNoAll} = 'MIcellmap_';
         	[figNo{figNoAll}, figNoAll] = openFigure(figNoAll, '');
	            if idNumCounter==1
					suptitle([num2str(subject) '\_' assay ' | cell maps of mutually informative cells',10,10])
				end
	            % cell maps of MI scores
    			[xPlot yPlot] = getSubplotDimensions(nIDs+1);
                subplot(xPlot,yPlot,idNum)
		            imagesc(groupedImagesMI);
		            axis square; box off; axis off;
		            colormap(ostruct.colormap);
		            title([nameArray{idNum}]);
		    % =====================
			figNames{figNoAll} = 'Gfunction_MI_cellDistances_';
         	[figNo{figNoAll}, figNoAll] = openFigure(figNoAll, '');
	            if idNumCounter==1
					suptitle([num2str(subject) '\_' assay ' | G-function distributions (i.e. spatial clustering)',10,10])
				end
				[xPlot yPlot] = getSubplotDimensions(nIDs+1);
	            subplot(xPlot,yPlot,idNum)
		    		viewLineFilledError(gfunctionShuffledMean,gfunctionShuffledStd);
			    	hold on;
			    	plot(gfunction);box off; xlabel('distance (px)'); ylabel('G(d)');
			    	title(strcat(nameArray{idNum},' '));
			    	if idNumCounter==1
			    		h_legend = legend({'shuffled std','shuffled mean','not significant','significant'},'Location','Best');
			    		set(h_legend,'FontSize',10);
			    	end
			    	hold off;
		    	% pause
            % =====================
            % add summary statistics
            if ~any(strcmp('summaryStats',fieldnames(ostruct)))
            	ostruct.summaryStats.subject{1,1} = nan;
            	ostruct.summaryStats.assay{1,1} = nan;
            	ostruct.summaryStats.assayType{1,1} = nan;
            	ostruct.summaryStats.assayNum{1,1} = nan;
            	ostruct.summaryStats.stimulus{1,1} = nan;
            	ostruct.summaryStats.pctMI2sigma{1,1} = nan;
            	ostruct.summaryStats.zscore{1,1} = nan;
            	ostruct.summaryStats.zscoresPost{1,1} = nan;
            	ostruct.summaryStats.zscoresPre{1,1} = nan;
            	ostruct.summaryStats.signalFiringModulation{1,1} = nan;
            	ostruct.summaryStats.signalFiringModulationShuffle{1,1} = nan;
            	zScoreString = {'All','Ttest','NotTtest','MI'};
            	for alignIdxToUse=1:length(alignedSignalArray)
            		eval(['ostruct.summaryStats.zscore' zScoreString{alignIdxToUse} '{1,1} = nan']);
            	end
            end
            ostruct.summaryStats.subject{end+1,1} = ostruct.subject{fileNum};
            ostruct.summaryStats.assay{end+1,1} = ostruct.assay{fileNum};
            ostruct.summaryStats.assayType{end+1,1} = ostruct.info.assayType{fileNum};
            ostruct.summaryStats.assayNum{end+1,1} = ostruct.info.assayNum{fileNum};
            ostruct.summaryStats.stimulus{end+1,1} = nameArray{idNum};
            ostruct.summaryStats.pctMI2sigma{end+1,1} = nanmean(sigModSignals);
            lenTimeseqHalf = floor(length(timeSeq)/2);
            % calculate Zscore
            zscores = (alignedSignal-alignedSignalShuffledMean)./alignedSignalShuffledStd;
            zscoresPost = nanmean(zscores(lenTimeseqHalf+1:lenTimeseqHalf+20));
            zscoresPre = nanmean(zscores(lenTimeseqHalf-20:lenTimeseqHalf));

            ostruct.summaryStats.zscore{end+1,1} = (zscoresPost-zscoresPre);
            ostruct.summaryStats.zscoresPost{end+1,1} = zscoresPost;
            ostruct.summaryStats.zscoresPre{end+1,1} = zscoresPre;
            % look at number of significant points before and after stimulus onset
            alignedSig = alignedSignal>(alignedSignalShuffledMean+1.96*alignedSignalShuffledStd);
            alignedSigPost = nanmean(alignedSig(lenTimeseqHalf+1:lenTimeseqHalf+20));
            alignedSigPre = nanmean(alignedSig(lenTimeseqHalf-20:lenTimeseqHalf));

            ostruct.summaryStats.signalFiringModulation{end+1,1} = (alignedSigPost-alignedSigPre);
            ostruct.summaryStats.signalFiringModulationShuffle{end+1,1} = NaN;
            %
            zScoreString = {'All','Ttest','NotTtest','MI'};
            for alignIdxToUse=1:length(alignedSignalArray)
	            alignedSignal = alignedSignalArray{alignIdxToUse};
	            alignedSignalShuffledMean = alignedSignalShuffledMeanArray{alignIdxToUse};
	            alignedSignalShuffledStd = alignedSignalShuffledStdArray{alignIdxToUse};
	            zscoresExtra = (alignedSignal-alignedSignalShuffledMean)./alignedSignalShuffledStd;
	            zscoresPostExtra = nanmean(zscoresExtra(lenTimeseqHalf+1:lenTimeseqHalf+10));
	            eval(['ostruct.summaryStats.zscore' zScoreString{alignIdxToUse} '{end+1,1} = (zscoresPostExtra)']);
        	end
            % struct2table(ostruct.summaryStats)
            % ostruct.summaryStats.signalFiringModulation{end+1,1} = (sum(alignedSignal(lenTimeseqHalf+1:end))-sum(alignedSignal(1:lenTimeseqHalf)))/(sum(alignedSignal(lenTimeseqHalf+1:end))+sum(alignedSignal(1:lenTimeseqHalf)));
            % ostruct.summaryStats.signalFiringModulationShuffle{end+1,1} = (sum(alignedSignalShuffled(lenTimeseqHalf+1:end))-sum(alignedSignalShuffled(1:lenTimeseqHalf)))/(sum(alignedSignalShuffled(lenTimeseqHalf+1:end))+sum(alignedSignalShuffled(1:lenTimeseqHalf)));
            % struct2table(ostruct.summaryStats)
            % =====================
            % ADD BIG DATA
            % ostruct = addValuesToBigData(ostruct,1:length(zscores),zscores,nameArray{idNum},ostruct.assay{fileNum});
            % ~any(strcmp('bigData',fieldnames(ostruct)))
            if ~any(strcmp('bigData',fieldnames(ostruct)))
            	display('creating bigdata structure')
                ostruct.bigData.frame = [];
                ostruct.bigData.value = [];
                ostruct.bigData.varType = {};
                % ostruct.bigData.subjectType = {};
                ostruct.bigData.subject = {};
                ostruct.bigData.assay = {};
                ostruct.bigData.assayType = {};
                ostruct.bigData.assayNum = {};
            	ostruct.bigData
            end
            numPtsToAdd = length(zscores)
            % numPtsToAdd = 101;
            zscoresLength = 1:length(zscores);
            ostruct.bigData.frame(end+1:end+numPtsToAdd,1) = zscoresLength(:);
            ostruct.bigData.value(end+1:end+numPtsToAdd,1) = zscores(:);
            ostruct.bigData.varType(end+1:end+numPtsToAdd,1) = {nameArray{idNum}};
            % ostruct.bigData.subjectType(end+1:end+numPtsToAdd,1) = subjectType;
            ostruct.bigData.subject(end+1:end+numPtsToAdd,1) = {ostruct.info.subject{fileNum}};
            ostruct.bigData.assay(end+1:end+numPtsToAdd,1) = {ostruct.info.assay{fileNum}};
            ostruct.bigData.assayType(end+1:end+numPtsToAdd,1) = {ostruct.info.assayType{fileNum}};
            ostruct.bigData.assayNum(end+1:end+numPtsToAdd,1) = {ostruct.info.assayNum{fileNum}};

            % =====================
            idNumCounter = idNumCounter+1;
		end
		% write out summary statistics
		writetable(struct2table(ostruct.summaryStats),['private\data\' ostruct.info.protocol{fileNum} '_summary5.tab'],'FileType','text','Delimiter','\t');
		% write out large data
        writetable(struct2table(ostruct.bigData),['private\data\' ostruct.info.protocol{fileNum} '_stimTriggered_bigData.tab'],'FileType','text','Delimiter','\t');
		% =====================
		% look to see which cells are responsive to multiple stimuli
		figNames{figNoAll} = 'miMap_all_';
     	[figNo{figNoAll}, figNoAll] = openFigure(figNoAll, '');
			sigModSignalsAllSum = sum(sigModSignalsAll,2);
			[groupedImagesSigMod] = groupImagesByColor(IcaFilters,sigModSignalsAllSum);
			groupedImagesSigModMap = createObjMap(groupedImagesSigMod);
			imagesc(groupedImagesSigModMap); axis square;
			% colormap(ostruct.colormap);
			colorMatrix = [1 1 1;hsv(length(idArray))];
			colormap(colorMatrix);
			% cb = colorbar('location','southoutside');
			cb = colorbar;
			ylabel(cb, '# MI stimuli');
			title([num2str(subject) '\_' assay ' | overlap of mutually informative cells, all stimuli'])
		% =====================
		% compare each stimuli to other stimuli MI maps
		figNames{figNoAll} = 'miMap_allPairwise_';
     	[figNo{figNoAll}, figNoAll] = openFigure(figNoAll, '');
	     	[p,q] = meshgrid(1:nIDs, 1:nIDs);
	     	idPairs = [p(:) q(:)];
	     	idPairs = unique(sort(idPairs,2),'rows');
	     	idPairs((idPairs(:,1)==idPairs(:,2)),:) = [];
			nIDs = length(idArray);
			% colorArray = hsv(nIDs);
			nPairs = size(idPairs,1);
			% ===
			nColors = size(ostruct.colormap,1);
			colorIdx1 = round(quantile(1:nColors,0.33));
			colorIdx2 = round(quantile(1:nColors,0.66));
			colorIdx3 = round(quantile(1:nColors,1));
			nameColor3 = ['{\color[rgb]{',num2str(ostruct.colormap(colorIdx3,:)),'}overlap}'];
			% ===
			for idPairNum = 1:nPairs
				idNum1 = idPairs(idPairNum,1);
				idNum2 = idPairs(idPairNum,2);
				if size(sigModSignalsAll,2)<idNum1|size(sigModSignalsAll,2)<idNum2
					continue;
				else
					sigModSignalsAllPair = sigModSignalsAll(:,[idNum1 idNum2]);
				end
				% for display purposes, change one so can see the two populations and overlap
				sigModSignalsAllPairMod = [sigModSignalsAllPair(:,1) 2*sigModSignalsAllPair(:,2)];
				sigModSignalsAllPairMod = sum(sigModSignalsAllPairMod,2);
				[groupedImagesSigMod] = groupImagesByColor(IcaFilters,sigModSignalsAllPairMod);
				groupedImagesSigModMap = createObjMap(groupedImagesSigMod);
				% make sure color scheme stays correct
				groupedImagesSigModMap(1,1:4) = 0:3;
				%
				[xPlot yPlot] = getSubplotDimensions(nPairs);
				subplot(xPlot,yPlot,idPairNum)
					imagesc(groupedImagesSigModMap); axis square;
					colormap(ostruct.colormap);
					% color based on which is which
					nameColor1 = ['{\color[rgb]{',num2str(ostruct.colormap(colorIdx1,:)),'}',strrep(nameArray{idNum1},'__',' '),'}'];
					nameColor2 = ['{\color[rgb]{',num2str(ostruct.colormap(colorIdx2,:)),'}',strrep(nameArray{idNum2},'__',' '),'}'];
					% title([,'=1',10,nameArray{idNum2},'=2'])
					title([nameColor1,10,nameColor2]);
					box off; axis off;
					drawnow;
	        end
	   %      subplot(xPlot,yPlot,nPairs)
	   %      	imagesc([0:3]);
	   %      	cb = colorbar('location','southoutside');
				% xlabel(cb, 'MI stimuli number');
			suptitle([num2str(subject) '\_' assay ' | overlap of mutually informative cells, ' nameColor3])
		% =====================
		figNames{figNoAll} = 'miStimTriggered_allPairwise_';
     	[figNo{figNoAll}, figNoAll] = openFigure(figNoAll, '');
	     	[p,q] = meshgrid(1:nIDs, 1:nIDs);
	     	idPairs = [p(:) q(:)];
	     	% idPairs = unique(sort(idPairs,2),'rows');
	     	% idPairs((idPairs(:,1)==idPairs(:,2)),:) = []
			nIDs = length(idArray);
			% colorArray = hsv(nIDs);
			nPairs = size(idPairs,1);
			% ===
			nColors = size(ostruct.colormap,1);
			colorIdx1 = round(quantile(1:nColors,0.33));
			colorIdx2 = round(quantile(1:nColors,0.66));
			colorIdx3 = round(quantile(1:nColors,1));
			nameColor3 = ['{\color[rgb]{',num2str(ostruct.colormap(colorIdx3,:)),'}overlap}'];
			% ===
			ycounter = 1;
			xcounter = 1;
			for idPairNum = 1:nPairs
				idNum1 = idPairs(idPairNum,1);
				idNum2 = idPairs(idPairNum,2);
				if size(sigModSignalsAll,2)<idNum1|size(sigModSignalsAll,2)<idNum2
					continue;
				else
					sigModSignalsAllPair = sigModSignalsAll(:,[idNum1 idNum2]);
				end
				stimVector = stimVectorAll{idNum2};
				% signals sorted by response to stimulus
				nStims = sum(stimVector);
				% get signals to use for alignment from second stim
				signalFilterIdx = sigModSignalsAll(:,[idNum1]);
				if idNum1~=idNum2
					% remove signals that overlap for the two stimuli
					overlapExcludeIdx = ~logical(sum(sigModSignalsAll(:,[idNum1 idNum2]),2)==2);
					% only look at overlap
					% overlapExcludeIdx = logical(sum(sigModSignalsAll(:,[idNum1 idNum2]),2)==2);
					signalFilterIdx = signalFilterIdx.*overlapExcludeIdx;
				else
					% overlapExcludeIdx = logical(sum(sigModSignalsAll(:,[idNum1 idNum2]),2)==2);
					% signalFilterIdx = signalFilterIdx.*overlapExcludeIdx;
				end
				sum(signalFilterIdx)
				if(sum(signalFilterIdx)~=0)
					% only look at responsive signals
					signalPeaksTwoFiltered = signalPeaksTwo(find(signalFilterIdx),:);
					% get the response for each signal aligned to stimulus
					alignResponseAllSignals = alignSignal(signalPeaksTwoFiltered,stimVector,timeSeq);
					% sort by cells most responsive right after stimuli
					% alignResponseAllSignals
					alignResponseAllSignalsSum = sum(alignResponseAllSignals((round(end/2):(round(end/2)+10)),:),1);
					[responseN reponseScoreIdx] = sort(alignResponseAllSignalsSum,'descend');
					signalPeaksTwoSorted = signalPeaksTwoFiltered(reponseScoreIdx,:);
					alignSignalAllSorted = alignResponseAllSignals(:,reponseScoreIdx)';
					[xPlot yPlot] = getSubplotDimensions(nPairs);
					subplot(xPlot,yPlot,idPairNum)
						alignSignalAllSortedImg = alignSignalAllSorted/nStims;
						if options.dfofAnalysis==1
						else
							% alignSignalAllSortedImg(1,1) = 1;
						end
						imagesc(alignSignalAllSortedImg);
						box off;
						% make axis normal
						set(gca,'YDir','normal');
						% axis off;
						set(gca,'xtick',[],'xticklabel',[]);
						if ycounter==1
							% ylabel('signals')
							ylabel([strrep(nameArray{idNum1},'__',' '),' MI'])
						else
							% y=ylim;
							% ylim([0 y(1)]);
						end
						colormap(customColormap([]));
						if options.dfofAnalysis==1
							cb = colorbar('location','southoutside');
							xlabel(cb, '\DeltaF/F/stimulus');
						else
							% xlabel(cb, 'spikes/stimulus');
						end
						if xcounter==1
							% title([strrep(nameArray{idNum1},'__',' '),' MI signals',10,strrep(nameArray{idNum2},'__',' '),' aligned stimulus'])
							title([strrep(nameArray{idNum2},'__',' '),' aligned'])
						end
						hold on;
						numXTicks = 7;
						L = get(gca,'XLim');
						set(gca,'XTick',round(linspace(L(1),L(2),numXTicks)))
						set(gca,'XTickLabel',round(linspace(min(timeSeq),max(timeSeq),numXTicks)))
						if xcounter==nIDs
							xlabel('frames');
						end
						alignSignalAllSortedMean = sum(alignSignalAllSorted/nStims,1);
						alignLineHeight = round(size(alignSignalAllSorted,1)/2);
						if ycounter==1
							thisYMax = max(alignSignalAllSortedMean);
							alignSignalAllSortedMeanNorm = normalizeVector(alignSignalAllSortedMean,'normRange','zeroToOne')*alignLineHeight;
							% alignSignalAllSortedMeanNorm
						else
							% thisYMax
							alignSignalAllSortedMean(end+1) = thisYMax;
							alignSignalAllSortedMeanNorm = normalizeVector(alignSignalAllSortedMean,'normRange','zeroToOne')*alignLineHeight;
							% alignSignalAllSortedMeanNorm
							alignSignalAllSortedMeanNorm = alignSignalAllSortedMeanNorm(1:end-1);
						end
						plot(alignSignalAllSortedMeanNorm,'LineWidth',3,'Color','k');
						hold off;
				end
				if ycounter==nIDs
					ycounter = 1;
					xcounter = xcounter + 1;
				else
					ycounter = ycounter+1;
				end
	        end
	   %      subplot(xPlot,yPlot,nPairs)
	   %      	imagesc([0:3]);
	   %      	cb = colorbar('location','southoutside');
				% xlabel(cb, 'MI stimuli number');
			suptitle([num2str(subject) '\_' assay ' | comparison of mutually informative signals to other stimuli, excluding ',nameColor3,' signals'])
		% =====================
		% save the figure
		for i=1:length(figNames)
			tmpDirPath = strcat(options.picsSavePath,filesep,figNames{i},filesep);
			if (~exist(tmpDirPath,'dir')) mkdir(tmpDirPath); end;
			saveFile = char(strrep(strcat(tmpDirPath,thisFileID,''),'/',''));
			saveFile
			set(figNo{i},'PaperUnits','inches','PaperPosition',[0 0 15 15])
			figure(figNo{i})
			print('-dpng','-r200',saveFile)
			print('-dmeta','-r200',saveFile)
			close(figNo{i})
		end
		% saveas(plotFig,saveFile);
  %       saveFile = char(strrep(strcat(options.picsSavePath,'p104_stimTriggeredAvg_cellmaps_',thisFileID,'.png'),'/',''));
  %       saveas(mapFig,saveFile);
  %       saveFile = char(strrep(strcat(options.picsSavePath,'stimTriggeredAvg_MIpiecharts_',thisFileID,'.png'),'/',''));
  %       saveas(pieFig,saveFile);
        % close(plotFig);close(mapFig);close(pieFig);
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

	ostruct.counter = ostruct.counter + 1;

	if ostruct.counter==(ostruct.nAnalyzeFolders+1)
		for idNum = 1:length(idArray)
			figure(ostruct.endFig)
			% [figNo{2}, ~] = openFigure(2, '');
			% normalize the rows so it is easier to compare the effect (rather than the effect size) between trials
			A = ostruct.aggregate.stimTriggered{idNum}';
			[rows,~]=size(A);
			colMax=max(abs(A),[],1);
			normalizedA=A./repmat(colMax,rows,1);
			imagesc(normalizedA');box off;
			colormap(ostruct.colormap);cb = colorbar('location','southoutside');
			% imagesc(ostruct.aggregate.stimTriggered{idNum}); box off; colormap hot;
			% do a little label adjustments
			numXTicks = 7;
			L = get(gca,'XLim');
			set(gca,'XTick',linspace(L(1),L(2),numXTicks))
			set(gca,'XTickLabel',linspace(min(timeSeq),max(timeSeq),numXTicks))
			numYTicks = ostruct.counter*2;
			L = get(gca,'YLim');
			set(gca,'YTick',0:1:numYTicks*2)
			set(gca,'YTickLabel',{'',ostruct.lists.assay{:}})
			xlabel('frames');
			ylabel('trial');
			title([num2str(subject) ' all trials, ' nameArray{idNum} ' triggered firing rate over entire trial, frames/sec = ' num2str(framesPerSecond)]);
			% save the figure
			saveFile = char(strrep(strcat(options.picsSavePath,'all_stimTriggeredAvg_',num2str(subject),'_',nameArray{idNum},'.png'),'/',''));
			% saveFile = char(strrep(strcat('private\pics\p104\p104_stimTriggeredAvg_all_',num2str(subject),'_',nameArray{idNum},'.png'),'/',''));
			saveas(ostruct.endFig,saveFile);
		end
		close(ostruct.endFig)
	end

function [ostruct] = stimulusTriggeredMovie(ostruct, options, fileNum, nFiles, thisDirSaveStr,trialRegExp,movieList)
		% compares the subject's signal to movement data

		% have user choose range of frames to load
		usrIdxChoice = inputdlg('select frame range (e.g. 1:1000), leave blank for all frames');

		% look for clean filters
		filesToLoad=strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr});
		% if bad ICs haven't been removed yet, use the raw
		if(~exist(filesToLoad{1}, 'file'))
			% filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
			filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
			if(~exist(filesToLoad{1}, 'file'))
				return
			end
		end
		for i=1:length(filesToLoad)
			display(['loading: ' filesToLoad{i}]);
			load(filesToLoad{i})
		end

		% load movement data
		[options.trackingDir '\' trialRegExp];
		movementFilePath = getFileList(options.trackingDir,trialRegExp);
		if isempty(movementFilePath)
			return
		end
		display(['loading: ' movementFilePath{1}]);
		movement = readtable(movementFilePath{1},'Delimiter','tab','FileType','text');

		% get the movement comparison data
		outputData = compareSignalToMovement(IcaTraces,movement,'makePlots',0);
		% get the correlation between the two
		thisVel = outputData.downsampledVelocity*options.framesPerSecond/(ostruct.data.pxToCm(fileNum));

		% look at movement in the video aligned
		timeSeq = [-20:20];
		nPoints = length(thisVel);
		onsetIdx = find([0 diff(thisVel>1)]==1);
		peakIdxs = bsxfun(@plus,timeSeq',onsetIdx);
		peakIdxs(find(peakIdxs<1)) = [];
		peakIdxs(find(peakIdxs>nPoints)) = [];
		%
		thisVelDuplicate = thisVel;
		thisVelDuplicate(onsetIdx) = 10;
		inputVel = thisVelDuplicate(peakIdxs(:));
		inputVel(inputVel>10) = NaN;
		%
		inputFiring = sum(spreadSignal(outputData.signalPeaks),1);
		inputFiring = inputFiring(peakIdxs(:));
		inputLines = [inputVel; inputFiring];

		%
		if ~isempty(usrIdxChoice{1})
			try
				peakIdxs = peakIdxs(str2num(usrIdxChoice{1}));
			catch
			end
		end

		% load movie
		vidList = getFileList(options.thisDir,'.*.h5');
		vidList = getFileList(options.videoDir,trialRegExp);
		% peakIdxs(:)
		% get the movie
		behaviorMovie = loadMovieList(vidList{1},'convertToDouble',options.convertToDouble,'frameList',peakIdxs(:)*options.downsampleFactor);
		ioptions.extraMovie = loadMovieList(movieList{1},'convertToDouble',options.convertToDouble,'frameList',peakIdxs(:));
		% ioptions.extraLinePlotLegend = {'velocity (cms/s)','firing rate (all neurons)'};
		ioptions.colorLinePlot = 1;
		ioptions.extraLinePlot = inputLines;
		ioptions.primaryTrackingPoint = [movement.XM(peakIdxs(:)*options.downsampleFactor) movement.YM(peakIdxs(:)*options.downsampleFactor) movement.Angle(peakIdxs(:)*options.downsampleFactor)];
		playMovie(behaviorMovie,'options',ioptions);

function [ostruct] = signalToMovement(ostruct, options, fileNum, nFiles, thisDirSaveStr,trialRegExp)
	% compares the subject's signal to movement data

	% look for clean filters
	filesToLoad=strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr});
 	rawFiles = 0;
	% if bad ICs haven't been removed yet, use the raw
	if(~exist(filesToLoad{1}, 'file'))
		% filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
		filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
		rawFiles = 1;
		if(~exist(filesToLoad{1}, 'file'))
			return
		end
	end
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end
	if rawFiles==1
    	[IcaFilters, IcaTraces, valid, imageSizes] = filterImages(IcaFilters, IcaTraces);
    end

	% load movement data
	[options.trackingDir '\' trialRegExp];
	movementFilePath = getFileList(options.trackingDir,[trialRegExp '.*.tab']);
	if isempty(movementFilePath)
		display(['cannot find stimulus file: ' trialRegExp])
		return
	end
	% display(['loading: ' movementFilePath{1}]);
	movement = readMultipleTables(movementFilePath,'tab');
	size(movement)
	size(IcaTraces)
	% return
	% movement = readtable(movementFilePath{1},'Delimiter','tab','FileType','text');
	% =====================
	% used to save files and make graphs
	thisID = strcat(ostruct.subject{fileNum},'\_',ostruct.summaryStats.subjectType(fileNum),'\_',ostruct.assay{fileNum});
	thisFileID = strcat(ostruct.subject{fileNum},'_',ostruct.summaryStats.subjectType(fileNum),'_',ostruct.assay{fileNum});
    % =====================
	% get the movement comparison data
	movement.XM = movement.XM*options.framesPerSecond/ostruct.summaryStats.pxToCm(fileNum);
	movement.YM = movement.YM*options.framesPerSecond/ostruct.summaryStats.pxToCm(fileNum);
	outputData = compareSignalToMovement(IcaTraces,movement,'makePlots',1);
    % =====================
    % stim constants
    STIM_CUTOFF = 0.01;
    subject = str2num(strrep(strrep(ostruct.subject{fileNum},'m',''),'f',''));
    ostruct.curentSubject = ostruct.subject{fileNum};
    assay = ostruct.assay{fileNum};
    % =====================
    %
	% thisVel = outputData.downsampledVelocity*options.framesPerSecond/(ostruct.summaryStats.pxToCm(fileNum));
	thisVel = outputData.downsampledVelocity;
	avgPeaksPerPt = outputData.avgPeaksPerPt;
	% avgPeaksPerPt = sum(IcaTraces,1);
	signalPeaks = outputData.signalPeaks;
	% signalPeaks = IcaTraces;
	signalPeaksRaw = IcaTraces;
    stimVectorRaw = thisVel;
    stimVector = thisVel>STIM_CUTOFF;
    figure(929)
	    plot(thisVel,'r'); hold on;
	    plot(avgPeaksPerPt,'b'); hold off;
	    legend({'velocity','firing rate'})
    % =====================
	% get the correlation between the two
	ostruct.summaryStats.pearsonStimBehavior(fileNum,1) = corr(avgPeaksPerPt(:), stimVectorRaw(:),'type','Pearson');
    ostruct.summaryStats.spearmanStimBehavior(fileNum,1) = corr(avgPeaksPerPt(:), stimVectorRaw(:),'type','Spearman');
	fitvals = polyfit(avgPeaksPerPt, stimVectorRaw,1);
	ostruct.summaryStats.slopeStimBehavior(fileNum,1) = fitvals(1);
    % =====================
	% get percent time in center of arena
	YM = outputData.downsampledXM;
	XM = outputData.downsampledYM;
	maxX = max(XM);
	maxY = max(YM);
	minVal = 0.33; maxVal = 0.66;
	indxY = (YM>round(maxY*minVal))&(YM<round(maxY*maxVal));
	indxX = (XM>round(maxX*minVal))&(XM<round(maxX*maxVal));
	ostruct.summaryStats.pctTimeCenter(fileNum,1) = sum(indxY&indxX)/length(XM);
    % =====================
	% look at total movement
	ostruct.summaryStats.totalDistance(fileNum,1) = sum(stimVectorRaw);
	% =====================
	% look at movement in the video aligned
	% movieVelocity = outputData.velocity*options.framesPerSecond/(ostruct.summaryStats.pxToCm(fileNum));
	% timeSeq = [-20:20];
	% nPoints = length(stimVectorRaw);
	% onsetIdx = find([0 diff(stimVector)]==1);
	% onsetIdx = onsetIdx*4;
	% peakIdxs = bsxfun(@plus,timeSeq',onsetIdx);
	% peakIdxs(find(peakIdxs<1)) = 1;
	% peakIdxs(find(peakIdxs>nPoints)) = 1;
	% inputVel = stimVectorRaw(ceil(peakIdxs(:)/4));
	% inputVel(inputVel>10) = NaN;
	% % peakIdxs
	% peakIdxs = peakIdxs(1:1000);
	% % behaviorMovie = behaviorMovie(:,:,peakIdxs);
	% % load movie
	% vidList = getFileList(options.videoDir,trialRegExp);
	% peakIdxs(:)
	% behaviorMovie = loadMovieList(vidList{1},'convertToDouble',options.convertToDouble,'frameList',peakIdxs(:));
	% playMovie(behaviorMovie,'extraLinePlot',inputVel);
	% playMovie(behaviorMovie);
	% =====================
	timeSeq = [-20:20];
	nSignals = size(IcaTraces,1);
	% get the signal aligned to movement, initiation and termination
	nShuffles = 20;
	stimVectorArray = {stimVector, [0 diff(stimVector)]==1, [0 diff(stimVector)]==-1};
	stimNameArray = {'movementAll','movementInitiation','movementTermination'};
	for stimID = 1:length(stimVectorArray)
		signalAlignedMovement{stimID} = alignSignal(signalPeaksRaw, stimVectorArray{stimID},timeSeq,'overallAlign',1)/nSignals;
		% shuffle to get Z scores
		reverseStr = '';
		for i=1:nShuffles
			alignedSignalShuffled(:,i) = alignSignal(shuffleMatrix(signalPeaksRaw,'waitbarOn',0), stimVectorArray{stimID},timeSeq,'overallAlign',1)'/nSignals;
			% alignedSignalStimShuffled(:,i) = alignSignal(signalPeaks, shuffleMatrix(stimVector,'waitbarOn',0),timeSeq,'overallAlign',1)';
			reverseStr = cmdWaitbar(i,nShuffles,reverseStr,'inputStr','shuffling alignment','waitbarOn',1,'displayEvery',1);
		end
		alignedSignalShuffledMean = mean(alignedSignalShuffled,2);
		alignedSignalShuffledStd = std(alignedSignalShuffled,0,2);
		lenTimeseqHalf = floor(length(timeSeq)/2);
	    % calculate Zscore
	    zscores = (signalAlignedMovement{stimID}-alignedSignalShuffledMean)./alignedSignalShuffledStd;
	    signalAlignedMovementZscore{stimID} = zscores;
	    zscoresPost = sum(zscores(lenTimeseqHalf+1:end));
	    zscoresPre = sum(zscores(1:lenTimeseqHalf));
		% SUMMARY_STATS_ADD
		ostruct.summaryStats.(strcat(stimNameArray{stimID},'ZscorePost'))(fileNum,1) = sum(zscoresPost);
		ostruct.summaryStats.(strcat(stimNameArray{stimID},'ZscorePre'))(fileNum,1) = sum(zscoresPre);
		ostruct.summaryStats.(strcat(stimNameArray{stimID},'Max'))(fileNum,1) = nanmax(signalAlignedMovement{stimID});
	end
    % =====================
	% get the sliding correlation
    windowSize = 1e3;
	[slidingCorrelation] = computeSlidingCorrelation(avgPeaksPerPt',stimVectorRaw','windowSize',windowSize);
	ostruct.otherdata.slidingCorrelation{fileNum} = slidingCorrelation;
	% SUMMARY_STATS_ADD
	ostruct.summaryStats.slidingCorrStd(fileNum,1) = nanstd(slidingCorrelation);
	ostruct.summaryStats.slidingCorrVar(fileNum,1) = nanvar(slidingCorrelation);
    ostruct.summaryStats.slidingCorrSkew(fileNum,1) = skewness(slidingCorrelation);
    ostruct.summaryStats.slidingCorrKurt(fileNum,1) = kurtosis(slidingCorrelation);
	% ostruct.tables.
    % =====================
	% get mutual information
	% miScores = MutualInformation(stimVector,signalPeaks);
	miScoresShuffled = mutualInformationShuffle(stimVector,signalPeaks);
	miZscores = miScoresShuffled(:,4);
	saveFile = char(strrep(strcat(options.picsSavePath,'MIShuffleScores_',thisFileID,'.png'),'/',''));
	saveas(gcf,saveFile);
	% get number significantly modulated
	sigModSignals3s = miScoresShuffled(:,1)>(miScoresShuffled(:,2)+3*miScoresShuffled(:,3));
	sigModSignals = miScoresShuffled(:,1)>(miScoresShuffled(:,2)+1.96*miScoresShuffled(:,3));
	% SUMMARY_STATS_ADD
	ostruct.summaryStats.pctMI3sigma(fileNum,1) = sum(sigModSignals3s)/length(sigModSignals3s);
	ostruct.summaryStats.pctMI2sigma(fileNum,1) = sum(sigModSignals)/length(sigModSignals);

	% [mapFig ooo] = openFigure(3, '');
	% 	[groupedImagesMISig] = groupImagesByColor(IcaFilters,sigModSignals');
	% 	groupedImagesMISig = createObjMap(groupedImagesMISig);
	% 	imagesc(groupedImagesMISig); colormap hot; colorbar; axis square;
	% 	title([num2str(subject) '\_' assay]);
	% % ostruct = addValuesToBigData(ostruct,1:length(gfunction(:,nGroups)),gfunction(:,nGroups),{'gfunDist'},thisSubjType);
	% saveFile = char(strrep(strcat(options.picsSavePath,'MIShuffleScoresCellmap_',thisFileID,'.png'),'/',''));
	% saveas(gcf,saveFile);
	% =====================
	% get the grouped images
	% miScoresNormalized = normalizeVector(miScores);
	% miScoresGrouped = group_equally(miScores, 10);
	miScoresGrouped = sigModSignals;
	% [groupedImages] = groupImagesByColor(IcaFilters,miScoresGrouped+1);
	[groupedImages] = groupImagesByColor(IcaFilters,miZscores);
	groupedImageCellmap = createObjMap(groupedImages);
    % =====================
    % firing rate grouped images
    numPeakEvents = sum(signalPeaks,2);
    [groupedImagesRates] = groupImagesByColor(IcaFilters,numPeakEvents);
    groupedImageCellmapRates = createObjMap(groupedImagesRates);
    % firing rate histogram
    maxPeakEvents = max(numPeakEvents)+(5-mod(max(numPeakEvents),5));
    firingRateBins = 0:5:maxPeakEvents;
    firingRateBinCounts = histc(numPeakEvents,firingRateBins);
    % SUMMARY_STATS_ADD
    ostruct.summaryStats.meanNumPeaks(fileNum,1) = nanmean(numPeakEvents);
    % =====================
    % movement triggered maps
    eventROI = [-2:2];
    stimArray = {stimVector, ~stimVector};
    for iStim = 1:length(stimArray)
        nEvents = sum(stimArray{iStim})*length(eventROI);
        alignedSignalObjs = alignSignal(signalPeaksRaw, stimArray{iStim},eventROI,'overallAlign',0);
        alignedSignalObjsEvents{iStim} = sum(alignedSignalObjs,1)/nEvents;
        maxVal(iStim) = max(alignedSignalObjsEvents{iStim});
    end
    alignedSignalObjsEvents{length(stimArray)+1} = alignedSignalObjsEvents{1} - alignedSignalObjsEvents{2}
    % ./(alignedSignalObjsEvents{1} + alignedSignalObjsEvents{2});
    maxVal = max(maxVal);
    nameArray = {'stimulus','not stimulus','stimulus diff'};
    for idNum = 1:length(nameArray)
        display(['analyzing ' nameArray{idNum}]);
        [mapFig ooo] = openFigure(2, '');
        subplot(2,ceil(length(nameArray)/2),idNum)
        % add in fake filter for normalizing across trials
        IcaFiltersTmp = IcaFilters;
        if ~(idNum==length(nameArray))
            IcaFiltersTmp(end+1,:,:) = 0;
            IcaFiltersTmp(end,1,1) = 1;
            alignedSignalObjsEvents{idNum}(end+1) = maxVal;
        end
        [groupedImagesRates] = groupImagesByColor(IcaFiltersTmp,alignedSignalObjsEvents{idNum});
        groupedImageCellmapRates = createObjMap(groupedImagesRates);
        imagesc(groupedImageCellmapRates); axis square;
        box off; axis off;
        colormap(ostruct.colormap);cb = colorbar('location','southoutside');
        title([num2str(subject) '\_' assay ' ' nameArray{idNum}]);
    end
    saveFile = char(strrep(strcat(options.picsSavePath,'movementOnOffCellmap_',thisFileID,'.png'),'/',''));
    saveas(gcf,saveFile);
    % pause
    % =====================
	% get centroid locations along with distance matrix
	[xCoords yCoords] = findCentroid(IcaFilters);
	dist = pdist([xCoords(:) yCoords(:)]);
	npts = length(xCoords);
	distanceMatrix = diag(realmax*ones(1,npts))+squareform(dist);
	% calculate the G-function for each group
	uniqueGroups = unique(miScoresGrouped);
	nGroups = length(uniqueGroups);
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
	nSignals = size(miScoresShuffled,1);
	nSignificantSignals = sum(miScoresGrouped);
	nShuffles = 20;
	for shuffleNo=1:nShuffles
		groupIdx = randsample(nSignals,nSignificantSignals,false);
		minDistances = min(distanceMatrix(groupIdx,groupIdx));
		for i=1:50
			gfunctionShuffled(i,shuffleNo)=sum(minDistances<=i)/length(minDistances);
		end
	end
	gfunctionShuffledMean = mean(gfunctionShuffled,2);
	gfunctionShuffledStd = std(gfunctionShuffled,0,2);

	for i=1:(nGroups-1)
		[ktestReject(i) ktestPval(i) ktestStat(i)]  = kstest2(gfunction(:,nGroups),gfunction(:,i),'Tail','unequal');
	end
	% SUMMARY_STATS_ADD
	% use the fisher to combine p-values
	ostruct.summaryStats.gfunctionFisher(fileNum,1) = -2*nansum(log(ktestPval));
	%
	ktestReject = [ktestReject NaN];
	ktestStatStr = arrayfun(@(x) sprintf('p<0.05 = %d',x),ktestReject,'un',0);
	% = poissrnd(lambda,m,n,...)
	% clusters = kmeans([xCoords(:) yCoords(:)],10,'Distance','sqEuclidean');
	% scatter(xCoords, yCoords, 30, clusters, 'filled')
	% clusters = clusterdata([xCoords(:) yCoords(:)],'distance','euclidean','maxclust',10);
	% =================================================================
	% struct2table(ostruct.summaryStats)
	movTable = struct2table(ostruct.summaryStats);
	writetable(movTable,['private\data\' ostruct.info.protocol{fileNum} '_movementSummary.tab'],'FileType','text','Delimiter','\t');
	% =================================================================
	% FIGURES
	figNo = 400;
	if ostruct.counter==1|~any(strcmp('plots',fieldnames(ostruct)))
		ostruct.plots.figCount = 0;
		ostruct.plots.plotCount = 1;
		ostruct.plots.sheight = 2;
		ostruct.plots.swidth = 3;
	end

	nSignals = size(IcaTraces,1);
    % =======
	% look at MI score distribution
  %   [figHandle figNo] = openFigure(figNo, '');
		% hist(sum(miScores,2),30);box off;
		% title(['distribution of MI scores for ' ostruct.subject{fileNum}]);
		% xlabel('MI score');ylabel('count');
		% h = findobj(gca,'Type','patch');
		% set(h,'FaceColor',[0 0 0],'EdgeColor','w');
		% saveFile = char(strrep(strcat(options.picsSavePath,'MIscores_',thisFileID,'.png'),'/',''));
		% saveas(gcf,saveFile);
		% hold off;
	% =======
	[figHandle figNo] = openFigure(figNo, '');
		viewLineFilledError(gfunctionShuffledMean,gfunctionShuffledStd);
    	hold on;
    	plot(gfunction);box off; xlabel('distance (px)'); ylabel('G(d)');
    	title(strcat(thisID, ', ', num2str(nSignals), ' | G-function distributions (i.e. spatial clustering)'));
    	legend({'shuffled std','shuffled mean','not significant','significant'},'Location','SouthEast')
    	saveFile = char(strrep(strcat(options.picsSavePath,'Gfunction_MI_cellDistances_',thisFileID,'.png'),'/',''));
    	saveas(gcf,saveFile);
    	hold off;
    % =======
	% plot the cells colored by MI percentile
	[figHandle figNo] = openFigure(figNo, '');
		imagesc(groupedImageCellmap);
		box off; axis off;
		colormap(ostruct.colormap);cb = colorbar('location','southoutside');
		title(strcat(thisID, ', ', num2str(nSignals), ' | MI z-scores'));
		saveFile = char(strrep(strcat(options.picsSavePath,'cellmaps_MIcolored_',thisFileID,'.png'),'/',''));
		saveas(gcf,saveFile);
		hold off;
    % =======
    % plot the cells colored by transients
    [figHandle figNo] = openFigure(figNo, '');
        imagesc(groupedImageCellmapRates);
        box off; axis off;
        colormap(ostruct.colormap);cb = colorbar('location','southoutside');
        title(strcat(thisID, ', ', num2str(nSignals), ' firing rate (Hz)'));
        saveFile = char(strrep(strcat(options.picsSavePath,'cellmaps_transients_',thisFileID,'.png'),'/',''));
        % saveFile = 'private\pics\da_sd.png';
        saveas(gcf,saveFile);
        hold off;
    % =======
	% plot scatterplots of the unique functions
	% [figHandle figNo] = openFigure(figNo, '');
	% 	uniqueGroups = unique(miScoresGrouped);
	% 	nGroups = length(uniqueGroups);
	% 	suptitle(strcat(thisID, ', ', num2str(nSignals), ' cells colored by MI score quantile'));
	% 	for groupNum=nGroups:-1:1
	% 	    groupId = uniqueGroups(groupNum);
	% 	    groupIdx = find(miScoresGrouped==groupId);
	% 	    subplot(4,ceil(nGroups/4),groupNum);
	% 	    scatter(xCoords(groupIdx),yCoords(groupIdx),30,miScoresGrouped(groupIdx),'filled');
	% 	    axis off;caxis([1 nGroups+1])
	% 	    if groupNum==1
	% 	       colorbar;
	% 	    end
	% 	end
	% 	saveFile = char(strrep(strcat(options.picsSavePath,'cellmaps_MIcolored_facet_',thisFileID,'.png'),'/',''));
	% 	saveas(gcf,saveFile);
	% 	hold off;
    % =======
	% plot the G-function scores
	% [figHandle figNo] = openFigure(figNo, '');
	% 	plot(gfunction);box off; xlabel('distance (px)'); ylabel('G(d)');
	% 	set(gca,'ColorOrder',copper(nGroups)); hold on
	% 	plot(gfunction);box off; xlabel('distance (px)'); ylabel('G(d)');
	% 	title(strcat(thisID, ', ', num2str(nSignals), ' G-function of different MI groups, X^2 = ', num2str(ostruct.data.gfunctionFisher(fileNum,1))));
	% 	legend(ktestStatStr)
	% 	saveFile = char(strrep(strcat(options.picsSavePath,'Gfunction_MI_cellDistances',thisFileID,'.png'),'/',''));
	% 	saveas(gcf,saveFile);
	% 	hold off;
		% pause
    % =======
	% plot the sliding correlation
	[figHandle figNo] = openFigure(figNo, '');
		plot(slidingCorrelation);box off;
		xlabel('frames');ylabel('corr');
		title(strcat(thisID, ', ', num2str(nSignals), ' signals, spike and movement correlation during trial'));
		saveFile = char(strrep(strcat(options.picsSavePath,'spikeMovCorr_',thisFileID,'.png'),'/',''));
		saveas(gcf,saveFile);
		hold off;
    % =======
	% plot the movement triggered average
	alignStr = {'all movement','movement initiation','movement termination'};
	for iSigMov=1:length(signalAlignedMovement)
		[figHandle figNo] = openFigure(figNo, '');
			plot(timeSeq,signalAlignedMovement{iSigMov}');box off;
			xlabel('frames relative to stimulus');ylabel('peaks');
			title(strcat(thisID, ', ', num2str(nSignals), ' signals, firing relative to stimulus: ',alignStr{iSigMov}));
			saveFile = char(strrep(strcat(options.picsSavePath,'movTriggeredFiring_',thisFileID,'_',num2str(iSigMov),'.png'),'/',''));
			% saveFile = 'private\pics\da_sd.png';
			saveas(gcf,saveFile);
			hold off;
	end
    % =======
	% plot a heatmap of the location of the firing rates at each location
	[figHandle figNo] = openFigure(figNo, '');
		allIdx = [outputData.signalPeakIdx{:}];
		yAtPeaks = outputData.downsampledXM(allIdx);
		xAtPeaks = outputData.downsampledYM(allIdx);
		figHandle = smoothhist2D([yAtPeaks; xAtPeaks]',7,[100,100],0.05,'image');hold on;box off;
		colormap(flipud(gray))
		set(figHandle,'MarkerEdgeColor','k','MarkerSize',14);

		xflip = [outputData.downsampledXM(1 : end - 1) fliplr(outputData.downsampledXM)];
		yflip = [outputData.downsampledYM(1 : end - 1) fliplr(outputData.downsampledYM)];
		patch(xflip, yflip, 'r', 'EdgeColor','r','EdgeAlpha', 0.2, 'FaceColor', 'none');
		% plot(outputData.downsampledXM,outputData.downsampledYM,'r');hold on;box off;
		title(strcat(thisID, ', ', num2str(nSignals), ' signals, red = path, 2D histogram = firing intensity'));
		box off; axis off;
		% colorbar
		% plot(yAtPeaks,xAtPeaks,'k.','MarkerSize',14);hold off;drawnow
		saveFile = char(strrep(strcat(options.picsSavePath,'mov_vs_peaks_',thisFileID,'.png'),'/',''));
		saveas(gcf,saveFile);
		% [x,y,reply]=ginput(1);
		hold off;

	% plot a heatmap of the location of the firing rates at each location
	[figHandle figNo] = openFigure(figNo, '');
		subplot(ostruct.plots.sheight,ostruct.plots.swidth,ostruct.plots.plotCount);
		figHandle = smoothhist2D([outputData.downsampledXM(stimVector); outputData.downsampledYM(stimVector)]',7,[100,100],[],'image');hold on;box off;
		colormap(flipud(gray))
		xflip = [outputData.downsampledXM(1 : end - 1) fliplr(outputData.downsampledXM)];
		yflip = [outputData.downsampledYM(1 : end - 1) fliplr(outputData.downsampledYM)];
		set(figHandle,'MarkerEdgeColor','k','MarkerSize',14);
		patch(xflip(stimVector), yflip(stimVector), 'r', 'EdgeColor','r','EdgeAlpha', 0.2, 'FaceColor', 'none');
		% plot(outputData.downsampledXM,outputData.downsampledYM,'r');hold on;box off;
		box off; axis off;
		title(strcat(thisID, ', locations during movement'));
		% colorbar
		% plot(yAtPeaks,xAtPeaks,'k.','MarkerSize',14);hold off;drawnow
		saveFile = char(strrep(strcat(options.picsSavePath,'all_mov_vs_peaks_fig',num2str(ostruct.plots.figCount),'.png'),'/',''));
		saveas(gcf,saveFile);
		% [x,y,reply]=ginput(1);
		hold off;

	% =================================================================
	% CROSS-SUBJECT FIGURES
	colorIdx = strmatch(ostruct.summaryStats.subjectType(fileNum,1),ostruct.lists.subjectType);
    thisSubjType = ostruct.summaryStats.subjectType(fileNum,1);
	subjColor = ostruct.lists.typeColors(colorIdx,:);
    % initialize output of multi-animal data
    if ostruct.counter==1
        ostruct.bigData.frame = [];
        ostruct.bigData.value = [];
        ostruct.bigData.varType = {};
        ostruct.bigData.subjectType = {};
        ostruct.bigData.subject = {};
    end
    % =======
	% plot the movement triggered average for all subjects
	alignStr = {'all_movement','movement_initiation','movement_termination'};
	alignTitleStr = {'all movement','movement initiation','movement termination'};
    normalizeList = {'normalized','unnormalized'};
 %    for iLoop = 1:2
	% 	for iSigMov=1:length(signalAlignedMovement)
	% 		thisMov = signalAlignedMovement{iSigMov};
	% 		[figHandle figNo] = openFigure(figNo, '');
	% 			[legendHandle] = groupColorLegend(ostruct.lists.subjectType,ostruct.lists.typeColors);

	% 			if iLoop==1
	% 				% normalize vector
	% 				range = max(thisMov) - min(thisMov);
	% 				a = (thisMov - min(thisMov)) / range;
	% 			else
	% 				a = thisMov;
	% 			end
	%             % a = thisMov/nSignals;
	% 			phandle = plot(timeSeq,a','Color',ostruct.lists.typeColors(colorIdx,:));box off;
	% 			hold on;
	% 			xlabel('frames relative to stimulus');ylabel('peaks');
	% 			title(strcat(normalizeList{iLoop},': ',alignTitleStr{iSigMov}));
	% 			saveFile = char(strrep(strcat(options.picsSavePath,'all_signalAlignedMovement',normalizeList{iLoop},'_',num2str(iSigMov),'.png'),'/',''));
	% 			% saveFile = 'private\pics\da_sd.png';
	% 			saveas(gcf,saveFile);

	%             ostruct = addValuesToBigData(ostruct,timeSeq,a,{strcat(normalizeList{iLoop},'_',alignStr{iSigMov})},thisSubjType);
	% 	end
	% end
    % =======
    % z scores
	% plot the movement triggered average for all subjects
    for iLoop = 1:2
		for iSigMov=1:length(signalAlignedMovementZscore)
			thisMov = signalAlignedMovementZscore{iSigMov};
			[figHandle figNo] = openFigure(figNo, '');
				[legendHandle] = groupColorLegend(ostruct.lists.subjectType,ostruct.lists.typeColors);

				if iLoop==1
					% normalize vector
					range = max(thisMov) - min(thisMov);
					a = (thisMov - min(thisMov)) / range;
				else
					a = thisMov;
				end
	            % a = thisMov/nSignals;
				phandle = plot(timeSeq,a','Color',ostruct.lists.typeColors(colorIdx,:));box off;
				hold on;
				xlabel('frames relative to stimulus');ylabel('peaks');
				title(strcat(normalizeList{iLoop},' Zscores: ',alignTitleStr{iSigMov}));
				saveFile = char(strrep(strcat(options.picsSavePath,'all_signalAlignedMovementZscore_',normalizeList{iLoop},'_',num2str(iSigMov),'.png'),'/',''));
				% saveFile = 'private\pics\da_sd.png';
				saveas(gcf,saveFile);

	            ostruct = addValuesToBigData(ostruct,timeSeq,a,{strcat(normalizeList{iLoop},'_',alignStr{iSigMov},'_Zscore')},thisSubjType);
		end
	end
    % =======
    % all subject sliding correlation
    [figHandle figNo] = openFigure(figNo, '');
        [legendHandle] = groupColorLegend(ostruct.lists.subjectType,ostruct.lists.typeColors);
        phandle = plot(slidingCorrelation,'Color',subjColor);box off;
        hold on;
        xlabel('frames');ylabel('corr');
        title(['spike and movement correlation during trial, windows=' num2str(windowSize)]);

        saveFile = char(strrep(strcat(options.picsSavePath,'all_spikeMovCorr_.png'),'/',''));
        % saveFile = 'private\pics\da_sd.png';
        saveas(gcf,saveFile);
    % =======
	% plot the cumulative movement for all subjects
	[figHandle figNo] = openFigure(figNo, '');
		[legendHandle] = groupColorLegend(ostruct.lists.subjectType,ostruct.lists.typeColors);

		phandle = plot(cumsum(thisVel),'Color',subjColor);box off;
		hold on;
		xlabel('trial time (frames)');ylabel('velocity (cm/sec)');
		title('cumulative movement');

		saveFile = char(strrep(strcat(options.picsSavePath,'all_cumMovement_.png'),'/',''));
		saveas(gcf,saveFile);

        % ostruct = addValuesToBigData(ostruct,1:length(thisVel),cumsum(thisVel),{'cumulative movement'},thisSubjType);
    % =======
	% look at the distribution of simultaneous firing events
	[figHandle figNo] = openFigure(figNo, '');
		[legendHandle] = groupColorLegend(ostruct.lists.subjectType,ostruct.lists.typeColors);

        spreadPeakSignal = sum(spreadSignal(outputData.signalPeaks,'timeSeq',[-2:2]),1);
		maxH = max(spreadPeakSignal);
		histH = hist(spreadPeakSignal,[0:maxH]);
		plot([0:maxH], histH, 'Color', subjColor);box off;
		set(gca,'YScale','log');
		title('distribution simultaneous firing events');
		xlabel('simultaneous spikes');ylabel('count');
		hold on;

		saveFile = char(strrep(strcat(options.picsSavePath,'all_firingEventDist.png'),'/',''));
		saveas(gcf,saveFile);

        ostruct = addValuesToBigData(ostruct,0:maxH,histH,{'simultaneousfiringEventsDist'},thisSubjType);
    % =======
    % look at the distribution of firing events
    [figHandle figNo] = openFigure(figNo, '');
        [legendHandle] = groupColorLegend(ostruct.lists.subjectType,ostruct.lists.typeColors);
        plot(firingRateBins, firingRateBinCounts, 'Color', subjColor);box off;
        title('distribution of firing rates');
        xlabel('firing rate');ylabel('count');
        hold on;

        saveFile = char(strrep(strcat(options.picsSavePath,'all_firingRateDist.png'),'/',''));
        saveas(gcf,saveFile);

        ostruct = addValuesToBigData(ostruct,firingRateBins,firingRateBinCounts,{'firingEventsDist'},thisSubjType);
    % =======
	% look at the distribution of Gfunctions
	[figHandle figNo] = openFigure(figNo, '');
		for i=1:length(ostruct.lists.subjectType)
		    plot(1,1,'Color',ostruct.lists.typeColors(i,:));
		    hold on
		end
		hleg1 = legend(ostruct.lists.subjectType);

		plot(gfunction(:,nGroups), 'Color', subjColor);box off;
		xlabel('distance (px)'); ylabel('G(d)');
		title('G-function for highest scoring MI group');
		hold on;

		saveFile = char(strrep(strcat(options.picsSavePath,'all_Gfunction.png'),'/',''));
		saveas(gcf,saveFile);

        ostruct = addValuesToBigData(ostruct,1:length(gfunction(:,nGroups)),gfunction(:,nGroups),{'gfunDist'},thisSubjType);
    % =======
    [figHandle figNo] = openFigure(figNo, '');
        subplot(ostruct.plots.sheight,ostruct.plots.swidth,ostruct.plots.plotCount);
        	% scatter(outputData.avgPeaksPerPt, thisVel,[],~(thisVel<1),'Marker','.','SizeData',3);
            % scatter(outputData.avgPeaksPerPt, thisVel,'Marker','.','SizeData',3,'MarkerFaceColor','k','MarkerEdgeColor','k');
            plot(outputData.avgPeaksPerPt, thisVel,'.','MarkerSize',2,'MarkerFaceColor',subjColor,'MarkerEdgeColor',subjColor)
        	title(strcat(ostruct.subject{fileNum},'|',ostruct.summaryStats.subjectType(fileNum),'|',ostruct.assay{fileNum}));
        	if ostruct.plots.plotCount==1
        		xlabel('peaks/frame')
        		ylabel('velocity')
        	end
        	set(gca,'xlim',[0 10],'ylim',[0 13]);
        	fitVals = polyfit(outputData.avgPeaksPerPt, thisVel,1);
        	refHandle = refline(fitVals(1),fitVals(2));
        	set(gca,'Color','none'); box off;drawnow;
            refHandle2 = refline(0,STIM_CUTOFF);
            set(refHandle2,'Color','r')

        saveFile = char(strrep(strcat(options.picsSavePath,'all_stim_vs_firing_fig',num2str(ostruct.plots.figCount),'.png'),'/',''));
        saveas(gcf,saveFile);
    % =======
    % increment file counter
    ostruct.counter = ostruct.counter+1;

    % signal = 1;
    % exitLoop = 0;
    % nSignals = size(IcaTraces,1);
    % directionOfNextChoice = 1;
    % while exitLoop==0
    %   plot(outputData.downsampledXM,outputData.downsampledYM,'r');hold on;box off;
    %   title(['signal: ' num2str(signal) '/' num2str(nSignals)]);
    %   yAtPeaks = outputData.downsampledXM(outputData.signalPeakIdx{signal});
    %   xAtPeaks = outputData.downsampledYM(outputData.signalPeakIdx{signal});
    %   plot(yAtPeaks,xAtPeaks,'k.','MarkerSize',14);hold off;drawnow
    %   [x,y,reply]=ginput(1);
    %   if isequal(reply, 28)
    %         % go back, left
    %         directionOfNextChoice=-1;
    %     elseif isequal(reply, 29)
    %         % go forward, right
    %         directionOfNextChoice=1;
    %   elseif isequal(reply, 102)
    %       % user clicked 'f' for finished, exit loop
    %       exitLoop=1;
    %       % i=nFilters+1;
    %   elseif isequal(reply, 103)
    %       % if user clicks 'g' for goto, ask for which IC they want to see
    %       icChange = inputdlg('enter IC #'); icChange = str2num(icChange{1});
    %       if icChange>nFilters|icChange<1
    %           % do nothing, invalid command
    %       else
    %           i = icChange;
    %           directionOfNextChoice = 0;
    %       end
    %   else
    %       directionOfNextChoice = 1;
    %   end
    %   signal = signal+directionOfNextChoice;
    %   if signal<=0
    %       i = nSignals;
    %   elseif signal>nSignals;
    %       i = 1;
    %   end
    % end

    % nameArray = {'velocity'};
    % i = 1;
    % plot velocity vs. firing rate
	% figure(655+ostruct.plots.figCount)
	% 	subplot(5,ceil(nFiles/5),fileNum);
	% 		smoothhist2D([outputData.avgPeaksPerPt; thisVel]',7,[100,100],0,'image');
	% 		if fileNum==1
	% 			xlabel('firing rate (peaks/frame)')
	% 			ylabel([nameArray{i} ' (unit/frame)'])
	% 		end
	% struct2table(ostruct.bigData)
	if mod(ostruct.plots.plotCount,ostruct.plots.sheight*ostruct.plots.swidth)==0
	   ostruct.plots.figCount = ostruct.plots.figCount+1;
	   ostruct.plots.plotCount = 1;
	else
	   ostruct.plots.plotCount = ostruct.plots.plotCount+1;
	end

function [ostruct] = addValuesToBigData(ostruct,frame,value,varType,subjectType)
    % small function to add values to big data
    numPtsToAdd = length(frame(:));
    ostruct.bigData.frame(end+1:end+numPtsToAdd,1) = frame(:);
    ostruct.bigData.value(end+1:end+numPtsToAdd,1) = value(:);
    ostruct.bigData.varType(end+1:end+numPtsToAdd,1) = varType;
    ostruct.bigData.subjectType(end+1:end+numPtsToAdd,1) = subjectType;
    ostruct.bigData.subject(end+1:end+numPtsToAdd,1) = {ostruct.curentSubject};

function [ostruct] = matchObjAcrossTrials(ostruct, options, fileNum, nFiles, thisDir,thisDirSaveStr)

	% =======
	fileToLoad = {strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr}),strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr})};
	variableStruct = loadFileToVariables(fileToLoad,options);
	if any(strcmp('null',fieldnames(variableStruct))); return; else; fn=fieldnames(variableStruct); end;
	for i=1:length(fn); eval([fn{i} '=variableStruct.' fn{i} ';']); end
	% =======

	size(IcaFilters)
	ostruct.inputImages{ostruct.counter} = IcaFilters;
	ostruct.inputSignals{ostruct.counter} = IcaTraces;
	lengthSignal = size(IcaTraces,2);
	if ostruct.counter==1
		ostruct.lengthLongestSignal = lengthSignal;
	elseif lengthSignal>ostruct.lengthLongestSignal
		ostruct.lengthLongestSignal = lengthSignal;
	end

	thisID = strcat(ostruct.subject{fileNum},'\_',ostruct.info.subjectType(fileNum),'\_',ostruct.assay{fileNum});
	thisFileID = strcat(ostruct.subject{fileNum},'_',ostruct.info.subjectType(fileNum),'_',ostruct.assay{fileNum});

	ostruct.counter = ostruct.counter+1;
	if ostruct.counter==(ostruct.nAnalyzeFolders+1)
		ostruct.alignmentStruct = matchObjBtwnTrials(ostruct.inputImages,'inputSignals',ostruct.inputSignals);
		% save structure
		alignmentStruct = ostruct.alignmentStruct;
		saveID = {options.alignmentSaveName};
		saveVariable = {'alignmentStruct'};
		for i=1:length(saveID)
			savestring = [thisDirSaveStr saveID{i}];
			display(['saving: ' savestring])
			save(savestring,saveVariable{i},'-v7.3');
		end

		saveFile = char(strrep(strcat(options.picsSavePath,'alignmentCentroids_',thisFileID,'.png'),'/',''));
		saveas(gcf,saveFile);
		% look at the statistics and alignment of cells
		[matchedObjMaps] = displayMatchingObjs(ostruct.inputImages,ostruct.alignmentStruct.globalIDs,'inputSignals',ostruct.inputSignals);

		figure(421)
        colormap(ostruct.colormap);
        cb = colorbar('location','southoutside');
	end

function loadControllerFiles(filesToLoad,altFilesToLoad)

	% if files don't exist, load alts
	if(~exist(filesToLoad{1}, 'file'))
		filesToLoad=altFilesToLoad;
		if(~exist(filesToLoad{1}, 'file'))
			return
		end
	end
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

function compareSignalToMovieController(thisDir, fileFilterRegexp,thisDirSaveStr, options)
	%get the list of movies to load
	movieList = getFileList(thisDir, fileFilterRegexp);

	% load movies
	[thisMovie o m n] = loadMovieList(movieList);

	% load traces and filters
	filesToLoad=strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr});
	% if bad ICs haven't been removed yet, use the raw
	if(~exist(filesToLoad{1}, 'file'))
		% filesToLoad=strcat(thisDirSaveStr, {rawICfiltersSaveStr,rawICtracesSaveStr});
		filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr});
		if(~exist(filesToLoad{1}, 'file'))
            tmp = getFileList(thisDir,options.rawICfiltersSaveStr);
			filesToLoad{1} = tmp{1};
            tmp = getFileList(thisDir,options.rawICtracesSaveStr);
            filesToLoad{2} = tmp{1};
		end
	end
	for i=1:length(filesToLoad)
		display(['loading: ' filesToLoad{i}]);
		load(filesToLoad{i})
	end

	compareSignalToMovie(thisMovie, IcaFilters, IcaTraces);

function convertToSpikeEFxn(thisDirSaveStr,options)
	% convert to SpikeE data format
	filterFilePath = [thisDirSaveStr options.cleanedICfiltersSaveStr];
	traceFilePath = [thisDirSaveStr options.cleanedICtracesSaveStr];
	[SpikeImageData, SpikeTraceData] = convertToSpikeE(filterFilePath, traceFilePath, 'toSpikeE');
	save([thisDir filesep thisID '_ICfilters_SpikeE.mat'], 'SpikeImageData');
	save([thisDir filesep thisID '_ICtraces_SpikeE.mat'], 'SpikeTraceData');

function objectMaps(ostruct,fileNum,nFiles,thisDir,thisDirSaveStr,options)

    thisFileID = strcat(ostruct.subject{fileNum},'_',ostruct.assay{fileNum});

    if ~exist('IcaFilters','var')
        fileToLoad = {strcat(thisDirSaveStr, {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr}),strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr})};
        variableStruct = loadFileToVariables(fileToLoad,options);
        if any(strcmp('null',fieldnames(variableStruct))); return; else; fn=fieldnames(variableStruct); end;
        for i=1:length(fn); eval([fn{i} '=variableStruct.' fn{i} ';']); end
	end

	% remove bad traces
	% rmList = sum(~isnan(IcaTraces),2)~=0;
	% IcaTraces = IcaTraces(rmList,:);
	% IcaFilters = IcaFilters(rmList,:);
	% rmList = sum(IcaTraces,2)~=0;
	% IcaTraces = IcaTraces(rmList,:);
	% IcaFilters = IcaFilters(rmList,:);

    [figHandle figNo] = openFigure(969, '');
	    s1 = subplot(1,2,1);
		    % coloredObjs = groupImagesByColor(thresholdImages(IcaFilters),[]);
		    % thisCellmap = createObjMap(coloredObjs);
		    % firing rate grouped images
		    numPeakEvents = sum(signalPeaks,2);
		    numPeakEvents = numPeakEvents/size(signalPeaks,2)*options.framesPerSecond;
		    [groupedImagesRates] = groupImagesByColor(IcaFilters,numPeakEvents);
		    thisCellmap = createObjMap(groupedImagesRates);

		    % if fileNum==1
		    %     fig1 = figure(32);
		    %     % colormap gray;
		    % end
			% thisCellmap = createObjMap([thisDirSaveStr options.rawICfiltersSaveStr]);
			% subplot(round(nFiles/4),4,fileNum);
			imagesc(thisCellmap);
			colormap(ostruct.colormap);cb = colorbar('location','southoutside'); ylabel(cb, 'Hz');
		    % colormap hot; colorbar;
			% title(regexp(thisDir,'m\d+', 'match'));
			title([ostruct.subject{fileNum} ' | ' ostruct.assay{fileNum} ' | firing rate map | ' num2str(size(signalPeaks,1))])
			box off; axis tight; axis off;
			set(gca, 'LooseInset', get(gca,'TightInset'))

		[signalSnr a] = computeSignalSnr(IcaTraces,'testpeaks',signalPeaks,'testpeaksArray',signalPeakIdx);
	[figHandle figNo] = openFigure(969, '');
		s2 = subplot(1,2,2);
			[signalSnr sortedIdx] = sort(signalSnr,'descend');
			sortedIcaTraces = IcaTraces(sortedIdx,:);
			signalPeakIdx = {signalPeakIdx{sortedIdx}};
			cutLength = 100;
			nSignalsShow = 20;
			sortedIcaTracesCut = zeros([nSignalsShow cutLength*2+1]);
			shiftVector = round(linspace(round(cutLength/10),round(cutLength*0.9),nSignalsShow));
			shiftVector = shiftVector(randperm(length(shiftVector)));
			for i=1:nSignalsShow
				spikeIdx = signalPeakIdx{i};
				spikeIdxValues = sortedIcaTraces(i,spikeIdx);
				[k tmpIdx] = max(spikeIdxValues);
				spikeIdx = spikeIdx(tmpIdx);
				spikeIdx = spikeIdx-(round(cutLength/2)-shiftVector(i));
				% spikeIdx
				% cutLength
				nPoints = size(IcaTraces,2);
				if (spikeIdx-cutLength)<0
					beginDiff = abs(spikeIdx-cutLength);
					cutIdx = bsxfun(@plus,spikeIdx,-(cutLength-beginDiff-1):(cutLength+beginDiff+1));
					cutIdx = 1:(cutLength*2+1);
				elseif (spikeIdx+cutLength)>nPoints
					endDiff = abs(-spikeIdx);
					cutIdx = bsxfun(@plus,spikeIdx,-(cutLength+endDiff+1):(cutLength-endDiff-1));
					cutIdx = (nPoints-(cutLength*2)):nPoints;
				else
					cutIdx = bsxfun(@plus,spikeIdx,-cutLength:cutLength);
				end
				if ~isempty(cutIdx)
					sortedIcaTracesCut(i,:) = sortedIcaTraces(i,cutIdx(:)');
				end
			end
			sortedIcaTracesCut = flip(sortedIcaTracesCut,1);
			size(sortedIcaTracesCut)
			plotSignalsGraph(sortedIcaTracesCut,'LineWidth',2.5);
			nTicks = 10;
			set(gca,'XTick',round(linspace(1,size(sortedIcaTracesCut,2),nTicks)))
			labelVector = round(linspace(1,size(sortedIcaTracesCut,2),nTicks)/options.framesPerSecond)
			set(gca,'XTickLabel',labelVector);
			xlabel('seconds');ylabel('dfof');
			box off;
			title('example traces');
		d=0.02; %distance between images
		set(s1,'position',[d 0.1 0.5-2*d 0.8])
     	set(s2,'position',[0.5+d 0.1 0.5-2*d 0.8])
	    saveFile = char(strrep(strcat(options.picsSavePath,'cellmap_',thisFileID,''),'/',''));
	    set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
	    % figure(figHandle)
	    print('-dpng','-r200',saveFile)
	    print('-dmeta','-r200',saveFile)
	    % saveas(gcf,saveFile);
		drawnow;
		options.movieList

	[figHandle figNo] = openFigure(970, '');
		% timeVector = (1:size(sortedIcaTracesCut,2))/options.framesPerSecond;
		plotSignalsGraph(sortedIcaTracesCut,'LineWidth',2.5);
		nTicks = 10;
		set(gca,'XTick',round(linspace(1,size(sortedIcaTracesCut,2),nTicks)))
		labelVector = round(linspace(1,size(sortedIcaTracesCut,2)/options.framesPerSecond,nTicks))
		set(gca,'XTickLabel',labelVector);
		xlabel('seconds');ylabel('dfof');
		box off;
		% axis off;
		% title('example traces');
		title([ostruct.subject{fileNum} ' | ' ostruct.assay{fileNum} ' | example traces'])
	    saveFile = char(strrep(strcat(options.picsSavePath,'traces_',thisFileID,''),'/',''));
	    saveFile
	    set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
	    % figure(figHandle)
	    print('-dpng','-r200',saveFile)
	    print('-dmeta','-r200',saveFile)
	    % saveas(gcf,saveFile);
		drawnow;
		options.movieList

	if ~isempty(options.movieList)
		[figHandle figNo] = openFigure(971, '');
			movieFrame = loadMovieList(options.movieList{1},'convertToDouble',options.convertToDouble,'frameList',1:2);
			movieFrame = squeeze(movieFrame(:,:,1));
			% imagesc(imadjust(movieFrame));
			imagesc(movieFrame);
			% imshow(movieFrame);
			axis off; colormap gray;
			title([ostruct.subject{fileNum} ' | ' ostruct.assay{fileNum} ' | blue>green>red percentile rank']);
			hold on;
			icaQ = quantile(numPeakEvents,[0.3 0.6]);
			IcaFiltersThresholded = thresholdImages(IcaFilters,'binary',0);
			% IcaFiltersThresholded = IcaFilters;
			colorObjMaps{1} = createObjMap(IcaFiltersThresholded(numPeakEvents<icaQ(1),:,:));
			colorObjMaps{2} = createObjMap(IcaFiltersThresholded(numPeakEvents>icaQ(1)&numPeakEvents<icaQ(2),:,:));
			colorObjMaps{3} = createObjMap(IcaFiltersThresholded(numPeakEvents>icaQ(2),:,:));

			zeroMap = zeros(size(movieFrame));
			oneMap = ones(size(movieFrame));
			green = cat(3, zeroMap, oneMap, zeroMap);
			blue = cat(3, zeroMap, zeroMap, oneMap);
			red = cat(3, oneMap, zeroMap, zeroMap);
			warning off
			blueOverlay = imshow(blue);
			greenOverlay = imshow(green);
			redOverlay = imshow(red);
			warning on
			set(redOverlay, 'AlphaData', colorObjMaps{1}/2);
			set(greenOverlay, 'AlphaData', colorObjMaps{2}/2);
			set(blueOverlay, 'AlphaData', colorObjMaps{3}/2);
			set(gca, 'LooseInset', get(gca,'TightInset'))
			hold off;
			saveFile = char(strrep(strcat(options.picsSavePath,'cellmap_overlay_',thisFileID,''),'/',''));
			saveFile
			set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
			% figure(figHandle)
			print('-dpng','-r200',saveFile)
			% print('-dmeta','-r200',saveFile)
			% saveas(gcf,saveFile);
			% pause

		IcaFiltersThresholded = thresholdImages(IcaFilters,'binary',0);
		saveFile = char(strcat(thisDirSaveStr,'cellmap_thresholded.h5'));
		thisObjMap = createObjMap(IcaFiltersThresholded);
		movieSaved = writeHDF5Data(thisObjMap,saveFile)
		IcaFiltersThresholded = thresholdImages(IcaFilters,'binary',1);
		saveFile = char(strcat(thisDirSaveStr,'cellmap_thresholded_binary.h5'));
		thisObjMap = createObjMap(IcaFiltersThresholded);
		movieSaved = writeHDF5Data(thisObjMap,saveFile)
	end

function [ostruct] = trainClassifier(ostruct,thisDir, fileFilterRegexp,thisDirSaveStr, options, fileNum)
	% load traces and filters
	if exist(options.classifierFilepath, 'file')
		filesToLoad = {options.classifierFilepath};
		display(['loading: ' filesToLoad{1}]);
		load(filesToLoad{1});
	else
		display(['no classifier at: ' options.classifierFilepath])
	end
	% =======
	addToOstruct = 1;
	% load filters/traces
    filesToLoad=strcat(thisDirSaveStr, {options.rawICfiltersSaveStr,options.rawICtracesSaveStr,options.cleanedICdecisionsSaveStr});
    if(~exist(filesToLoad{1}, 'file'))
    	display('no files');
    	% ostruct.counter = ostruct.counter+1;
        addToOstruct = 0;
    end
    if(~exist(filesToLoad{3}, 'file'))&strcmp('training',options.trainingOrClassify)
    	display('no decisions');
    	% ostruct.counter = ostruct.counter+1;
    	addToOstruct = 0;
    end
	% =======
	if addToOstruct==1
		for i=1:length(filesToLoad)
		    display(['loading: ' filesToLoad{i}]);
		    load(filesToLoad{i})
		end
		ostruct.inputImages{ostruct.counter} = IcaFilters;
		ostruct.inputSignals{ostruct.counter} = IcaTraces;
		valid(valid==-1) = 0;
		ostruct.validArray{ostruct.counter} = valid;
	end

	if strcmp('classify',options.trainingOrClassify)
		ioption.classifierType = options.classifierType;
		ioption.trainingOrClassify = options.trainingOrClassify;
		ioption.inputTargets = {ostruct.validArray{ostruct.counter}};
		ioption.inputStruct = classifierStruct
		[ostruct.classifier] = classifySignals({ostruct.inputImages{ostruct.counter}},{ostruct.inputSignals{ostruct.counter}},'options',ioption);
		% ostruct.data.confusionPct
		% ostruct.classifier.confusionPct
		if ~any(strcmp('summaryStats',fieldnames(ostruct)))
			ostruct.summaryStats.subject{1,1} = nan;
			ostruct.summaryStats.assay{1,1} = nan;
			ostruct.summaryStats.assayType{1,1} = nan;
			ostruct.summaryStats.assayNum{1,1} = nan;
			ostruct.summaryStats.confusionPctFN{1,1} = nan;
			ostruct.summaryStats.confusionPctFP{1,1} = nan;
			ostruct.summaryStats.confusionPctTP{1,1} = nan;
			ostruct.summaryStats.confusionPctTN{1,1} = nan;
		end
		ostruct.summaryStats.subject{end+1,1} = ostruct.subject{fileNum};
		ostruct.summaryStats.assay{end+1,1} = ostruct.assay{fileNum};
		ostruct.summaryStats.assayType{end+1,1} = ostruct.info.assayType{fileNum};
		ostruct.summaryStats.assayNum{end+1,1} = ostruct.info.assayNum{fileNum};
		ostruct.summaryStats.confusionPctFN{end+1,1} = ostruct.classifier.confusionPct(1);
		ostruct.summaryStats.confusionPctFP{end+1,1} = ostruct.classifier.confusionPct(2);
		ostruct.summaryStats.confusionPctTP{end+1,1} = ostruct.classifier.confusionPct(3);
		ostruct.summaryStats.confusionPctTN{end+1,1} = ostruct.classifier.confusionPct(4);
	end

	ostruct.counter = ostruct.counter+1;
	if ostruct.counter==(ostruct.nAnalyzeFolders+1)&strcmp('training',options.trainingOrClassify)
		ioption.classifierType = options.classifierType;
		ioption.trainingOrClassify = options.trainingOrClassify;
		ioption.inputTargets = ostruct.validArray;
		[ostruct.classifier] = classifySignals(ostruct.inputImages,ostruct.inputSignals,'options',ioption);
		% [ostruct.classifier] = classifySignals(ostruct.inputImages,ostruct.inputSignals,'inputTargets',ostruct.validArray,'classifierType',options.classifierType);


		% save classifier
		classifierStruct = ostruct.classifier;
		saveVariable = {'classifierStruct'};
		for i=1:length(saveVariable)
			savestring = options.classifierFilepath;
			display(['saving: ' savestring])
			save(savestring,saveVariable{i});
		end
	end

% function [ostruct] = labelMovie(ostruct,thisDir, fileFilterRegexp,thisDirSaveStr, options)

