function obj = modelDownsampleRawMovies(obj)
% downsamples inscopix files and moves them to appropriate folders.

	try
		downsampleSettings = inputdlg(...
			{...
				'Folder(s) where raw HDF5s are located. Use comma to separate multiple source folders:',...
				'Folder to save downsampled HDF5s to:',...
				'Decompression source root folder(s). Use comma to separate multiple source folders:',...
				'Downsample factor (in x-y):',...
				'Regexp for HDF5 files:',...
				'HDF5 hierarchy name where movie is stored:',...
				'Max chunk size (MB)',...
				'Regexp for folders:',...
				'Regexp for base filename (use txt log name):',...
				'Extension for base filename:',...
			},...
			'downsample settings',1,...
			{...
				'A:\data\processing\',...
				'B:\data\processing\',...
				'E:\',...
				'4',...
				'recording.*.hdf5',...
				'/images',...
				'25000',...
				'2015',...
				'recording.*.txt',...
				'.txt',...
			});
		folderListInfo = strsplit(downsampleSettings{1},',');
		nFolders = length(folderListInfo);
		for folderNo = 1:nFolders
			% downsample if all decompressed files are in the same folder
			ioptions.folderListInfo = [folderListInfo{folderNo} filesep];
			ioptions.downsampleSaveFolder = [downsampleSettings{2} filesep];
			ioptions.downsampleFactor = str2num(downsampleSettings{4});
			ioptions.fileFilterRegexp = downsampleSettings{5};
			ioptions.datasetName = downsampleSettings{6};
			ioptions.maxChunkSize = str2num(downsampleSettings{7});
			ioptions.runArg = 'downsampleMovie';
			ostruct = controllerAnalysis('options',ioptions);
		end

		% re-create folder structure
		clear ioptions
		%
		downsampleSaveFolder = [downsampleSettings{2} filesep];
		% used to determine which folders to copy from src to dest
		ioptions.srcFolderFilterRegexp = downsampleSettings{8};
		% this regexp is used to search the destination directory
		ioptions.srcSubfolderFileFilterRegexp = downsampleSettings{9};
		%
		ioptions.srcSubfolderFileFilterRegexpExt = downsampleSettings{10};
		[success destFolders] = moveFilesToFolders(strsplit(downsampleSettings{3},','),char(downsampleSaveFolder(:))','options',ioptions);

		% ============================
		% move files to their correct folders
		% moveSettings = inputdlg({...
		% 	'regexp for folders:',...
		% 	'regexp for base filename (use txt log name):',...
		% 	'extension for base filename:',...
		% 	'source root folder(s), use comma to separate multiple source folders:',...
		% 	'destination folder (where HDF5s were downsampled):'...
		% 	},...
		% 	'downsample settings',1,{...
		% 	'2014',...
		% 	'recording.*.txt',...
		% 	'.txt',...
		% 	'E:\',...
		% 	char(ioptions.downsampleSaveFolder(:))'});
		% re-create folder structure
		% used to determine which folders to copy from src to dest
		% ioptions.srcFolderFilterRegexp = moveSettings{1};
		% % this regexp is used to search the destination directory
		% ioptions.srcSubfolderFileFilterRegexp = moveSettings{2};
		% %
		% ioptions.srcSubfolderFileFilterRegexpExt = moveSettings{3};
		% [success destFolders] = moveFilesToFolders(strsplit(moveSettings{4},','),moveSettings{5},'options',ioptions);

		if isempty(obj.inputFolders)
			obj.inputFolders = destFolders;
			obj.dataPath = destFolders;
		else
			obj.inputFolders = cat(obj.inputFolders,destFolders);
			obj.dataPath = cat(obj.dataPath,destFolders);
		end
	catch err
		obj.foldersToAnalyze = [];
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end

function downsampleHDFMovieFxnObj(movieList,options)
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
end