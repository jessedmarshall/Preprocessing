function obj = modelPreprocessMovie(obj)
% preprocess movies


	if obj.guiEnabled==1
		scnsize = get(0,'ScreenSize');
		[fileIdxArray, ok] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
	else
		if isempty(obj.foldersToAnalyze)
			fileIdxArray = 1:length(obj.fileIDNameArray);
		else
			fileIdxArray = obj.foldersToAnalyze;
		end
	end

	options.fileFilterRegexp = 'concat_.*.h5';
	folderListInfo = {obj.inputFolders{fileIdxArray}};
	options.datasetName = obj.inputDatasetName;

	controllerPreprocessMovie2('folderListPath',folderListInfo,'fileFilterRegexp',options.fileFilterRegexp,'datasetName',options.datasetName,'frameList',[]);