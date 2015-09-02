% downsample movies
controllerAnalysis('folderListInfo','private\analyze\small_grin.txt','downsampleSaveFolder','B:\data\pav\p104\small_grin\');
controllerAnalysis('folderListInfo','A:\data\pav\p104\Small_GRIN_PAV','downsampleSaveFolder','B:\data\pav\p104\small_grin\');
controllerAnalysis('folderListInfo','A:\data\processing');

% move structures
moveFilesToFolders('A:\data\pav\p104\Small_GRIN_PAV\','B:\data\pav\p104\small_grin','srcFolderFilterRegexp','14')
moveFilesToFolders('E:\','A:\data\pav\p104\Small_GRIN_PAV\','srcFolderFilterRegexp','14')
moveFilesToFolders('E:\','B:\data\pav\p104\small_grin','srcFolderFilterRegexp','14')
moveFilesToFolders('E:\','A:\data\processing','srcFolderFilterRegexp','14')
% =====================
% PREPROCESSING
% pre-process files
ioptions.folderListInfo = 'private\analyze\p104_small_grin.txt';
ioptions.runArg = 'preprocessInscopix';
ostruct = controllerAnalysis('options',ioptions);
% look at dfofs
ioptions.folderListInfo = 'private\analyze\p104_small_grin.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'playShortClip';
ostruct = controllerAnalysis('options',ioptions);
% verify movies don't have problematic frames, saves images of each folder to /private/pics/movieStatistics
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'getMovieStatistics';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% crop/view turboreg
controllerAnalysis('folderListInfo','private\analyze\small_grin.txt','fileFilterRegexp','cropped');

% pcaica
ioptions.pcaicaList.('F887') = [500 300];
ioptions.pcaicaList.('M885') = [375 250];
ioptions.pcaicaList.('M886') = [500 300];
ioptions.pcaicaList.('F139') = [300 200];
ioptions.pcaicaList.('M884') = [375 250];
ioptions.pcaicaList.('M894') = [300 150];
ioptions.folderListInfo = 'private\analyze\p104_small_grin.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'pcaicaInscopix';
ostruct = controllerAnalysis('options',ioptions);

pcaicaList.('M894') = [300 150];
controllerAnalysis('folderListInfo','private\analyze\small_grin_check.txt','fileFilterRegexp','cropped','pcaicaList',pcaicaList);
% =====================
% sort ICs
ioptions.folderListInfo = 'private\analyze\p104_small_grin.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'icaChooser';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% PAV analysis
ostruct.tables.subjectTable = readtable(subjectTablePath,'Delimiter','comma','FileType','text');
subjectTablePath = 'C:\Users\Jones Parker\Dropbox\Biafra-Jones\analysis\pav\2014_05_04\rawLickData.csv';
ioptions.runArg = 'stimTriggeredAverage';
ioptions.stimNameArray = {'lick', 'CS', 'US'};
ioptions.stimIdNumArray = [24 30 31];
ioptions.subjectTablePath = subjectTablePath;
ioptions.picsSavePath = 'private\pics\p104\';
ioptions.skipSubjData = 1;
ioptions.delimiter = 'comma';
tmpStruct = controllerAnalysis('folderListInfo','private\analyze\small_grin.txt','options',ioptions);
% =====================
% CELLMAPS
ioptions.folderListInfo = 'private\analyze\p104_small_grin.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.picsSavePath = 'private\pics\p104_small_grin\';
ioptions.runArg = 'objectMaps';
ostruct = controllerAnalysis('options',ioptions);










% PAV analysis
ostruct.tables.subjectTable = readtable(subjectTablePath,'Delimiter','comma','FileType','text');

subjectTablePath = 'B:\shared_kup\MEDFILES\tmpanalysis\2014_05_09\rawLickData.csv';
ioptions.runArg = 'stimTriggeredAverage';
ioptions.stimNameArray = {'lick', 'CS', 'US'};
ioptions.stimIdNumArray = [24 30 31];
ioptions.subjectTablePath = subjectTablePath;
ioptions.picsSavePath = 'private\pics\p104\';
ioptions.skipSubjData = 1;
ioptions.delimiter = ',';
tmpStruct = controllerAnalysis('folderListInfo','A:\data\pav\p104\SST-Mice\140509-M894-MAG1\','options',ioptions);