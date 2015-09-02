% =====================
% DOWMSAMPLING
% downsample if all decompressed files are in the same folder
ioptions.folderListInfo = 'A:\data\processing';
ioptions.runArg = 'downsampleInscopix';
ostruct = controllerAnalysis('options',ioptions);
% re-create folder structure
output = moveFilesToFolders('E:\','A:\data\processing');
% ---
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
ioptions.pcaicaList.('m81') = [700 550];
ioptions.pcaicaList.('m84') = [700 550];
ioptions.folderListInfo = 'private\analyze\fileList.txt';
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