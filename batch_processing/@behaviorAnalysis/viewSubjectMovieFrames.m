function obj = viewSubjectMovieFrames(obj)
	% creates obj maps and plots of high-SNR example signals
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

	fileFilterRegexp = 'concat';
	display(repmat('#',1,21))
	display('computing signal peaks...')
	nFiles = length(obj.rawSignals);
	subjectList = unique(obj.subjectStr);

	Miji;
	for thisSubjectStr=subjectList
		validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
		% validManualIdx = find(arrayfun(@(x) isempty(x{1}),obj.validManual));
		% classifyFoldersIdx = intersect(validFoldersIdx,validManualIdx);
		movieList = getFileList({obj.inputFolders{validFoldersIdx}}, fileFilterRegexp);
		movieList
		subjectMovieFrames = loadMovieList(movieList,'convertToDouble',0,'frameList',1:2);
		% movieFrame = squeeze(movieFrame(:,:,1));
		subjectMovieFrames = subjectMovieFrames(:,:,1:2:end);
		[subjectMovieFrames] = normalizeVector(single(subjectMovieFrames),'normRange','zeroToOne');
		[subjectMovieFrames] = normalizeMovie(subjectMovieFrames,'normalizationType','meanSubtraction');

		movieSavePathBase = strcat(obj.picsSavePath,filesep,'subjectMovieFrames_');
		if (~exist(movieSavePathBase,'dir')) mkdir(movieSavePathBase); end;
		movieSavePath = strcat(movieSavePathBase,filesep,thisSubjectStr{1},'.h5');
		[output] = writeHDF5Data(subjectMovieFrames,movieSavePath);
		movieSavePath = strcat(movieSavePathBase,filesep,thisSubjectStr{1},'.tiff');
		options.comp = 'no';
		movieSavePath
		saveastiff(subjectMovieFrames, movieSavePath, options);

		MIJ.createImage(thisSubjectStr{1}, subjectMovieFrames, true);
		% pause
	end
	display('press key on command window to continue...')
	pause
	for thisSubjectStr=subjectList
		MIJ.run('Close');
	end
	MIJ.exit;