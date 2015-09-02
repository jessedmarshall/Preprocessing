% biafra ahanonu
% started 2014.05.31

% =====================
% DOWMSAMPLING
% downsample if all decompressed files are in the same folder
ioptions.folderListInfo = 'A:\data\processing\';
ioptions.downsampleSaveFolder = 'B:\data\processing\';
ioptions.runArg = 'downsampleInscopix';
ostruct = controllerAnalysis('options',ioptions);
% ====
% re-create folder structure
% used to determine which folders to copy from src to dest
ioptions.srcFolderFilterRegexp = '2014';
% this regexp is used to search the destination directory
ioptions.srcSubfolderFileFilterRegexp = 'recording.*.txt';
%
ioptions.srcSubfolderFileFilterRegexpExt = '.txt';
output = moveFilesToFolders('E:\','A:\data\processing','options',ioptions);
% =====================
% OR if downsample if reading from a list
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.runArg = 'downsampleInscopix';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% FOLDER LIST
% make a txt file containing paths to relevant files
% =====================
% PREPROCESSING
% pre-process files
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.runArg = 'preprocessInscopix';
ostruct = controllerAnalysis('options',ioptions);
% look at dfofs
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'playShortClip';
ostruct = controllerAnalysis('options',ioptions);
% verify movies don't have problematic frames, saves images of each folder to /private/pics/movieStatistics
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'getMovieStatistics';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% PCAICA
% list of [PCs ICs] for each subject
% the subject number should be somewhere in the path with a suffix of m### or f###, e.g. m892 or f291
ioptions.pcaicaList.('m81') = [500 300];
ioptions.pcaicaList.('m82') = [500 300];
ioptions.pcaicaList.('m84') = [500 300];
ioptions.pcaicaList.('m88') = [500 300];

ioptions.pcaicaList.('m19') = [600 400];
ioptions.pcaicaList.('m80') = [450 350];
ioptions.pcaicaList.('m83') = [400 250];
ioptions.pcaicaList.('m86') = [600 400];

ioptions.pcaicaList.('F043') = [800 650];
ioptions.pcaicaList.('m121') = [700 500];
ioptions.pcaicaList.('m120') = [700 500];
ioptions.pcaicaList.('m821') = [700 500];
ioptions.pcaicaList.('m822') = [600 400];
ioptions.pcaicaList.('m823') = [400 300];
ioptions.pcaicaList.('m824') = [400 300];

ioptions.pcaicaList.('m788') = [700 500];
ioptions.pcaicaList.('m787') = [700 500];
ioptions.pcaicaList.('m789') = [700 500];
ioptions.pcaicaList.('m790') = [700 500];
ioptions.pcaicaList.('m791') = [700 500];
ioptions.pcaicaList.('m792') = [700 500];

ioptions.pcaicaList.('m777') = [700 500];
ioptions.pcaicaList.('m778') = [700 500];
ioptions.pcaicaList.('f779') = [700 500];
ioptions.pcaicaList.('m780') = [700 500];

ioptions.pcaicaList.('m163') = [400 300];
ioptions.pcaicaList.('m165') = [800 600];
ioptions.pcaicaList.('m166') = [500 350];
ioptions.pcaicaList.('m167') = [700 550];
ioptions.pcaicaList.('m170') = [800 600];
ioptions.pcaicaList.('m10212') = [600 450];
ioptions.pcaicaList.('m3484') = [450 250];
ioptions.pcaicaList.('m7211') = [800 600];
ioptions.pcaicaList.('m9094') = [700 500];

ioptions.folderListInfo = 'private\analyze\processing.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'pcaicaInscopix';
ostruct = controllerAnalysis('options',ioptions);
% sort ICs
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'icaChooser';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% CELLMAPS
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.picsSavePath = 'private\pics\PROTOCOLNUMBER\';
ioptions.runArg = 'objectMaps';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% FIRING STATS
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.picsSavePath = 'private\pics\PROTOCOLNUMBER\';
ioptions.runArg = 'computePeaks';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% CREATE SIDE BY SIDE
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.videoDir = 'A:\data\vids\PROTOCOLNUMBER\';
ioptions.fileFilterRegexp = 'crop';
ioptions.sideBySideDir = 'A:\data\miniscope\side_by_side\PROTOCOLNUMBER\';
ioptions.runArg = 'createSideBySide';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% TRIAL TO TRIAL ALIGNMENT
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.picsSavePath = 'private\pics\PROTOCOLNUMBER\';
ioptions.runArg = 'matchObjAcrossTrials';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% CREATE STIM TRIGGERED MOVIE
ioptions.stimNameArray = {'lick__all','lick__onset','lick__offset', 'CS', 'US'};
ioptions.stimIdNumArray = [24 24 24 30 31];
%
ioptions.stimNameArray = {'choice_lever'};
ioptions.stimIdNumArray = [62];
%
ioptions.stimNameArray = {'right_lever_press','left_lever_press'};
ioptions.stimIdNumArray = [4 3];
%
ioptions.videoDir = 'Z:\data\vids\PROTOCOLNUMBER\';
ioptions.fileFilterRegexp = 'crop';
ioptions.subjectTablePath = 'rawData.csv';
ioptions.delimiter = ',';
ioptions.stimNameArray = strrep(ioptions.stimNameArray,'_','__');
ioptions.picsSavePath = ['private\pics\PROTOCOLNUMBER\'];
ioptions.sideBySideDir = 'A:\data\miniscope\side_by_side\PROTOCOLNUMBER\';
ioptions.skipSubjData = 1;
ioptions.stimTriggerOnset = 420;
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.runArg = 'stimTriggeredMovie';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% CREATE STIM TRIGGERED AVERAGE
ioptions.stimNameArray = {'choice_right_press','choice_left_press','forced_right_press','forced_left_press','choice_lever_extend','forced_right_lever','forced_left_lever'};
ioptions.stimIdNumArray = [63 64 67 68 62 65 66];
ioptions.stimNameArray = strrep(ioptions.stimNameArray,'_','__');
ioptions.subjectTablePath = 'rawData.csv';
ioptions.delimiter = ',';
ioptions.picsSavePath = ['private\pics\PROTOCOLNUMBER\'];
ioptions.skipSubjData = 1;
ioptions.stimTriggerOnset = 420;
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.runArg = 'stimTriggeredAverage';
ostruct = controllerAnalysis('options',ioptions);