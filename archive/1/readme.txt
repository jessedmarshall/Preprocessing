# baifra ahanonu
# started: 2013.11.11
# readme for controlling (batch) pre-processing and analysis of miniscope data
# updated: 2013.11.18 [20:00:24]

#general
	+ Controllers (i.e. wrapper functions) are located in the root directory, they should be used to call individual functions that only do at most a couple operations and accept a set of simple inputs (e.g. avoid complex structures as inputs).
	+ The controllers should handle pushing around and saving of data NOT the individual functions.
	+ getOptions MUST be loaded for most (if not all?) of the functions to work. This function basically handles varargin in a standardized manner.

#data organization
	+ To make the code as general as possible, data is moved around as plain 2d/3D matrices. If you want to organize that differently, do so at the controller level rather than inside functions.
	+ Inputs to the current controllers involve a text file pointing to folders that contain
	+ Data is organized as follows:
		+ PC/IC filters: [MxNxP] matrix with M and N being height/width of video and P = {nPCs | nICs}
		+ PC/IC traces: [Pxf] matrix where P = {nPCs | nICs} and f = frames (of the movie)
		+ outputStruct: takes on various forms, see each controller for details

#pre-processing
	+ The main m-file is controllerPreprocessMovie.m, which contains a series of functions to turboreg, normalize, dfof, and downsample the movie. The code is modular so different pre-processing can be added to the pipeline pretty easily.
	+ TO RUN: see below
	+ outputStruct = controllerPreprocessMovie('analyze\p728_batch_pre.txt');
		'fileFilterRegexp' = 'concatenated_', is the regexp for the name of the downsampled (for the moment) movies.
		'frameList' = [], can make this a 1xN vector indicating the frames of the movie you want to look at
		'turboregType' = 'preselect', means that you preselect the regions to turboreg for all the movies before going forward

#analysis
	+ The main m-file is controllerAnalysis.m, which helps coordinate calling of separate functions that help with PCA-ICA, spike detection, and other analysis.
	+ TO RUN: see below
	+ outputStruct = controllerAnalysis('', outputStruct)
	+ outputStruct = controllerAnalysis('', 'analyze\p728_batch_pre.txt')
		+ fileFilterRegexp = 'concatenated_.*.h5' is the default, change to suit your needs (e.g. controllerAnalysis('', 'analyze\p728_batch_pre.txt','fileFilterRegexp','kitty.*.tif'))

#notes
	+ The code works with .tif, but REALLY prefers if you use HDF5 files.
	+ The code currently assumes that ALL HDF5 files containing movies place the movies in a dataset named /1 (or 1 when exporting from ImageJ) inside the .h5 file.
	+ Normalization (e.g. bandpass divisive) is currently disabled. Jesse and i tested PCA-ICA on the same movies with and without this step and there was no discernible difference in the quality of the traces.
	+ The code doesn't assume much about the structure of your data folder organization, only that you give it folders with .tiff (size <4GB each) or .h5 (unlimited size). If there are multiple movies in a folder, they will be concatenated for the batch analysis.
	+ I currently only support analyzing a slice of a movie for .h5 files.
	+ Turboreg currently splits the movie into chunks for parallel image registration (avoid serialization errors due to transfer to large movies to workers). The actual turboreg isn't as i assume you only turboreg a sub-region. This will be updated soon.
	+ Turboreg currently uses the first frame for turboreg, so either change that part of the code or turn the LED on before the trial begins.
	+ The code currently asks for PCs/ICs, the option is there to add the nPCs and nICs in the input file with the folders (e.g. \path,nICs,nPCs).