% =====================
% DOWMSAMPLING
% downsample if all decompressed files are in the same folder
ioptions.folderListInfo = 'A:\data\huntington\p215_reversal\processing\';
ioptions.runArg = 'downsampleInscopix';
ostruct = controllerAnalysis('options',ioptions);
% re-create folder structure
output = moveFilesToFolders('Z:\data\miniscope\raw\p215\','A:\data\huntington\p215_reversal\processing\');
% ---
% OR if downsample if reading from a list
ioptions.folderListInfo = 'private\analyze\p215.txt';
ioptions.runArg = 'downsampleInscopix';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% FOLDER LIST
% make a txt file containing paths to relevant files
% =====================
% PREPROCESSING
% pre-process files
ioptions.folderListInfo = 'private\analyze\p215.txt';
ioptions.runArg = 'preprocessInscopix';
ostruct = controllerAnalysis('options',ioptions);
% look at dfofs
ioptions.folderListInfo = 'private\analyze\p215.txt';
ioptions.fileFilterRegexp = 'cropped';
ioptions.runArg = 'playShortClip';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% PCAICA
% list of [PCs ICs] for each subject
% the subject number should be somewhere in the path with a suffix of m### or f###, e.g. m892 or f291
ioptions.pcaicaList.('F043') = [1200 900];
ioptions.pcaicaList.('M120') = [700 550];
ioptions.pcaicaList.('M121') = [700 550];
ioptions.folderListInfo = 'private\analyze\p215.txt';
ioptions.fileFilterRegexp = 'cropped';
ioptions.runArg = 'pcaicaInscopix';
ostruct = controllerAnalysis('options',ioptions);
% sort ICs
ioptions.folderListInfo = 'private\analyze\p215.txt';
ioptions.fileFilterRegexp = 'cropped';
ioptions.runArg = 'icaChooser';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% CELLMAPS
ioptions.folderListInfo = 'private\analyze\p215.txt';
ioptions.fileFilterRegexp = 'cropped';
ioptions.picsSavePath = 'private\pics\p215\';
ioptions.runArg = 'objectMaps';
ostruct = controllerAnalysis('options',ioptions);
% =====================
% FIRING STATS
ioptions.folderListInfo = 'private\analyze\p215.txt';
ioptions.fileFilterRegexp = 'cropped';
ioptions.picsSavePath = 'private\pics\p215\';
ioptions.runArg = 'computePeaks';
ostruct = controllerAnalysis('options',ioptions);