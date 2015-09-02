function obj = modelGetFileInfo(obj)
	% get information for each folder
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
	obj.inputFolders = obj.dataPath;
	for i=1:length(obj.dataPath)
	    fileInfo = getFileInfo(obj.dataPath{i});
	    obj.subjectStr{i} = fileInfo.subject;
	    obj.subjectNum{i} = fileInfo.subjectNum;
	    obj.assay{i} = fileInfo.assay;
	    obj.protocol{i} = fileInfo.protocol;
	    obj.assayType{i} = fileInfo.assayType;
	    obj.assayNum{i} = fileInfo.assayNum;
	    obj.date{i} = fileInfo.date;
	    obj.fileIDArray{i} = strcat(obj.subjectStr{i},'_',obj.assay{i});
	    obj.fileIDNameArray{i} = char([obj.subjectStr{i},' ',obj.assay{i}]);
	    obj.folderBaseSaveStr{i} = strcat(fileInfo.date,'_',fileInfo.protocol,'_',fileInfo.subject,'_',fileInfo.assay);
	end