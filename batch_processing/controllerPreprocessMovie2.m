function [ostruct] = controllerPreprocessMovie2(varargin)
	% controller for pre-processing movies, mainly aimed at miniscope data
	% biafra ahanonu
	% started 2013.11.09 [10:46:23]

	% changelog
		% 2013.11.10 - refactored to make the work-flow more obvious and more easily modifiable by others. Now outputs a structure that contains information about what occured during the run.
		% 2013.11.11 - allowed increased flexibility in terms of inputting PCs/ICs and loading default options.
		% 2013.11.18
		% 2014.01.07 [11:12:19] adding to changelog again: updated support for tif files.
		% 2014.01.23 [20:23:02] fixed getCurrentMovie bug, wasn't passing options.datasetName to loadMovieList.
		% 2014.06.06 removed sub-function for now to improve memory usage and made it easier for the user to choose what pre-processing to do and save.
		% 2015.01.05 [20:00:26] turboreg options uses uicontrol now instead of pulldown and is more dynamic.
		% 2015.01.19 [20:43:49] - changed how turboreg is passed to function to improve memory usage, also moved dfof and downsample directly into function to reduce memory footprint there as well.
	% TODO
		% Allow easy switching between analyzing all files in a folder together and each file in a folder individually
		% FML, make this object oriented...
		% Allow reading in of subset of movie for turboreg analysis, e.g. if we have super large movies

	% remove pre-compiled functions
	clear FUNCTIONS;
	% load necessary functions and defaults
	loadBatchFxns();
	%========================
	% set the options, these can be modified by varargin
	options.folderListPath='manual';
	% should each movie in a folder be processed separately?
	options.processMoviesSeparately = 0;
	% should the movies be processed or just an ostruct be created?
	options.processMovies=1;
	% set this to an m-file with default options
	options.loadOptionsFromFile = 0;
	% number of frames to subset to reduce turboreg overhead
	options.turboregNumFramesSubset = 3000;
	% how to turboreg, options: 'preselect','coordinates','other'. Only pre-select is implemented currently.
	options.turboregType = 'preselect';
	% 1 = rotation, 0 = no rotation
	options.turboreg.turboregRotation = 1;
	% should the movie be dfof'd?
	options.dfofMovie = 1;
	% method of doing deltaF/F: 'dfof', 'divide', 'minus'
	options.dfofType = 'dfof';
	% factor to downsample by
	options.downsampleFactor = 4;
	% number of pixels to crop around movie
	options.pxToCrop = 14;
	% the regular expression used to find files
	options.fileFilterRegexp = 'concatenated_.*.h5';
	% decide whether to get nICs and nPCs from file list
	options.inputPCAICA = 0;
	% ask for # PC/ICs at the end
	options.askForPCICs = 0;
	% number of frames from input movie to analyze
	options.frameList = [];
	% name for dataset in HDF5 file
	options.datasetName = '/1';
	% reference frame used for cropping and turboreg
	options.refCropFrame = 1;
	% ====
	% OLD OPTIONS
	% should the movie be saved?
	options.saveMovies = 0;
	% save the final movie
	options.saveDfofMovie = 0;
	% should the movie be turboreg'd
	options.turboregMovie = 1;
	% normalize the movie (e.g. divisive normalization)
	options.normalizeMovie = 0;
	% should the movie be downsampled?
	options.downsampleMovie = 1;
	% ====
	% get options
	options = getOptions(options,varargin);
	options
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	startDir = pwd;
	% read in the list of folders
	if strcmp(class(options.folderListPath),'char')&~strcmp(options.folderListPath,'manual')
		if ~isempty(regexp(options.folderListPath,'.txt'))
			fid = fopen(options.folderListPath, 'r');
			tmpData = textscan(fid,'%s','Delimiter','\n');
			folderList = tmpData{1,1};
			fclose(fid);
		else
			% user just inputs a single directory
			folderList = {options.folderListPath};
		end
		nFiles = length(folderList);
	elseif strcmp(class(options.folderListPath),'cell')
		folderList = options.folderListPath;
		nFiles = length(folderList);
	else
		if strcmp(options.folderListPath,'manual')
			[folderListPath,folderPath,~] = uigetfile('*.*','select text file that points to analysis folders','example.txt');
			% exit if user picks nothing
			if folderListPath==0
				return
			end
			folderListPath = [folderPath folderListPath];
		else
			folderListPath = options.folderListPath;
		end
		fid = fopen(folderListPath, 'r');
		tmpData = textscan(fid,'%s','Delimiter','\n');
		folderList = tmpData{1,1};
		fclose(fid);
		nFiles = length(folderList);
	end
	%========================
	% allow user to choose steps in the processing
	scnsize = get(0,'ScreenSize');
	analysisOptionList = {'turboreg','fft_highpass','crop','dfof','downsampleTime','fft_lowpass'};
	defaultChoiceList = {'turboreg','crop','dfof','downsampleTime'};
	%defaultChoiceIdx = find(cellfun(@(x) sum(strcmp(x,defaultChoiceList)),analysisOptionList));
	defaultChoiceIdx = find(ismember(analysisOptionList,defaultChoiceList));
	[analysisOptionsIdx, ok] = listdlg('ListString',analysisOptionList,'InitialValue',defaultChoiceIdx,...
	    'Name','the red pill...',...
	    'PromptString',['select analysis steps to perform. will be analyzed top to bottom, with top first'],...
	    'ListSize',[scnsize(3)*0.4 scnsize(4)*0.3]);
	if ok~=1
		return
	end
	defaultSaveList = {'downsampleTime'};
	defaultSaveIdx = find(ismember(analysisOptionList,defaultSaveList));
	[saveIdx, ok] = listdlg('ListString',analysisOptionList,'InitialValue',defaultSaveIdx,...
	    'Name','Gentlemen, you can not fight in here! This is the War Room.',...
	    'PromptString','select at which stages to save a file. if option not selected for analysis, will be ignored',...
	    'ListSize',[scnsize(3)*0.4 scnsize(4)*0.3]);
	if ok~=1
		return
	end
	% only keep save if user selected option to analyze...
	defaultSaveIdx = intersect(analysisOptionsIdx,defaultSaveIdx);
	if isempty(defaultSaveIdx)
		defaultSaveIdx = find(ismember(analysisOptionList,defaultSaveList));
	end
	% ========================
	% ask user for options if particular analysis selected
	% if sum(ismember({analysisOptionList{analysisOptionsIdx}},'turboreg'))==1
		options.turboreg = getTurboregSettings();
		options.turboreg
		options.datasetName = options.turboreg.datasetName;
		options.fileFilterRegexp = options.turboreg.fileFilterRegexp;
		options.processMoviesSeparately = options.turboreg.processMoviesSeparately;
		options.turboregNumFramesSubset = options.turboreg.turboregNumFramesSubset;
	% end
	% ========================
	% allow the user to pre-select all the targets
	if options.processMovies==1
		[turboRegCoords] = turboregCropSelection(options,folderList);
	end
	ostruct.folderList = {}
	% ========================
	folderList
	startTime = tic;
	frameListDlg = 0;
	%
	folderListMinusComments = find(cellfun(@(x) isempty(x),strfind(folderList,'#')));
	nFilesToRun = length(folderListMinusComments);
	fileNumToRun = 1;
	%
	for fileNum=1:nFiles

		movieSaved = 0;
		fileStartTime = tic;
		try
			display(repmat('+',1,42))
			display(repmat('+',1,42))
			% decide whether to get PCA-ICA parameters from file
			if options.inputPCAICA==1
				thisDir = folderList{fileNum};
				% should be folderDir,nPCs,nICs
				dirInfo = regexp(thisDir,',','split');
				thisDir = dirInfo{1};
				if(length(dirInfo)>=3)
					ostruct.nPCs{fileNum} = str2num(dirInfo{3});
					ostruct.nICs{fileNum} = str2num(dirInfo{2});
				else
					display('please add nICs and PCs')
				    ostruct.nPCs{fileNum} = 700;
				    ostruct.nICs{fileNum} = 500;
				end
			else
				% thisDir = folderList{fileNum};
				dirInfo = regexp(folderList{fileNum},',','split');
				thisDir = dirInfo{1};
			end
			% start logging for this file
			display([num2str(fileNum) '/' num2str(length(folderList)) ': ' thisDir]);
			display([num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' thisDir]);
			% check if this directory has been commented out, if so, skip
			if strfind(thisDir,'#')==1
			    display('skipping...')
			    continue;
			end
			diary([thisDir filesep 'preprocess.log']);

			% get the list of movies
			movieList = getFileList(thisDir, options.fileFilterRegexp);
			% get information from directory
			fileInfo = getFileInfo(movieList{1});
			fileInfo
			% base string to save as
			fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.subject '_' fileInfo.assay];
			thisDirSaveStr = [thisDir filesep fileInfoSaveStr];
			saveStr = '';
			% add the folder to the output structure
			ostruct.folderList{fileNum} = thisDir;

			% get the movie
			% [thisMovie ostruct options] = getCurrentMovie(movieList,options,ostruct);
			if frameListDlg==0
                usrIdxChoice = inputdlg('select frame range (e.g. 1:1000), leave blank for all frames');
				% options.frameList = [1:500];
                options.frameList = str2num(usrIdxChoice{1});
                frameListDlg = 1;
			end
			if options.processMoviesSeparately==1
				nMovies = length(movieList);
			else
				nMovies = 1;
			end
			for movieNo = 1:nMovies
				display(['movie ' num2str(movieNo) '/' num2str(nMovies) ': ' ])
				% thisMovieList = movieList{movieNo};
				% 'loadSpecificImgClass','single'
				if options.processMoviesSeparately==1
					thisMovie = loadMovieList(movieList{movieNo},'convertToDouble',0,'frameList',options.frameList,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',0,'loadSpecificImgClass','single');
					% playMovie(thisMovie);
				else
					if isempty(options.frameList)&options.turboreg.loadMoviesFrameByFrame==1
						movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',options.frameList,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',1,'loadSpecificImgClass','single','getMovieDims',1);
						sum(movieDims.z)
						thisFrameList = 1:sum(movieDims.z);
					else
						thisFrameList = options.frameList;
					end
					thisMovie = loadMovieList(movieList,'convertToDouble',0,'frameList',thisFrameList,'inputDatasetName',options.datasetName,'treatMoviesAsContinuous',1,'loadSpecificImgClass','single');
				end

				imagesc(squeeze(thisMovie(:,:,1)))
				suptitle([num2str(fileNumToRun) '/' num2str(nFilesToRun) ': ' strrep(thisDir,'\','/')]);

				% nOptions = length(analysisOptionsIdx)
				saveStr = '';
				% to improve memory usage, edit the movie in loops, at least until this is made object oriented.
				for optionIdx = analysisOptionsIdx
					optionName = analysisOptionList{optionIdx};
					saveStr = [saveStr '_' optionName];
					% if options.processMovies==1
					% 	thisDir = folderList{fileNum};
					% 	% get the list of movies
					% 	movieList = getFileList(thisDir, options.fileFilterRegexp);
					% 	% save the location of the downsampled dfof for PCA-ICA identification
					% 	ostruct.dfofFilePath{fileNum} = movieList{1};
					% 	% add info to ostruct
					% 	ostruct.fileFilterRegexp{fileNum} = 'concatenated_.*.h5';
					% 	ostruct.folderList{fileNum} = thisDir;
					% end
					display(repmat('*',1,7));
					display([optionName ' movie...']);
					try
						switch optionName
							case 'turboreg'
								for iternationNo = 1:options.turboreg.numTurboregIterations
									if strcmp(options.turboreg.normalizeBeforeRegister,'imagejFFT')
										Miji;
									end
									turboregInputMovie();
									if strcmp(options.turboreg.normalizeBeforeRegister,'imagejFFT')
										MIJ.exit;
									end
								end
							case 'crop'
								cropInputMovie();
							case 'fft_highpass'
								fftHighpassInputMovie();
							case 'fft_lowpass'
								fftLowpassInputMovie();
							case 'dfof'
								dfofInputMovie();
							case 'downsampleTime'
								downsampleTimeInputMovie()
							otherwise
								% do nothing
						end
						% save the location of the downsampled dfof for PCA-ICA identification
					catch err
						% save the location of the downsampled dfof for PCA-ICA identification
						ostruct.dfofFilePath{fileNum} = [];
						display(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						display(repmat('@',1,7))
						break;
					end

					% some make single again
					% thisMovie = single(thisMovie);
					% save movie if user selected that option
					optionIdx
					saveIdx
					if sum(optionIdx==saveIdx)
						savePathStr = [thisDirSaveStr saveStr '_' num2str(movieNo) '.h5'];
						% switch optionName
						% case 'downsampleTime'
						% 	options.downsampleZ = [];
						% 	options.downsampleFactor = options.turboreg.downsampleFactorTime;
						% 	if isempty(options.downsampleZ)
						% 		downZ = floor(size(thisMovie,3)/options.downsampleFactor);
						% 	else
						% 		downZ = options.downsampleZ;
						% 	end
						% 	downZ
						% 	display('saving dataset slab...')
						% 	movieSaved = writeHDF5Data(thisMovie,savePathStr,'hdfStart',[1 1 1],'hdfCount',[size(thisMovie,1)-1 size(thisMovie,2)-1 downZ]);
						% otherwise
						% end
						movieSaved = writeHDF5Data(thisMovie,savePathStr)
						ostruct.dfofFilePath{fileNum} = savePathStr;
					end
					display(repmat('$',1,7))
					display(class(thisMovie))
					display(size(thisMovie))
					display(repmat('$',1,7))
				end
			end
			movieFrames = size(thisMovie,3);
			if movieFrames>500
				ostruct.movieFrames{fileNum} = 500;
			else
				ostruct.movieFrames{fileNum} = movieFrames;
			end


			% save file filter regexp based on saveStr
			ostruct.fileFilterRegexp{fileNum} = saveStr;

			toc(fileStartTime)
			toc(startTime)

			fileNumToRun = fileNumToRun + 1;
		catch err
			display(repmat('@',1,7))
			display(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
			%
			clear thisMovie
			ostruct.dfofFilePath{fileNum} = [];
			fileNumToRun = fileNumToRun + 1;
			% try to save the current point in the analysis
			try
				% display(['trying to save: ' savePathStr]);
				% writeHDF5Data(thisMovie,savePathStr);
			catch err2
				display(repmat('@',1,7))
				display(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
				display(getReport(err2,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
			end
		end
		clear thisMovie
		% pause(20);
		% pack
		diary OFF;
	end
	% ask the user for PCA-ICA parameters if not input in the files
	if options.inputPCAICA==0
		[ostruct options] = getPcaIcaParams(ostruct,options)
	end

	toc(startTime)

	cd(startDir)

	function downsampleTimeInputMovie()
		options.downsampleZ = [];
		options.waitbarOn = 1;
		% thisMovie = single(thisMovie);
		options.downsampleFactor = options.turboreg.downsampleFactorTime;
		options.downsampleFactor
		% thisMovie = downsampleMovie(thisMovie,'downsampleFactor',options.downsampleFactor);
		% =====================
		% we do a bit of trickery here: we can downsample the movie in time by downsampling the X*Z 'image' in the Z-plane then stacking these downsampled images in the Y-plane. Would work the same of did Y*Z and stacked in X-plane.
		downX = size(thisMovie,1);
		downY = size(thisMovie,2);
		if isempty(options.downsampleZ)
			downZ = floor(size(thisMovie,3)/options.downsampleFactor);
		else
			downZ = options.downsampleZ;
		end
		downZ
		% pre-allocate movie
		% inputMovieDownsampled = zeros([downX downY downZ]);
		% this is a normal for loop at the moment, if convert inputMovie to cell array, can force it to be parallel
		reverseStr = '';
		for frame=1:downY
		   downsampledFrame = imresize(squeeze(thisMovie(:,frame,:)),[downX downZ],'bilinear');
		   % to reduce memory footprint, place new frame in old movie and cut off the unneeded frames after
		   thisMovie(1:downX,frame,1:downZ) = downsampledFrame;
		   % inputMovie(:,frame,:) = downsampledFrame;
			if mod(frame,20)==0&options.waitbarOn==1|frame==downY
			    reverseStr = cmdWaitbar(frame,downY,reverseStr,'inputStr','temporally downsampling matrix');
			end
        end
        j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
        reverseStr = '';
        % for frame = (downZ+1):size(thisMovie,3)
        %     thisMovie(:,:,1) = [];
        %     reverseStr = cmdWaitbar(frame,downZ,reverseStr,'inputStr','removing elements');
        % end
		%thisMovie = thisMovie(:,:,1:downZ);
		thisMovie(:,:,(downZ+1):end) = 0;
        % thisMovie(:,:,(downZ+1):end) = [];
        thisMovieTmp = thisMovie(:,:,1:downZ);
        clear thisMovie;
        thisMovie = thisMovieTmp;
        clear thisMovieTmp;
        j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
		drawnow;
		% =====================
	end

	function dfofInputMovie()
		% dfof must have positive values
		% thisMovieMin = nanmin(thisMovie(:));
		if strcmp(options.turboreg.normalizeBeforeRegister,'bandpass')
			thisMovie = thisMovie+1;
		end
		% leave mean at 1, goes to zero when doing pca ica
		% thisMovie = dfofMovie(thisMovie,'dfofType',options.dfofType);
		% figure(1970+fileNum)
		% 	subplot(2,1,1)
		% 	plot(squeeze(nanmean(nanmean(thisMovie,1),2)))
		% 	% title(['mean | ' ]);
		% 	ylabel('mean');box off;
		% 	subplot(2,1,2)
		% 	plot(squeeze(nanvar(nanvar(thisMovie,[],1),[],2)))
		% 	% title('variance');
		% 	ylabel('variance');xlabel('frame'); box off;
		% 	suptitle(thisDirSaveStr)
		% =====================
		% get the movie F0
		% thisMovie = single(thisMovie);
	    display('getting F0...')
	    inputMovieF0 = zeros([size(thisMovie,1) size(thisMovie,2)]);
	    nRows = size(thisMovie,1);
	    reverseStr = '';
	    for rowNo=1:nRows
	        % inputMovieF0 = nanmean(inputMovie,3);
	        inputMovieF0(rowNo,:) = nanmean(squeeze(thisMovie(rowNo,:,:)),2);
	        reverseStr = cmdWaitbar(rowNo,nRows,reverseStr,'inputStr','F0','waitbarOn',1,'displayEvery',5);
	    end
		% bsxfun for fast matrix divide
		switch options.dfofType
	        case 'divide'
	            display('F(t)/F0...')
	            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
	            thisMovie = bsxfun(@ldivide,inputMovieF0,thisMovie);
	        case 'dfof'
	            display('F(t)/F0 - 1...')
	            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
	            % thisMovie = bsxfun(@ldivide,inputMovieF0,thisMovie);
	            reverseStr = '';
	            nFrames = size(thisMovie,3);
	            for frameNo = 1:nFrames
	            	thisMovie(:,:,frameNo) = thisMovie(:,:,frameNo)./inputMovieF0;
	            	reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','DFOF','waitbarOn',1,'displayEvery',50);
	            end
	            thisMovie = thisMovie-1;
	        case 'minus'
	            display('F(t)-F0...')
	            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
	            thisMovie = bsxfun(@minus,thisMovie,inputMovieF0);
	        otherwise
	            % return;
	    end
	    % =====================
	end
	function turboregInputMovie()
		% number of frames to subset
		subsetSize = options.turboregNumFramesSubset;
		movieLength = size(thisMovie,3);
		numSubsets = ceil(movieLength/subsetSize)+1;
		subsetList = round(linspace(1,movieLength,numSubsets));
		subsetList
		% convert movie to single for turboreg
		j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
		% thisMovie = single(thisMovie);
		% get reference frame before subsetting, so won't change
		thisMovieRefFrame = squeeze(thisMovie(:,:,options.refCropFrame));
		nSubsets = (length(subsetList)-1);
		% turboregThisMovie = single(zeros([size(thisMovie,1) size(thisMovie,2) 1]));

		% whos
		for thisSet = 1:nSubsets
			subsetStartTime = tic;
			subsetStartIdx = subsetList(thisSet);
			subsetEndIdx = subsetList(thisSet+1);
			display(repmat('$',1,7))
			if thisSet==nSubsets
				movieSubset = subsetStartIdx:subsetEndIdx;
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			end
			display(repmat('$',1,7))
			%run with altered defaults
			% ioptions.Levels = 2;
			% ioptions.Lastlevels = 1;
			% ioptions.complementMatrix = 0;
			% ioptions.minGain=0.0;
			% ioptions.SmoothX = 80;
			% ioptions.SmoothY = 80;
			ioptions.turboregRotation = options.turboreg.turboregRotation;
			ioptions.RegisType = options.turboreg.RegisType;
			ioptions.parallel = options.turboreg.parallel;
			ioptions.meanSubtract = options.turboreg.meanSubtract;
			ioptions.normalizeType = options.turboreg.normalizeType;
			ioptions.registrationFxn = options.turboreg.registrationFxn;
			% if iternationNo~=options.turboreg.numTurboregIterations
			% 	ioptions.normalizeBeforeRegister = [];
			% elseif iternationNo==options.turboreg.numTurboregIterations
			% 	ioptions.normalizeBeforeRegister = options.turboreg.normalizeBeforeRegister;
			% end
			ioptions.normalizeBeforeRegister = options.turboreg.normalizeBeforeRegister;
			ioptions.imagejFFTLarge = options.turboreg.imagejFFTLarge;
			ioptions.imagejFFTSmall = options.turboreg.imagejFFTSmall;

			if ~isempty(options.turboreg.saveNormalizeBeforeRegister)
				options.turboreg.saveNormalizeBeforeRegister = [thisDirSaveStr saveStr '_lowpass.h5']
			end
			ioptions.saveNormalizeBeforeRegister = options.turboreg.saveNormalizeBeforeRegister;
			%
			ioptions.cropCoords = turboRegCoords{fileNum}{movieNo};
			ioptions.closeMatlabPool = 0;
			ioptions.refFrame = options.refCropFrame;
			ioptions.refFrameMatrix = thisMovieRefFrame;
			% for frameDftNo = movieSubset
			% 	refFftFrame = fft2(thisMovieRefFrame);
			% 	regFftFrame = fft2(squeeze(thisMovie(:,:,frameDftNo)));
			% 	[output Greg] = dftregistration(refFftFrame,regFftFrame,100);
			% 	[~, ~] = openFigure(79854, '');
			% 	subplot(1,2,1);
			% 	imagesc(thisMovieRefFrame);
			% 	title(['Reference image: ' num2str(options.refCropFrame)])
			% 	subplot(1,2,2);
			% 	% ifft2(Greg)
			% 	imagesc(real(ifft2(Greg)));
			% 	title(['Registered image: ' num2str(frameDftNo)])
			% 	colormap gray
			% 	drawnow
			% 	% commandwindow
			% 	% pause
			% end
			% playMovie(thisMovie);
			% dt=whos('VARIABLE_YOU_CARE_ABOUT'); MB=dt.bytes*9.53674e-7;
		    % thisMovie(:,:,movieSubset) = turboregMovie(thisMovie(:,:,movieSubset),'options',ioptions);
		    % j = whos('turboregThisMovie');j.bytes=j.bytes*9.53674e-7;j
		    j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
	    	thisMovie(:,:,movieSubset) = turboregMovie(thisMovie(:,:,movieSubset),'options',ioptions);
		    % if thisSet==1&thisSet~=nSubsets
		    % 	% class(movieSubset)
		    % 	% movieSubset
		    % 	% thisMovie(:,:,movieSubset) = [];
		    % 	% thisMovie = thisMovie(:,:,(subsetEndIdx):end);
		    % elseif thisSet==nSubsets
		    % 	% movieSubset-subsetStartIdx+1
		    % 	thisMovie(:,:,movieSubset-subsetStartIdx+1) = turboregMovie(thisMovie(:,:,movieSubset-subsetStartIdx+1),'options',ioptions);
		    % 	% clear thisMovie;
		    % 	% thisMovie = turboregThisMovie;
		    % 	% clear turboregThisMovie;
		    % else
		    % 	% movieSubset-subsetStartIdx+1
		    % 	thisMovie(:,:,movieSubset-subsetStartIdx+1) = turboregMovie(thisMovie(:,:,movieSubset-subsetStartIdx+1),'options',ioptions);
		    % 	% thisMovie(:,:,movieSubset-subsetStartIdx+1) = [];
		    % 	% cutoffSubset = length(movieSubset);
		    % 	% thisMovie = thisMovie(:,:,(cutoffSubset+1):end);
		    % end
		    % j = whos('turboregThisMovie');j.bytes=j.bytes*9.53674e-7;j
		    % j = whos('thisMovie');j.bytes=j.bytes*9.53674e-7;j
		    % tmpMovieClass = class(tmpMovie);
		    % cast(thisMovie,tmpMovieClass);
		    % thisMovie(:,:,movieSubset) = tmpMovie;
		    toc(subsetStartTime)
		end
	    clear ioptions;
	    size(thisMovie)
	    imagesc(squeeze(thisMovie(:,:,1)))
	    	title(['iteration number: ' num2str(iternationNo)])
	end
	function cropInputMovie()
		% turboreg outputs 0s where movement goes off the screen
		thisMovieMinMask = zeros([size(thisMovie,1) size(thisMovie,2)]);
		options.turboreg.registrationFxn
		switch options.turboreg.registrationFxn
			case 'imtransform'
				reverseStr = '';
				for row=1:size(thisMovie,1)
					% nanmin(~isnan(squeeze(thisMovie(row,:,:))),[],2)
					% thisMovieMinMask(row,:) = ~logical(nanmin(~isnan(squeeze(thisMovie(row,:,:))),[],2)>0);
					if row==1
						logical(nanmin(squeeze(thisMovie(row,:,:)),[],2)==0)'
					end
					thisMovieMinMask(row,:) = logical(nanmin(squeeze(thisMovie(row,:,:)),[],2)==0);
					reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
					% logical(nanmin(~isnan(thisMovie(row,:,:)),[],3)==0);
				end
			case 'transfturboreg'
				% thisMovieMinMask = logical(nanmin(thisMovie~=0,[],3)==0);
				reverseStr = '';
				for row=1:size(thisMovie,1)
					thisMovieMinMask(row,:) = logical(nanmin(squeeze(thisMovie(row,:,:))~=0,[],2)==0);
					reverseStr = cmdWaitbar(row,size(thisMovie,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
					% logical(nanmin(~isnan(thisMovie(row,:,:)),[],3)==0);
				end
			otherwise
				% do nothing
		end
		% [figHandle figNo] = openFigure(79854+fileNum, '');
		% imagesc(thisMovieMinMask); colormap gray;
		% suptitle(thisDirSaveStr);
		% thisMovieMinMask(thisMovieMinMask==0) = NaN;
		% thisMovie = bsxfun(@times,thisMovieMinMask,thisMovie);
		topVal = sum(thisMovieMinMask(1:floor(end/4),floor(end/2)))
		bottomVal = sum(thisMovieMinMask(end-floor(end/4):end,floor(end/2)))
		leftVal = sum(thisMovieMinMask(floor(end/2),1:floor(end/4)))
		rightVal = sum(thisMovieMinMask(floor(end/2),end-floor(end/4):end))
		tmpPxToCrop = max([topVal bottomVal leftVal rightVal]);

    	% % crop movie based on how much was turboreg'd
    	% display('cropping movie...')
    	% varImg = nanvar(thisMovie,[],3);
    	% varImg = var(thisMovie,0,3);
    	% medianVar = median(varImg(:));
    	% stdVar = std(varImg(:));
    	% twoSigma = 2*medianVar;
    	% varImgX = median(varImg,1);
    	% varImgY = median(varImg,2);
    	% varThreshold = 1e3;
    	% tmpPxToCrop = max([sum(varImgX>varThreshold) sum(varImgY>varThreshold)]);
    	% imagesc(nanvar(thisMovie,[],3));
    	% title('turboreg var projection');
    	% % tmpPxToCrop = 10;
    	tmpPxToCrop
    	if tmpPxToCrop~=0
	    	if tmpPxToCrop<options.pxToCrop
	    		% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',tmpPxToCrop);
	    		cropMatrixPreProcess(tmpPxToCrop);
	    	else
	    		% [thisMovie] = cropMatrix(thisMovie,'pxToCrop',options.pxToCrop);
	    		cropMatrixPreProcess(options.pxToCrop);
	    	end
	    end
    	% % convert to single (32-bit floating point)
    	% % thisMovie = single(thisMovie);
    	% saveStr = [saveStr '_crop'];
    end
    function cropMatrixPreProcess(pxToCropPreprocess)
    	if size(thisMovie,2)>=size(thisMovie,1)
			coords(1) = pxToCropPreprocess; %xmin
			coords(2) = pxToCropPreprocess; %ymin
			coords(3) = size(thisMovie,1)-pxToCropPreprocess;   %xmax
			coords(4) = size(thisMovie,2)-pxToCropPreprocess;   %ymax
		else
			coords(1) = pxToCropPreprocess; %xmin
			coords(2) = pxToCropPreprocess; %ymin
			coords(4) = size(thisMovie,1)-pxToCropPreprocess;   %xmax
			coords(3) = size(thisMovie,2)-pxToCropPreprocess;   %ymax
		end
    	rowLen = size(thisMovie,1);
		colLen = size(thisMovie,2);
		% a,b are left/right column values
		a = coords(1);
		b = coords(3);
		% c,d are top/bottom row values
		c = coords(2);
		d = coords(4);
		% set those parts of the movie to NaNs
		thisMovie(1:rowLen,1:a,:) = NaN;
		thisMovie(1:rowLen,b:colLen,:) = NaN;
		thisMovie(1:c,1:colLen,:) = NaN;
		thisMovie(d:rowLen,1:colLen,:) = NaN;
	end

    function fftHighpassInputMovie()
    	% do a highpass filter
    	ioptions.normalizationType = 'fft';
    	ioptions.freqLow = 7;
    	ioptions.freqHigh = 500;
    	ioptions.bandpassType = 'highpass';
    	ioptions.showImages = 0;
    	ioptions.bandpassMask = 'gaussian';
    	[thisMovie] = normalizeMovie(thisMovie,'options',ioptions);
    	if exist('tmpPxToCrop','var')
    		if tmpPxToCrop<options.pxToCrop
    			[thisMovie] = cropMatrix(thisMovie,'pxToCrop',tmpPxToCrop);
    		else
    			[thisMovie] = cropMatrix(thisMovie,'pxToCrop',options.pxToCrop);
    		end
    	end
    	% remove negative numbers
    	[thisMovie] = normalizeVector(thisMovie,'normRange','zeroToOne');
    	clear ioptions;
    end
    function fftLowpassInputMovie()
    	% do a lowpass filter
    	ioptions.normalizationType = 'fft';
    	ioptions.freqLow = 1;
    	ioptions.freqHigh = 7;
    	ioptions.bandpassType = 'lowpass';
    	ioptions.showImages = 0;
    	ioptions.bandpassMask = 'gaussian';
    	% save lowpass as separate
    	[thisMovieLowpass] = normalizeMovie(thisMovie,'options',ioptions);
    	clear ioptions;
    	if exist('tmpPxToCrop','var')
    		if tmpPxToCrop<options.pxToCrop
    			[thisMovieLowpass] = cropMatrix(thisMovieLowpass,'pxToCrop',tmpPxToCrop);
    		else
    			[thisMovieLowpass] = cropMatrix(thisMovieLowpass,'pxToCrop',options.pxToCrop);
    		end
    	end
    	% save lowpass as separate
    	if sum(optionIdx==saveIdx)
    		savePathStr = [thisDirSaveStr saveStr '.h5'];
    		movieSaved = writeHDF5Data(thisMovieLowpass,savePathStr)
    	end
    	% prevent lowpass file saving overwrite
    	optionIdx = -1;
    	clear thisMovieLowpass;
    end
end

function [turboRegCoords] = turboregCropSelection(options,folderList)
	% biafra ahanonu
	% 2013.11.10 [19:28:53]
	usrIdxChoiceStr = {'NO | do not duplicate coords across multiple folders','YES | duplicate coords across multiple folders','YES | duplicate coords if subject the same'};
	scnsize = get(0,'ScreenSize');
	[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','use coordinates over multiple folders?');
	usrIdxChoiceList = {-1,0,-2};
	applyPreviousTurboreg = usrIdxChoiceList{sel};

	folderListMinusComments = find(cellfun(@(x) isempty(x),strfind(folderList,'#')));
	nFilesToRun = length(folderListMinusComments);
	nFiles = length(folderList);
	class(folderListMinusComments)

	coordsStructure.test = [];
	for fileNumIdx = 1:nFilesToRun
		fileNum = folderListMinusComments(fileNumIdx);

		movieList = regexp(folderList{fileNum},',','split');
		movieList = movieList{1};
		movieList = getFileList(movieList, options.fileFilterRegexp);
		if options.processMoviesSeparately==1
			nMovies = length(movieList);
		else
			nMovies = 1;
		end
		for movieNo = 1:nMovies
			switch options.turboregType
				case 'preselect'
					if strfind(folderList{fileNum},'#')==1
					    % display('skipping...')
					    continue;
					end
					% opens frame n in each movie and asks the user to pre-select a region
					% thisDir = folderList{fileNum};
					dirInfo = regexp(folderList{fileNum},',','split');
					thisDir = dirInfo{1};
					display([num2str(fileNumIdx) '/' num2str(nFilesToRun) ': ' thisDir])
					options.fileFilterRegexp
					movieList = getFileList(thisDir, options.fileFilterRegexp);
					movieList
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
					suptitle([num2str(fileNumIdx) '\' num2str(nFilesToRun) ': ' strrep(thisDir,'\','/')]);
					set(0,'DefaultTextInterpreter','latex');

					% Use ginput to select corner points of a rectangular
					% region by pointing and clicking the subject twice
					fileInfo = getFileInfo(thisDir);
					switch applyPreviousTurboreg
						case -1 %'NO | do not duplicate coords across multiple folders'
							p = round(getrect);
						case 0 %'YES | duplicate coords across multiple folders'
							p = round(getrect);
							coordsStructure.(fileInfo.subject) = p;
						case -2 %'YES | duplicate coords if subject the same'
							if ~any(strcmp(fileInfo.subject,fieldnames(coordsStructure)))
								p = round(getrect);
								coordsStructure.(fileInfo.subject) = p;
							else
								p = coordsStructure.(fileInfo.subject);
							end
						otherwise
							% body
					end

					% Get the x and y corner coordinates as integers
					turboRegCoords{fileNum}{movieNo}(1) = p(1); %xmin
					turboRegCoords{fileNum}{movieNo}(2) = p(2); %ymin
					turboRegCoords{fileNum}{movieNo}(3) = p(1)+p(3); %xmax
					turboRegCoords{fileNum}{movieNo}(4) = p(2)+p(4); %ymax
					% turboRegCoords{fileNum}(1) = min(floor(p(1)), floor(p(2))); %xmin
					% turboRegCoords{fileNum}(2) = min(floor(p(3)), floor(p(4))); %ymin
					% turboRegCoords{fileNum}(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
					% turboRegCoords{fileNum}(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

					% Index into the original image to create the new image
					pts = turboRegCoords{fileNum}{movieNo};
					thisFrameCropped = thisFrame(pts(2):pts(4), pts(1):pts(3));
					% for poly region
					% sp=uint16(turboRegCoords{fileNum});
					% thisFrameCropped = thisFrame.*sp;

					% Display the subsetted image with appropriate axis ratio
					[figHandle figNo] = openFigure(9, '');
					subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;

					if applyPreviousTurboreg==0
						answer = inputdlg({'enter number of next folders to re-use coordinates on, click cancel if none'},'',1)
						if isempty(answer)
							applyPreviousTurboreg = 0;
						else
							applyPreviousTurboreg = str2num(answer{1});
						end
					elseif applyPreviousTurboreg>0
						applyPreviousTurboreg = applyPreviousTurboreg - 1;
						pause(0.15)
					end
					if any(strcmp(fileInfo.subject,fieldnames(coordsStructure)))
						pause(0.15)
						coordsStructure
					end
				case 'coordinates'
					% gets the coordinates of the turboreg from the filelist
					display('not implemented')
				otherwise
					% if no option selected, uses the entire FOV for each image
					display('not implemented')
					turboRegCoords{fileNum}{movieNo}=[];
			end
		end
	end
end
function [ostruct options] = getPcaIcaParams(ostruct,options)
	nFiles = length(ostruct.dfofFilePath);
	% inputdlg({'press OK to view a snippet of analyzed movies'},'...',1);
	uiwait(msgbox('press OK to view a snippet of analyzed movies','Success','modal'));
	% ask user for estimate of nPCs and nICs
	Miji;
	for fileNum=1:nFiles
		try
			display('+++++++')
			if isempty(ostruct.dfofFilePath{fileNum})
				display('no movie!')
				% display([num2str(fileNum) '/' num2str(nFiles) ' skipping: ' ostruct.dfofFilePath{fileNum}]);
				continue;
			else
				pathInfo = [num2str(fileNum) '/' num2str(nFiles) ': ' ostruct.dfofFilePath{fileNum}];
				display(pathInfo);
			end

			% get the list of movies
			movieList = {ostruct.dfofFilePath{fileNum}};

			options.frameList = [1:ostruct.movieFrames{fileNum}];

			% get the movie
			thisMovie = loadMovieList(movieList,'convertToDouble',0,'frameList',options.frameList);

			% playMovie(thisMovie,'fps',120,'extraTitleText',[10 pathInfo]);
			MIJ.createImage('result',thisMovie, true);
			uiwait(msgbox('press OK to move onto next movie','Success','modal'));
			MIJ.run('Close All Without Saving');

			if options.askForPCICs==1
				% add arbitrary nPCs and nICs to the output
				answer = inputdlg({'nPCs','nICs'},'cell extraction estimates',1)
				if isempty(answer)
					ostruct.nPCs{fileNum} = [];
					ostruct.nICs{fileNum} = [];
				else
					ostruct.nPCs{fileNum} = str2num(answer{1});
					ostruct.nICs{fileNum} = str2num(answer{2});
				end
			else
				ostruct.nPCs{fileNum} = [];
				ostruct.nICs{fileNum} = [];
			end
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	MIJ.exit;
end
function [turboregSettingStruct] = getTurboregSettings()

	turboregSettingDefaults = struct(...
	    'turboregRotation',  {{1,0}},...
	    'RegisType', {{1,3}},...
	    'parallel', {{1,0}},...
	    'numTurboregIterations',{{1,2,3,4,5}},...
	    'turboregNumFramesSubset',{{500,1000,2000,3000,5000,10000,15000}},...
	    'meanSubtract', {{1,0}},...
	    'normalizeType', {{'divideByLowpass','imagejFFT','highpass'}},...
	    'registrationFxn', {{'transfturboreg','imtransform'}},...
	    'normalizeBeforeRegister', {{[],'imagejFFT','bandpass','divideByLowpass'}},...
	    'saveNormalizeBeforeRegister', {{[],'save'}},...
	    'imagejFFTLarge',{{10000,100,500,1000,5000,8000}},...
	    'imagejFFTSmall',{{80,10,20,30,40,50,60,70,90,100}},...
	    'downsampleFactorTime',{{4,2,4,6,8,10,20}},...
	    'datasetName',{{'/1','/Movie','/movie'}},...
	    'fileFilterRegexp',{{'concat_.*.h5','concatenated_.*.h5','crop.*.h5'}},...
	    'processMoviesSeparately',{{0,1}},...
	    'loadMoviesFrameByFrame',{{0,1}}...
	);
	turboregSettingStr = struct(...
	    'turboregRotation', {{'DO turboreg rotation','DO NOT turboreg rotation'}},...
	    'RegisType', {{'affine','projective'}},...
	    'parallel', {{'parallel processing','NO parallel processing'}},...
	    'numTurboregIterations',{{'1','2','3','4','5'}},...
	    'turboregNumFramesSubset',{{'500','1000','2000','3000','5000','10000','15000'}},...
	    'meanSubtract', {{'normalize movie before turboreg','do not normalize movie before turboreg'}},...
	    'normalizeType', {{'divideByLowpass','imagejFFT','highpass'}},...
	    'registrationFxn', {{'transfturboreg','imtransform'}},...
	    'normalizeBeforeRegister', {{'NO normalizing before registering','imageJ divide by lowpass (requires Miji!)','matlab bandpass before registering','matlab divide by lowpass before registering'}},...
	    'saveNormalizeBeforeRegister', {{'NO not save lowpass','DO save lowpass'}},...
	    'imagejFFTLarge',{{'10000','100','500','1000','5000','8000'}},...
	    'imagejFFTSmall',{{'80','10','20','30','40','50','60','70','90','100'}},...
	    'downsampleFactorTime',{{'4','2','4','6','8','10','20'}},...
	    'datasetName',{{'/1','/Movie','/movie'}},...
	    'fileFilterRegexp',{{'concat_.*.h5','concatenated_.*.h5','crop.*.h5'}},...
	    'processMoviesSeparately',{{'no','yes'}},...
	    'loadMoviesFrameByFrame',{{'no','yes'}}...
	);

	% propertySettings = turboregSettingDefaults;

	propertyList = fieldnames(turboregSettingDefaults);
	nPropertiesToChange = size(propertyList,1);

	% add current property to the top of the list
	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		propertyOptions = turboregSettingStr.(property);
		propertySettingsStr.(property) = propertyOptions;
		% propertySettingsStr.(property);
	end

	uiListHandles = {};
	uiTextHandles = {};
	uiXIncrement = 0.05;
	uiYOffset = 0.95;
	uiTxtSize = 0.3;
	uiBoxSize = 0.4;
	[figHandle figNo] = openFigure(1337, '');
	clf
	uicontrol('Style','Text','String','processing options','Units','normalized','Position',[0.0 uiYOffset-uiXIncrement*(nPropertiesToChange+1) 0.3 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		uiTextHandles{propertyNo} = uicontrol('Style','Text','String',[property ': '],'Units','normalized','Position',[0.0 uiYOffset-uiXIncrement*propertyNo uiTxtSize 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
		uiListHandles{propertyNo} = uicontrol('Style', 'popup','String', propertySettingsStr.(property),'Units','normalized','Position', [uiTxtSize uiYOffset-uiXIncrement*propertyNo uiBoxSize 0.05]);
	end
	uicontrol('Style','Text','String','press enter to continue','Units','normalized','Position',[0.0 uiYOffset-uiXIncrement*(nPropertiesToChange+1) 0.3 0.05],'BackgroundColor','white','HorizontalAlignment','Left');
	pause

	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		uiListHandleData = get(uiListHandles{propertyNo});
		turboregSettingStruct.(property) = turboregSettingDefaults.(property){uiListHandleData.Value};
	end
	close(1337)
end