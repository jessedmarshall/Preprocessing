function writeHDF5Data(inputData,saveDir,varargin)
	% biafra ahanonu
	% started: 2013.11.01
	% saves input data to a HDF5 file
	%
	% inputs
		% movieList = full path names for movies to concatenate

	%========================
	% old way of saving, only temporary until full switch
	options.datasetname = '/1';
	% get options
	options = getOptions(options,varargin);
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	if exist(saveDir,'file')
		delete(saveDir)
	end
	% create a h5 file
	display(['creating HDF5 file: ' saveDir])
	h5create(saveDir,options.datasetname,size(inputData));
	% write out the inputData
	display(['writing HDF5 file: ' saveDir])
	h5write(saveDir,options.datasetname, inputData);