% biafra ahanonu
% started 2014.07.31

clear classes;
clear; clc;

% ============================
% If have raw HDF5 files, just do the following and follow down the list of functions to run
obj = behaviorAnalysis();
obj.runPipeline();
% ============================
% PREPROCESSING
% If you have downsampled HDF5 files
% path to txt files containing folders
options.rawSignals = 'private/analyze/objTest.txt';
% where to save pictures
options.picsSavePath = ['private\pics\objTest\'];
% load image/traces into ram? recommended not
options.loadVarsToRam = 0;
% where are behavioral videos located?
options.videoDir = 'Z:\data\vids\objTest\';
% where to save side-by-sides
options.videoSaveDir = 'A:\biafra\data\miniscope\side_by_side\objTest\';
% dataset name for downsampled HDF5 files
options.hdf5Datasetname = '/1';
% pca-ica
options.numExpectedSignals.('m163') = [400 300];
options.numExpectedSignals.('m165') = [800 600];
options.numExpectedSignals.('m166') = [500 350];
options.numExpectedSignals.('m167') = [700 550];
options.numExpectedSignals.('m170') = [800 600];
options.numExpectedSignals.('m10212') = [600 450];
options.numExpectedSignals.('m3484') = [450 250];
options.numExpectedSignals.('m7211') = [800 600];
options.numExpectedSignals.('m9094') = [700 500];
options.numExpectedSignals.('m1234') = [800 600];
options.numExpectedSignals.('m5678') = [700 500];
% create the object
obj = behaviorAnalysis('options',options)
% METHOD 1 - just follow functions in the pop-up
	obj.runPipeline();
% METHOD 2
	%
	obj.modelPreprocessMovie();
	%
	obj.modelExtractSignalsFromMovie();
	%
	obj.viewCreateObjmaps();
	%
	obj.initializeObj();
	%
	obj.computeManualSortSignals();
	% ADDITIONAL
	% if need to remove a particular region from the analysis
	obj.modelModifyRegionAnalysis
	% add a new folder to the object
	obj.modelAddNewFolders();

% ============================
options.rawSignals = 'private/analyze/fileList.txt';
% REVERSAL
	options.picsSavePath = ['private\pics\reversal\'];
	% stimulus
		options.discreteStimulusTable = 'reversal\rawData.csv';
		%
		options.stimulusTableValueName = 'frameSessionDownsampled';
		options.stimulusTableFrameName = 'frameSessionDownsampled';
		options.stimulusTableTimeName = 'time';
		options.stimulusTableSessionName = 'trial';
		%
		options.stimulusNameArray = {'choice_right_press','choice_left_press','forced_right_press','forced_left_press','choice_lever_extend','forced_right_lever','forced_left_lever','lick__all','lick__onset','lick__offset','mag_lick__all','mag_lick__onset','mag_lick__offset'};
		options.stimulusIdArray = {63 64 67 68 62 65 66 [7,14,30,35,40,43] [7,14,30,35,40,43] [7,14,30,35,40,43] 24 24 24};
		options.stimulusTimeSeq = {[-10:0],[-10:0],[-10:0],[-10:0],[0:10],[0:10],[0:10],[-5:5],[0:10],[-10:0],[-5:5],[0:10],[-10:0],[-5:5]};
		options.stimTriggerOnset = {0,0,0,0,0,0,0,0,1,-1,0,1,-1};
	% behavior metrics
		options.discreteStimulusTable = 'reversal\summaryData.csv';
		options.stimulusNameArray = {'correct (%)','omissions_press'};
		options.stimulusIdArray = [17 12];
% PAV
	% stimulus
		options.discreteStimulusTable = 'pav\rawData.csv';
		options.stimulusTableValueName = 'frameSessionDownsampled';
		options.stimulusTableFrameName = 'frameSessionDownsampled';
		options.stimulusTableTimeName = 'time';
		options.stimulusTableSessionName = 'trial';
		options.stimulusNameArray = {'lick__all','lick__onset','lick__offset', 'CS', 'US'};
		options.stimulusIdArray = [24 24 24 30 31];
	options.picsSavePath = ['private\pics\pav\'];
	options.stimTriggerOnset = 0;
	options.loadVarsToRam = 0;
	options.videoDir = 'Z:\data\vids\p200\';

% OPEN FIELD
	% AFTER IMAGEJ
	removeIncorrectObjs(getFileList('A:\biafra\data\behavior\open_field\p200\tracking\take3','.csv'),'subjectInfoTable','D:\b\Dropbox\schnitzer\data\databases\database.mice.open_field.p200.csv');
	%
	options.rawSignals = 'private/analyze/fileList.txt';
	options.picsSavePath = ['private\pics\open_field\'];
	% stimulus
	options.continuousStimulusTable	 = getFileList('\tracking\','.csv');
	options.continuousStimulusNameArray = {'XM','YM','Angle','XM_cm','YM_cm'};
	options.continuousStimulusSaveNameArray = strrep(options.continuousStimulusNameArray,'_','__');
	options.continuousStimulusIdArray = [1 2 3 4 5 ];
	options.continuousStimulusTimeSeq = {[-5:5],[-5:5],[-5:5],[-5:5],[-5:5]};
	options.loadVarsToRam = 0;
	options.videoDir = 'Z:\data\vids\p230\';

% load object
obj = behaviorAnalysis('options',options)

% load object
options.dataPath = options.rawSignals;
obj = behaviorAnalysis('options',options)

% save the object
obj.saveObj();

% wrapper for all necessary pre-computation
obj.runDiscreteCompute()
% wrapper for graphing functions
obj.runDiscreteView()

% individual
obj.computeDiscreteAlignedSignal();
obj.computeSpatioTemporalClustMetric();
obj.computeMatchObjBtwnTrials();
obj.computeAcrossTrialSignalStimMetric();

%
obj.viewStimTrig();
obj.viewObjmapStimTrig();
obj.viewChartsPieStimTrig();
obj.viewObjmapSignificant();
obj.viewSpatioTemporalMetric();

%
obj.viewPlotSignificantPairwise();
obj.viewObjmapSignificantPairwise();
obj.viewObjmapSignificantAllStims();