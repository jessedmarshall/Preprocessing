function loadBatchFxns()
	% loads the necessary directories to have the batch functions present
	% biafra ahanonu
	% started: 2013.12.24 [08:46:11]

	% add controller directory and subdirectories to path
	addpath(genpath(pwd));
	% EM analysis path
	addpath(genpath(['..' filesep 'Lacey']));
	% add path for Miji, change as needed
	pathtoMiji = 'A:\biafra\programs\Fiji.app\scripts\';
	addpath(pathtoMiji);

	% set default figure properties
	setFigureDefaults();