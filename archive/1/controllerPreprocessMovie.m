function [outputStruct] = controllerPreprocessMovie(folderListPath,varargin)
	% biafra ahanonu
	% started 2013.11.09 [10:46:23]
	% controller for pre-processing.
	% changelog
		% 2013.11.10 - refactored to make the work-flow more obvious and more easily modifiable by others. Now outputs a structure that contains information about what occured during the run.
		% 2013.11.11 - allowed increased flexibility in terms of inputting PCs/ICs and loading default options.
		% 2013.11.18  - s
	% TODO
		% Allow easy switching between analyzing all files in a folder together and each file in a folder individually

	% remove pre-compiled functions
	clear FUNCTIONS;
	% add controller directory and subdirectories to path
	addpath(genpath(pwd));
	% set default figure properties
	setFigureDefaults();
	%========================
	% set the options, these can be modified by varargin
	% should the movies be processed or just an outputStruct be created?
	options.processMovies=1;
	% set this to an m-file with default options
	options.loadOptionsFromFile = 0;
	% should the movie be saved?
	options.saveMovies = 0;
	% save the final movie
	options.saveDfofMovie = 1;
	% how to turboreg, options: 'preselect','coordinates','other'. Only pre-select is implemented currently.
	options.turboregType = 'preselect';
	% should the movie be turboreg'd
	options.turboregMovie = 1;
	% normalize the movie (e.g. divisive normalization)
	options.normalizeMovie = 1;
	% should the movie be dfof'd?
	options.dfofMovie = 1;
	% should the movie be downsampled?
	options.downsampleMovie = 1;
	options.downsampleFactor = 4;
	% the regular expression used to find files
	options.fileFilterRegexp = 'concatenated_.*.h5';
	% decide whether to get nICs and nPCs from file list
	options.inputPCAICA = 0;
	% number of frames from input movie to analyze
	options.frameList = [];
	% name for dataset in HDF5 file
	options.datasetName = '1';
	% get options
	options = getOptions(options,varargin);
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	% read in the list of folders
	fid = fopen(folderListPath, 'r');
	tmpData = textscan(fid,'%s','Delimiter','\n');
	folderList = tmpData{1,1};
	fclose(fid);
	nFiles = length(folderList);
	%========================
	% allow the user to pre-select all the targets
	if options.processMovies==1
		[turboRegCoords] = turboregCropSelection(options,folderList);
	end
	outputStruct.folderList = {}
	%========================
	folderList
	startTime = tic;
	for fileNum=1:nFiles
		display('+++++++')
		if options.processMovies==1
			% decide whether to get PCA-ICA parameters from file
			if options.inputPCAICA==1
				thisDir = folderList{fileNum};
				% should be folderDir,nPCs,nICs
				dirInfo = regexp(thisDir,',','split');
				thisDir = dirInfo{1};
				if(length(dirInfo)>=3)
					outputStruct.nPCs{fileNum} = str2num(dirInfo{3});
					outputStruct.nICs{fileNum} = str2num(dirInfo{2});
				else
					display('please add nICs and PCs')
				    outputStruct.nPCs{fileNum} = 700;
				    outputStruct.nICs{fileNum} = 500;
				end
			else
				thisDir = folderList{fileNum};
			end
			display([num2str(fileNum) '/' num2str(length(folderList)) ': ' thisDir]);
			% check if this directory has been commented out, if so, skip
			if strfind(thisDir,'#')==1
			    display('skipping...')
			    continue;
			end

			% get the list of movies
			movieList = getFileList(thisDir, options.fileFilterRegexp);
			% get information from directory
			fileInfo = getFileInfo(movieList{1});
			fileInfo
			% base string to save as
			fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.mouse '_' fileInfo.assay];
			thisDirSaveStr = [thisDir filesep fileInfoSaveStr];
			saveStr = '';
			% add the folder to the output structure
			outputStruct.folderList{fileNum} = thisDir;

			% get the movie
			[thisMovie outputStruct options] = getCurrentMovie(movieList,options,outputStruct);

			% turboreg!
			[thisMovie saveStr savePathStr] = getMovieTurboreg(thisMovie,turboRegCoords{fileNum},thisDirSaveStr,saveStr,options);

			% normalize (i don't use this at the moment)
			[thisMovie saveStr savePathStr] = getMovieNormalize(thisMovie,thisDirSaveStr,saveStr,options);

			% dF/F!
			[thisMovie saveStr savePathStr] = getMovieDfof(thisMovie,thisDirSaveStr,saveStr,options);

			% get downsampled (on it)
			[thisMovie saveStr savePathStr] = getMovieDownsample(thisMovie,thisDirSaveStr,saveStr,options);

			% save the location of the downsampled dfof for PCA-ICA identification
			outputStruct.dfofFilePath{fileNum} = savePathStr;

			% save file filter regexp based on saveStr
			outputStruct.fileFilterRegexp{fileNum} = saveStr;

			toc(startTime)
		else
			thisDir = folderList{fileNum};
			% get the list of movies
			movieList = getFileList(thisDir, options.fileFilterRegexp);
			% save the location of the downsampled dfof for PCA-ICA identification
			outputStruct.dfofFilePath{fileNum} = movieList{1};
			% add info to outputStruct
			outputStruct.fileFilterRegexp{fileNum} = 'concatenated_.*.h5';
			outputStruct.folderList{fileNum} = thisDir;
		end
	end

	% ask the user for PCA-ICA parameters if not input in the files
	if options.inputPCAICA==0
		[outputStruct options] = getPcaIcaParams(outputStruct,options)
	end

	toc(startTime)
function [thisMovie outputStruct options] = getCurrentMovie(movieList,options,outputStruct)
	% get the list of movies to load

	[pathstr,name,ext] = fileparts(movieList{1})
	if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
		options.movieType = 'hdf5';
		% use the faster way to read in image data, especially if only need a subset
		if isempty(options.frameList)
			thisMovie = loadMovieList(movieList,'movieType',options.movieType);
		else
			inputFilePath = movieList{1};
			hinfo = hdf5info(inputFilePath);
			hReadInfo = hinfo.GroupHierarchy.Datasets(1);
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
function [thisMovie saveStr savePathStr] = getMovieTurboreg(thisMovie,turboRegCoords,thisDirSaveStr,saveStr,options)
	% turboreg movie
	savePathStr = '';
	if options.turboregMovie==1
		display('registering movie...')
	    thisMovie = turboregMovie(thisMovie,'parallel',1,'cropCoords',turboRegCoords);
    	saveStr = ['_turboreg'];
	    if options.saveMovies==1
	    	savePathStr = [thisDirSaveStr saveStr '.h5'];
	    	writeHDF5Data(thisMovie,savePathStr)
	    end
	else
	    % movie20hzTurboreg = movie20hz;
	end

function [thisMovie saveStr savePathStr] = getMovieNormalize(thisMovie,thisDirSaveStr,saveStr,options)
	% normalize movie
	savePathStr = '';
	if options.normalizeMovie==1
		display('normalizing movie...')
	    thisMovie = normalizeMovie(thisMovie);
		saveStr = [saveStr '_normalized'];
		if options.saveMovies==1
			savePathStr = [thisDirSaveStr saveStr '.h5'];
			writeHDF5Data(thisMovie,savePathStr)
		end
	else
	    % movie20hzNorm = movie20hzTurboreg;
	end

function [thisMovie saveStr savePathStr] = getMovieDfof(thisMovie,thisDirSaveStr,saveStr,options)
	% dfof movie
	savePathStr = '';
	if options.dfofMovie==1
		display('dfof-ing movie...')
		thisMovie = dfofMovie(thisMovie);
		saveStr = [saveStr '_dfof'];
		if options.saveMovies==1
			savePathStr = [thisDirSaveStr saveStr '.h5'];
			writeHDF5Data(thisMovie,savePathStr)
		end
	else
		% dfofMovie20hz = movie20hzNorm;
	end

function [thisMovie saveStr savePathStr] = getMovieDownsample(thisMovie,thisDirSaveStr,saveStr,options)
	% downsample movie in time
	savePathStr = '';
	if options.downsampleMovie==1
		thisMovie = downsampleMovie(thisMovie,'downsampleFactor',options.downsampleFactor);
		saveStr = [saveStr '_5hz'];
		if options.saveMovies==1|options.saveDfofMovie==1
			savePathStr = [thisDirSaveStr saveStr '.h5'];
			writeHDF5Data(thisMovie,savePathStr)
		end
	else

	end

function [turboRegCoords] = turboregCropSelection(options,folderList)
	% biafra ahanonu
	% 2013.11.10 [19:28:53]
	nFiles = length(folderList);
	for fileNum=1:nFiles
		switch options.turboregType
			case 'preselect'

				if strfind(folderList{fileNum},'#')==1
				    display('skipping...')
				    continue;
				end
				% opens frame n in each movie and asks the user to pre-select a region
				thisDir = folderList{fileNum};
				movieList = getFileList(thisDir, options.fileFilterRegexp);
				inputFilePath = movieList{1};

				% inputFilePath = 'A:\shared\test2\concatenated_2013_10_05_p111_m728_vonfrey1.h5'
				hinfo = hdf5info(inputFilePath);
				hReadInfo = hinfo.GroupHierarchy.Datasets(1);
				xDim = hReadInfo.Dims(1);
				yDim = hReadInfo.Dims(2);
				% select the first frame from the dataset
				thisFrame = readHDF5Subset(inputFilePath,[0 0 0],[xDim yDim 1],'datasetName',options.datasetName);

				figure(9);subplot(2,1,1);imagesc(thisFrame); axis image; colormap gray; title('select region')

				% Use ginput to select corner points of a rectangular
				% region by pointing and clicking the mouse twice
				p = ginput(2)

				% Get the x and y corner coordinates as integers
				turboRegCoords{fileNum}(1) = min(floor(p(1)), floor(p(2))); %xmin
				turboRegCoords{fileNum}(2) = min(floor(p(3)), floor(p(4))); %ymin
				turboRegCoords{fileNum}(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
				turboRegCoords{fileNum}(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

				% Index into the original image to create the new image
				sp = turboRegCoords{fileNum};
				thisFrameCropped = thisFrame(sp(2):sp(4), sp(1): sp(3));

				% Display the subsetted image with appropriate axis ratio
				figure(9);subplot(2,1,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;
			case 'coordinates'
				% gets the coordinates of the turboreg from the filelist
				display('not implemented')
			otherwise
				% if no option selected, uses the entire FOV for each image
				display('not implemented')
				turboRegCoords{fileNum}=[];
		end
	end
function [outputStruct options] = getPcaIcaParams(outputStruct,options)
	nFiles = length(outputStruct.dfofFilePath);
	% ask user for estimate of nPCs and nICs
	for fileNum=1:nFiles
		display('+++++++')
		display([num2str(fileNum) '/' num2str(nFiles) ': ' outputStruct.dfofFilePath{fileNum}]);

		% get the list of movies
		movieList = {outputStruct.dfofFilePath{fileNum}};

		options.frameList = [1:500];

		% get the movie
		[thisMovie outputStruct options] = getCurrentMovie(movieList,options,outputStruct);

		figure(564);playMovie(thisMovie,'fps',60);

		% add arbitrary nPCs and nICs to the output
		answer = inputdlg({'nPCs','nICs'},'cell extraction estimates',1)
		outputStruct.nPCs{fileNum} = str2num(answer{1});
		outputStruct.nICs{fileNum} = str2num(answer{2});
	end