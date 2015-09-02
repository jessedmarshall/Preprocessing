function obj = modelAddNewFolders(obj)
% remove PCAs in a particular region or exclude from preprocessing, etc.

	try
		newFolderList = inputdlg('one new line per folder path','add folders',[10 100])
		newFolderList = newFolderList{1,1};
		size(newFolderList)
		class(newFolderList)

		% if obj.guiEnabled==1
		% 	scnsize = get(0,'ScreenSize');
		% 	[fileIdxArray, ok] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
		% else
		% 	fileIdxArray = 1:length(obj.fileIDNameArray);
		% end
		nExistingFolders = length(obj.inputFolders);
		nNewFolders = size(newFolderList,1);
		fileIdxArray = (nExistingFolders+1):(nExistingFolders+nNewFolders)
		% obj.foldersToAnalyze = fileIdxArray;
		nFolders = length(fileIdxArray)

		for thisFileNumIdx = 1:nFolders
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			obj.inputFolders{obj.fileNum,1} = strtrim(newFolderList(thisFileNumIdx,:));
			obj.dataPath{obj.fileNum,1} = strtrim(newFolderList(thisFileNumIdx,:));
			% display(repmat('=',1,21))
			% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.fileIDNameArray{obj.fileNum}]);
		end
		display('adding file info...')
		obj.modelGetFileInfo();
		display('getting model variables...')
		% obj.modelVarsFromFiles();

		% obj.runPipeline();

		obj.foldersToAnalyze = [];
	catch err
		obj.foldersToAnalyze = [];
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end