% =====================
% DOWMSAMPLING
% downsample if all decompressed files are in the same folder
ioptions.folderListInfo = 'A:\data\processing';
ioptions.runArg = 'downsampleInscopix';
ostruct = controllerAnalysis('options',ioptions);
% re-create folder structure
output = moveFilesToFolders('Z:\data\miniscope\raw\p104','A:\data\processing','srcFolderFilterRegexp','14');
% ---
% OR if downsample if reading from a list
ioptions.folderListInfo = 'A:\data\processing';
ioptions.runArg = 'downsampleInscopix';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% FOLDER LIST
% make a txt file containing paths to relevant files
% =====================
% PREPROCESSING
% pre-process files
ioptions.folderListInfo = 'private\analyze\p104_sst.txt';
ioptions.runArg = 'preprocessInscopix';
ostruct = controllerAnalysis('options',ioptions);
% look at dfofs
ioptions.folderListInfo = 'private\analyze\p104_sst.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'playShortClip';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% PCAICA
% list of [PCs ICs] for each subject
% the subject number should be somewhere in the path with a suffix of m### or f###, e.g. m892 or f291
% PCAICA
ioptions.pcaicaList.('F043') = [1200 900];
ioptions.pcaicaList.('M894') = [300 150];
ioptions.pcaicaList.('M810') = [300 150];
ioptions.pcaicaList.('M898') = [300 150];
ioptions.pcaicaList.('M899') = [450 250];
ioptions.folderListInfo = 'private\analyze\fileList.txt';
ioptions.fileFilterRegexp = 'cropped';
ioptions.runArg = 'pcaicaInscopix';
ostruct = controllerAnalysis('options',ioptions);

% sort ICs
ioptions.folderListInfo = 'private\analyze\p104_sst.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.runArg = 'icaChooser';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% CELLMAPS
ioptions.folderListInfo = 'private\analyze\p104_sst.txt';
ioptions.fileFilterRegexp = 'cropp';
ioptions.picsSavePath = 'private\pics\p104_sst\';
ioptions.runArg = 'objectMaps';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% FIRING STATS
ioptions.folderListInfo = 'private\analyze\p104_sst.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.picsSavePath = 'private\pics\FOLDERNAME\';
ioptions.runArg = 'computePeaks';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% CELLMAPS
ioptions.folderListInfo = 'private\analyze\p104_sst.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.picsSavePath = 'private\pics\p104_sst\';
ioptions.runArg = 'objectMaps';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% CREATE SIDE BY SIDE
ioptions.folderListInfo = 'private\analyze\p104_sst.txt';
ioptions.videoDir = 'Z:\data\vids\p104\SST\';
ioptions.fileFilterRegexp = 'crop';
ioptions.sideBySideDir = 'A:\data\miniscope\side_by_side\p104\';
ioptions.runArg = 'createSideBySide';
ostruct = controllerAnalysis('options',ioptions);
% =====================
behavior = loadMovieList('B:\data\video\p104\140515-M894-PAV6.avi');
dfof = loadMovieList('A:\data\pav\p104\SST-Mice\140515-M894-PAV6\2014_05_15_p104_M894_PAV6_turboreg_dfof_5hz_crop.h5');
dfof = normalizeMovie(dfof,'normalizationType','imfilter');
sideBySide = createSideBySide(behavior,dfof);
writeHDF5Data(sideBySide,'A:\data\pav\p104\SST-Mice\2014_05_14_p104_M894_PAV5_sideBySide.h5');
% save part
writeHDF5Data(sideBySide(:,:,1:5000),'A:\data\pav\p104\SST-Mice\2014_05_14_p104_M894_PAV5_sideBySide-2.h5');

sideBySide = downsampleMovie(sideBySide,'downsampleDimension','space','downsampleFactor',2);
writeHDF5Data(sideBySide,'A:\data\pav\p104\2014_05_14_p104_M894_PAV5_sideBySide_lores.h5');


% =====================
% CELLMAPS
ioptions.folderListInfo = 'private\analyze\p104_sst.txt';
ioptions.fileFilterRegexp = 'crop';
ioptions.picsSavePath = 'private\pics\p104_sst\';
ioptions.runArg = 'objectMaps';
ostruct = controllerAnalysis('options',ioptions);

% =====================
% CREATE STIM TRIGGERED MOVIE
ioptions.stimNameArray = {'CS', 'US'};
ioptions.stimIdNumArray = [30 31];
%
ioptions.stimNameArray = {'choice_lever'};
ioptions.stimIdNumArray = [62];
%
ioptions.stimNameArray = {'right_lever_press','left_lever_press'};
ioptions.stimIdNumArray = [4 3];
%
ioptions.videoDir = 'Z:\data\vids\p104\SST\';
ioptions.fileFilterRegexp = 'crop';
ioptions.subjectTablePath = 'C:\Users\Jones Parker\Dropbox\Biafra-Jones\analysis\medfiles\p104_sst\rawData.csv';
ioptions.delimiter = ',';
ioptions.stimNameArray = strrep(ioptions.stimNameArray,'_','__');
ioptions.picsSavePath = ['private\pics\PROTOCOLNUMBER\'];
ioptions.sideBySideDir = 'A:\data\miniscope\side_by_side\p104\';
ioptions.skipSubjData = 1;
ioptions.stimTriggerOnset = 420;
ioptions.folderListInfo = 'private\analyze\p104_sst.txt';
ioptions.runArg = 'stimTriggeredMovie';
ostruct = controllerAnalysis('options',ioptions);

% =====================
% PAV analysis
ostruct.tables.subjectTable = readtable(subjectTablePath,'Delimiter','comma','FileType','text');
ioptions.subjectTablePath = 'C:\Users\Jones Parker\Dropbox\Biafra-Jones\analysis\medfiles\p104_sst\rawData.csv';
ioptions.runArg = 'stimTriggeredAverage';
ioptions.picsSavePath = 'private\pics\p104_sst\';
ioptions.skipSubjData = 1;
ioptions.delimiter = 'comma';
ioptions.stimNameArray = {'lick__all','lick__onset','lick__offset', 'CS', 'US'};
ioptions.stimIdNumArray = [24 24 24 30 31];
ioptions.stimTriggerOnset = 0;
tmpStruct = controllerAnalysis('folderListInfo','private\analyze\p104_sst.txt','options',ioptions);