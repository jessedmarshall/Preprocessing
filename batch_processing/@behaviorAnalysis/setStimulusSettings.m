function obj = setStimulusSettings(obj)
	% get centroid locations along with distance matrix
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

	% ask user if discrete or continuous stimuli

	% ask user for the number of stimuli to add

	% get a list of stimuli names, ID numbers, and relevant frames before/after stimulus to analyze.

	obj.stimulusTableValueName = 'frame';
	obj.stimulusTableFrameName = 'frame';
	obj.stimulusTableTimeName = 'time';
	obj.stimulusTableSessionName = 'trial';
	% DISCRETE
	obj.discreteStimulusTable = ['D:\b\Dropbox\schnitzer\analysis\medfiles\p215_reversal\miniscope\rawSubjData.csv'];
	obj.stimulusNameArray = {'choice_right_press','choice_left_press','forced_right_press','forced_left_press','choice_lever_extend','forced_right_lever','forced_left_lever','lick__all','lick__onset','lick__offset'};
	obj.stimulusIdArray = {63 64 67 68 62 65 66 [7,14,30,35,40,43] [7,14,30,35,40,43] [7,14,30,35,40,43]};
	obj.stimulusTimeSeq = {[-10:0],[-10:0],[-10:0],[-10:0],[0:10],[0:10],[0:10],[-5:5],[0:10],[-10:0]};
	obj.stimTriggerOnset = {0,0,0,0,0,0,0,0,1,-1};
	% CONTINUOUS
	% removeIncorrectObjs(getFileList('A:\biafra\data\behavior\p230\tracking\','.csv'),'subjectInfoTable','saveFile',1);
	% obj.continuousStimulusTable	 = getFileList('A:\biafra\data\behavior\p215\tracking\cleaned\','cleaned');
	% obj.continuousStimulusNameArray = {'XM','YM','Angle','XM_cm','YM_cm'};
	% obj.continuousStimulusSaveNameArray = strrep(obj.continuousStimulusNameArray,'_','__');
	% obj.continuousStimulusIdArray = [1 2 3 4 5];
	% obj.continuousStimulusTimeSeq = {[-5:5],[-5:5],[-5:5],[-5:5],[-5:5]};


	if ~isempty(obj.discreteStimulusTable)&~strcmp(class(obj.discreteStimulusTable),'table')
	    obj.modelReadTable('table','discreteStimulusTable');
	    obj.modelTableToStimArray('table','discreteStimulusTable','tableArray','discreteStimulusArray','nameArray','stimulusNameArray','idArray','stimulusIdArray','valueName',obj.stimulusTableValueName,'frameName',obj.stimulusTableFrameName);
	end
	if ~isempty(obj.continuousStimulusTable)&~strcmp(class(obj.continuousStimulusTable),'table')
	    obj.delimiter = ',';
	    obj.modelReadTable('table','continuousStimulusTable','addFileInfoToTable',1);
	    obj.delimiter = ',';
	    obj.modelTableToStimArray('table','continuousStimulusTable','tableArray','continuousStimulusArray','nameArray','continuousStimulusNameArray','idArray','continuousStimulusIdArray','valueName',obj.stimulusTableValueName,'frameName',obj.stimulusTableFrameName,'grabStimulusColumnFromTable',1);
	end
	% load behavior tables
	if ~isempty(obj.behaviorMetricTable)&~strcmp(class(obj.behaviorMetricTable),'table')
	    obj.modelReadTable('table','behaviorMetricTable');
	    obj.modelTableToStimArray('table','behaviorMetricTable','tableArray','behaviorMetricArray','nameArray','behaviorMetricNameArray','idArray','behaviorMetricIdArray','valueName','value');
	end
	% modify stimulus naming scheme
	if ~isempty(obj.stimulusNameArray)
	    obj.stimulusSaveNameArray = obj.stimulusNameArray;
	    obj.stimulusNameArray = strrep(obj.stimulusNameArray,'_',' ');
	end

end
%% functionname: function description
function [outputs] = functionname(arg)

	newFolderList = inputdlg('one new line per folder path','add folders',[10 100])
	newFolderList = newFolderList{1,1};
	newFolderList = cellfun(@(x) strtrim(x),cellstr(newFolderList),'UniformOutput',false);
	obj.inputFolders{obj.fileNum,1} = strtrim(newFolderList(thisFileNumIdx,:));
	% maybe

	% ask for path(s) to stimulus
	newFolderList = inputdlg('one new line per folder path','add folders',[10 100])
	newFolderList = newFolderList{1,1};
	newFolderList = cellfun(@(x) strtrim(x),cellstr(newFolderList),'UniformOutput',false);
	obj.inputFolders{obj.fileNum,1} = strtrim(newFolderList(thisFileNumIdx,:));


	downsampleSettings = inputdlg({...
		'folder where raw HDF5s are located:',...
		'folder to save downsampled HDF5s to:',...
		'regexp for HDF5 files:',...
		'HDF5 hierarchy name where movie is stored:',...
		'max chunk size (MB)'},...
		'downsample settings',1,{...
		'A:\data\processing\',...
		'B:\data\processing\',...
		'recording.*.hdf5',...
		'/images',...
		'25000'});
	% downsample if all decompressed files are in the same folder
	ioptions.folderListInfo = [downsampleSettings{1} filesep];
	ioptions.downsampleSaveFolder = [downsampleSettings{2} filesep];
	ioptions.fileFilterRegexp = downsampleSettings{3};
	ioptions.datasetName = downsampleSettings{4};
	ioptions.maxChunkSize = str2num(downsampleSettings{5});
	ioptions.runArg = 'downsampleMovie';


	options.rawSignals = 'private/analyze/p200_openfield.txt';
		options.picsSavePath = ['private\pics\p200\open_field\'];
		% stimulus
		options.continuousStimulusTable	 = getFileList('A:\biafra\data\behavior\open_field\p200\tracking\','.csv');
		options.continuousStimulusNameArray = {'XM','YM','Angle','XM_cm','YM_cm'};
		options.continuousStimulusSaveNameArray = strrep(options.continuousStimulusNameArray,'_','__');
		options.continuousStimulusIdArray = [1 2 3 4 5 ];
		options.continuousStimulusTimeSeq = {[-5:5],[-5:5],[-5:5],[-5:5],[-5:5]};

	options.rawSignals = 'private/analyze/p200_scored.txt';
	options.picsSavePath = ['private\pics\p200\grooming\'];
	% stimulus
	options.discreteStimulusTable = getFileList('D:\b\Dropbox\schnitzer\data\assays\groombox\p200\','.csv');
	options.stimulusNameArray = {'hindpaw scratch','forepaw groom onset','forepaw groom offset','body lick groom onset','body lick groom offset','forepaw swipe','hindpaw scratching onset','hindpaw scratching offset'};
	options.stimulusNameArray = strrep(options.stimulusNameArray,'_','__');
	options.stimulusIdArray = [10 1 2 3 4 5 7 8];
	options.stimulusTimeSeq = {[-5:5],[0:10],[0:10],[0:10],[-5:5],[-5:5],[-5:5],[-5:5],[-5:5],[0:10],[-5:5],[-5:5],[0:10]};
	options.stimTriggerOnset = {0,1,-1,0,0};
	options.loadVarsToRam = 0;
	options.videoDir = 'Z:\data\vids\p200\';
	% load object
	obj = behaviorAnalysis('options',options)
end