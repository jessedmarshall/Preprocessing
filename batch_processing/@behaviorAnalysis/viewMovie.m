function obj = viewMovie(obj)
	% view movie
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
	% =====================
	% fileFilterRegexp = obj.fileFilterRegexp;
	FRAMES_PER_SECOND = obj.FRAMES_PER_SECOND;
	% DOWNSAMPLE_FACTOR = obj.DOWNSAMPLE_FACTOR;
	options.videoPlayer = [];
	% =====================
	if isempty(options.videoPlayer)
		usrIdxChoiceStr = {'matlab','imagej'};
		scnsize = get(0,'ScreenSize');
		[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which video player to use?');
		options.videoPlayer = usrIdxChoiceStr{sel};
	end
	% =====================
	if ~isempty(obj.videoDir)
		videoDir = strjoin(obj.videoDir,',');
	else
		videoDir = '';
	end
	movieSettings = inputdlg({...
			'start:end frames (leave blank for all)',...
			'behavior:movie sample rate (downsample factor): ',...
			'imaging movie regexp:',...
			'video folder(s), separate multiple folders by a comma:',...
			'side-by-side save folder:',...
			'analyze specific folder (leave blank if no)',...
			'show behavior video (0 = no, 1 = yes)',...
			'create movie montages (0 = no, 1 = yes)',...
			'create signal-based montages (0 = no, 1 = yes)',...
			'ask for movie list (0 = no, 1 = yes)'...
			'save movie? (0 = no, 1 = yes)',...
		},...
		'view movie settings',1,...
		{...
			'1:500',...
			num2str(obj.DOWNSAMPLE_FACTOR),...
			obj.fileFilterRegexp,...
			videoDir,....
			obj.videoSaveDir,...
			'',...
			'0',...
			'0',...
			'0',...
			'0',...
			'0'...
		}...
	);
	frameList = str2num(movieSettings{1});
	DOWNSAMPLE_FACTOR = str2num(movieSettings{2});
	% obj.fileFilterRegexp = movieSettings{3};
	% fileFilterRegexp = obj.fileFilterRegexp;
	fileFilterRegexp = movieSettings{3};
	% eval(['{''',movieSettings{4},'''}'])
	obj.videoDir = strsplit(movieSettings{4},','); videoDir = obj.videoDir;
	obj.videoSaveDir = movieSettings{5}; videoSaveDir = obj.videoSaveDir;
	analyzeSpecificFolder = movieSettings{6};
	showBehaviorVideo = str2num(movieSettings{7});
	createMontageVideosSwitch = str2num(movieSettings{8});
	createSignalBasedVideosSwitch = str2num(movieSettings{9});
	askForMovieList = str2num(movieSettings{10});
	saveCopyOfMovie = str2num(movieSettings{11});
	% =====================
	% FINISH INCORPORATING!!
	videoTrialRegExp = '';
	if showBehaviorVideo==1
		videoTrialRegExpList = {'yyyy_mm_dd_pNNN_mNNN_assayNN','yymmdd-mNNN-assayNN','yymmdd_mNNN_assayNN','subject_assay'};
		scnsize = get(0,'ScreenSize');
		[videoTrialRegExpIdx, ok] = listdlg('ListString',videoTrialRegExpList,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','video string type (N = number)');
		local_getVideoRegexp();
		% videoTrialRegExpList = {'yyyy_mm_dd_pNNN_mNNN_assayNN','yymmdd-mNNN-assayNN','subject_assay'};
		% scnsize = get(0,'ScreenSize');
		% [videoTrialRegExpIdx, ok] = listdlg('ListString',videoTrialRegExpList,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','video string type (N = number)');
	else

	end
	% % =====================
	if strcmp(options.videoPlayer,'imagej')
		Miji;
		% MIJ.exit;
		% MIJ.start;
	end
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	if ~isempty(analyzeSpecificFolder)
		nFilesToAnalyze = 1;
	end
	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ': ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			% subject = obj.subjectNum{obj.fileNum};
			% assay = obj.assay{obj.fileNum};
			% =====================
			% frameList
			if isempty(analyzeSpecificFolder)
				movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
			else
				analyzeSpecificFolder
				fileFilterRegexp
				movieList = getFileList(analyzeSpecificFolder, fileFilterRegexp);
			end
			movieList
			if askForMovieList == 1;
				scnsize = get(0,'ScreenSize');
				[movieMontageIdx, ok] = listdlg('ListString',movieList,'ListSize',[scnsize(3)*0.7 scnsize(4)*0.25],'Name','which movies to view?');
			else
				movieMontageIdx = 1:length(movieList);
			end
			nMovies = length(movieMontageIdx);
			for movieNo = 1:length(movieMontageIdx)
				display(['movie ' num2str(movieMontageIdx(movieNo)) '/' num2str(nMovies) ': ' movieList{movieMontageIdx(movieNo)}])

				[primaryMovie] = loadMovieList(movieList{movieMontageIdx(movieNo)},'convertToDouble',0,'frameList',frameList(:));
				% treatMoviesAsContinuous

				local_getVideoRegexp();
				vidList = getFileList(videoDir,videoTrialRegExp);
				if ~isempty(vidList)
					% get the movie
					% vidList
					if iscell(primaryMovie)
						% [primaryMovie{end+1}] = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw');
					else
						primaryMovieTmp = primaryMovie; clear primaryMovie;
						primaryMovie{1} = primaryMovieTmp; clear primaryMovieTmp;
					end
					% frameListTmp = 1:min(cellfun(@(x) size(x,3), primaryMovie));
					if isempty(frameList)
						% trueVidTotalFrames = size(primaryMovie,3)*DOWNSAMPLE_FACTOR;
						frameListTmp = 1:size(primaryMovie{1},3);
						% frameListTmp = round(frameListTmp/DOWNSAMPLE_FACTOR);
					else
						frameListTmp = frameList;
					end
					primaryMovie{end+1} = loadMovieList(vidList,'convertToDouble',0,'frameList',frameListTmp(:)*DOWNSAMPLE_FACTOR,'treatMoviesAsContinuous',1);
					[primaryMovie{end}] = normalizeVector(single(primaryMovie{end}),'normRange','zeroToOne');
					[primaryMovie{end}] = normalizeMovie(primaryMovie{end},'normalizationType','meanSubtraction');
				else
					% [primaryMovie] = loadMovieList(movieList{movieMontageIdx(movieNo)},'convertToDouble',0,'frameList',frameList(:));
				end
				if createSignalBasedVideosSwitch==1
					% [inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filtered');
					% {rawICfiltersSaveStr,rawICtracesSaveStr}
					% {rawICfiltersSaveStr,rawROItracesSaveStr}
					% [inputSignals inputImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
					% [inputSignals, inputImages, ~, ~] = modelGetSignalsImages(obj,'returnType','filtered','regexPairs',{{obj.rawICfiltersSaveStr,obj.rawROItracesSaveStr}});
					[inputSignals, inputImages, ~, ~] = modelGetSignalsImages(obj,'returnType','raw','regexPairs',{{obj.rawICfiltersSaveStr,obj.rawROItracesSaveStr}});
					if iscell(primaryMovie)
						% [primaryMovie{end+1}] = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw');
					else
						primaryMovieTmp = primaryMovie; clear primaryMovie;
						primaryMovie{1} = primaryMovieTmp; clear primaryMovieTmp;
					end
					tmpMovie = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw','normalizeOutputMovie','no');
					tmpMovie(tmpMovie<0.03) = NaN;
					% tmpMovie(1:20,1:20,1)
					% imagesc(squeeze(tmpMovie(:,:,1)));colorbar
					[primaryMovie{end+1}] = tmpMovie; clear tmpMovie;

					% [inputSignals, ~, ~, ~] = modelGetSignalsImages(obj,'returnType','filtered_traces');
					[inputSignals, ~, ~, ~] = modelGetSignalsImages(obj,'returnType','raw_traces');
					tmpMovie = createSignalBasedMovie(inputSignals(:,frameList(:)),inputImages,'signalType','raw','normalizeOutputMovie','no');
					tmpMovie(tmpMovie<0.03) = NaN;
					[primaryMovie{end+1}] = tmpMovie; clear tmpMovie;
				end

				if iscell(primaryMovie)
					% primaryMovie = montageMovies(primaryMovie);
					[primaryMovie] = createMontageMovie(primaryMovie,'identifyingText',{'dfof','','ROI','ICA'},'normalizeMovies', zeros([length(primaryMovie) 1]));
				end


				if saveCopyOfMovie==1
					savePathName = [obj.videoSaveDir filesep 'preview' filesep 'preview_' obj.fileIDArray{obj.fileNum} '.h5']
					[output] = writeHDF5Data(primaryMovie,savePathName);
				else
					playMovieThisFunction()
				end
				clear primaryMovie;
			end

			if createMontageVideosSwitch==1
				scnsize = get(0,'ScreenSize');
				[movieMontageIdx, ok] = listdlg('ListString',movieList,'ListSize',[scnsize(3)*0.7 scnsize(4)*0.25],'Name','which movies to make montage?');
				clear primaryMovie;
				if ok==1
					movieList{movieMontageIdx}
					[cropCoords] = getCropMovieCoords({movieList{movieMontageIdx}});

					for movieNo = 1:length(movieMontageIdx)
						[primaryMovie{movieNo}] = loadMovieList(movieList{movieMontageIdx(movieNo)},'convertToDouble',0,'frameList',frameList(:));
						fileInfo = getFileInfo(movieList{movieMontageIdx(movieNo)});
						movieTmp = primaryMovie{movieNo};
						nFrames = size(movieTmp,3);
						for frameNo = 1:nFrames
							movieTmp(:,:,frameNo) = squeeze(sum(...
								insertText(movieTmp(:,:,frameNo),[0 0],[fileInfo.subject '_' fileInfo.assay],...
								'BoxColor','white',...
								'AnchorPoint','LeftTop',...
								'BoxOpacity',1)...
							,3));
						end
						if isempty(cropCoords{movieNo})
							primaryMovie{movieNo} = movieTmp;
						else
							pts = cropCoords{movieNo};
							primaryMovie{movieNo} = movieTmp(pts(2):pts(4), pts(1):pts(3),:);
						end
					end

					videoTrialRegExp
					vidList = getFileList(videoDir,videoTrialRegExp);
					vidList
					if ~isempty(vidList)
						% get the movie
						vidList
						frameListTmp = 1:min(cellfun(@(x) size(x,3), primaryMovie));
						primaryMovie{end+1} = loadMovieList(vidList,'convertToDouble',0,'frameList',frameListTmp(:)*DOWNSAMPLE_FACTOR,'treatMoviesAsContinuous',1);
					end

					primaryMovie = montageMovies(primaryMovie);
					% [primaryMovie] = createMontageMovie(primaryMovie,'identifyingText',{'dfof','','ROI','ICA'});

					savePathName = [obj.videoSaveDir filesep 'montage_' obj.fileIDArray{obj.fileNum} '.h5']
					[output] = writeHDF5Data(primaryMovie,savePathName);

					playMovieThisFunction()
				end
			end

		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	if strcmp(options.videoPlayer,'imagej')
		MIJ.exit;
	end

	function playMovieThisFunction()
		switch options.videoPlayer
			case 'matlab'
				[exitSignal movieStruct] = playMovie(primaryMovie,'extraTitleText',obj.fileIDNameArray{obj.fileNum});
			case 'imagej'
				% Miji;
				MIJ.createImage('result', primaryMovie, true);
				clear primaryMovie;
				uiwait(msgbox('press OK to move onto next movie','Success','modal'));
				% MIJ.run('Close');
				MIJ.run('Close All Without Saving');
				% MIJ.exit;
			otherwise
				% body
		end
	end
	function local_getVideoRegexp()
		switch videoTrialRegExpIdx
			case 1
				videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
			case 2
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'-',obj.subjectStr{obj.fileNum},'-',obj.assay{obj.fileNum});
			case 2
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'_',obj.subjectStr{obj.fileNum},'_',obj.assay{obj.fileNum});
			case 3
				videoTrialRegExp = [obj.subjectStr{obj.fileNum} '_' obj.assay{obj.fileNum}]
			otherwise
				videoTrialRegExp = fileFilterRegexp
		end
	end
end
function [inputMovies] = montageMovies(inputMovies)
	nMovies = length(inputMovies);
	[xPlot yPlot] = getSubplotDimensions(nMovies);
	% movieLengths = cellfun(@(x){size(x,3)},inputMovies);
	% maxMovieLength = max(movieLengths{:});
	normalizeMoviesOption = 0;
	inputMovieNo = 1;
	for xNo = 1:xPlot
		for yNo = 1:yPlot
			if inputMovieNo>length(inputMovies)
				[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},NaN(size(inputMovies{1})),'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',normalizeMoviesOption);
			elseif yNo==1
				[behaviorMovie{xNo}] = inputMovies{inputMovieNo};
			else
				[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},inputMovies{inputMovieNo},'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',normalizeMoviesOption);
			end
			size(behaviorMovie{xNo})
			inputMovieNo = inputMovieNo+1;
		end
	end
	size(behaviorMovie{1})
	behaviorMovie{1} = permute(behaviorMovie{1},[2 1 3]);
	size(behaviorMovie{1})
	display(repmat('-',1,7))
	for concatNo = 2:length(behaviorMovie)
		[behaviorMovie{1}] = createSideBySide(behaviorMovie{1},permute(behaviorMovie{concatNo},[2 1 3]),'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',normalizeMoviesOption);
		behaviorMovie{concatNo} = {};
		size(behaviorMovie{1});
	end
	inputMovies = behaviorMovie{1};
	% behaviorMovie = cat(behaviorMovie{:},3)
end
%% getCropMovieCoords: function description
function [cropCoords] = getCropMovieCoords(movieList)
	% movieList
	nMovies = length(movieList);
	options.refCropFrame = 1;
	options.datasetName = '/1';

	usrIdxChoiceStr = {'YES | duplicate coords across multiple movies','NO | do not duplicate coords across multiple movies'};
	scnsize = get(0,'ScreenSize');
	[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','use coordinates over multiple folders?');
	if ok==0
		for movieNo = 1:nMovies
			cropCoords{movieNo} = {};
		end
		return
	end
	usrIdxChoiceList = {1,0};
	applyPreviousCoords = usrIdxChoiceList{sel};

	for movieNo = 1:nMovies
		inputFilePath = movieList{movieNo};

		[pathstr,name,ext] = fileparts(inputFilePath);
		if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
			hinfo = hdf5info(inputFilePath);
			hReadInfo = hinfo.GroupHierarchy.Datasets(1);
			xDim = hReadInfo.Dims(1);
			yDim = hReadInfo.Dims(2);
			% select the first frame from the dataset
			thisFrame = readHDF5Subset(inputFilePath,[0 0 options.refCropFrame],[xDim yDim 1],'datasetName',options.datasetName);
		elseif strcmp(ext,'.tif')|strcmp(ext,'.tiff')
			TifLink = Tiff(inputFilePath, 'r'); %Create the Tiff object
			thisFrame = TifLink.read();%Read in one picture to get the image size and data type
			TifLink.close(); clear TifLink
		end

		[figHandle figNo] = openFigure(9, '');
		subplot(1,2,1);imagesc(thisFrame); axis image; colormap gray; title('click, drag-n-draw region')
		set(0,'DefaultTextInterpreter','none');
		suptitle([num2str(movieNo) '\' num2str(nMovies) ': ' strrep(inputFilePath,'\','/')]);
		set(0,'DefaultTextInterpreter','latex');

		% Use ginput to select corner points of a rectangular
		% region by pointing and clicking the subject twice
		% fileInfo = getFileInfo(thisDir);
		if movieNo==1
			p = round(getrect);
		elseif applyPreviousCoords==1
			% skip, reuse last coordinates
		else
			p = round(getrect);
		end

		% Get the x and y corner coordinates as integers
		cropCoords{movieNo}(1) = p(1); %xmin
		cropCoords{movieNo}(2) = p(2); %ymin
		cropCoords{movieNo}(3) = p(1)+p(3); %xmax
		cropCoords{movieNo}(4) = p(2)+p(4); %ymax

		% Index into the original image to create the new image
		pts = cropCoords{movieNo};
		thisFrameCropped = thisFrame(pts(2):pts(4), pts(1):pts(3));
		% Display the subsetted image with appropriate axis ratio
		[figHandle figNo] = openFigure(9, '');
		subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;
	end
end