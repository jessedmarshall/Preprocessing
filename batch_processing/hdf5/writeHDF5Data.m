function [success] = writeHDF5Data(inputData,saveDir,varargin)
	% saves input data to a HDF5 file, tries to preserve datatype
	% biafra ahanonu
	% started: 2013.11.01
	%
	% inputs
		% movieList = full path names for movies to concatenate
	% outputs
		% success = 1 if successful save, 0 if error.
	% options
		% datasetname = HDF5 hierarchy where data should be stored

	% changelog
		% 2014.01.23 - updated so that it saves as the input data-type rather than defaulting to double
		% 2014.10.06 - added chunking to save, decrease compatibility problems.
	% TODO
		% Add option to overwrite existing HDF5 file ()

	%========================
	% old way of saving, only temporary until full switch
	options.datasetname = '/1';
	% save only a portion of the dataset, useful for large datasets
	% 3D matrix, [0 0 0] start and [x y z] end.
	options.hdfStart = [];
	options.hdfCount = [];
	% get options
	options = getOptions(options,varargin);
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	try
		if exist(saveDir,'file')
			delete(saveDir)
		end
		inputClass = class(inputData);
		display(['input class: ' inputClass])
		% create a h5 file
		display(['creating HDF5 file: ' saveDir])
		if isempty(options.hdfStart)
			dataDims = size(inputData);
			% [dim1 dim2 dim3] = size(inputData);
		else
			dataDims = options.hdfCount - options.hdfStart;
		end
		% set the last dimension to 1 for chunking
		dataDimsChunkCopy = dataDims;
		dataDimsChunkCopy(end) = 1;
		% create HDF dataspace
		h5create(saveDir,options.datasetname,dataDims,'Datatype',inputClass,'ChunkSize',dataDimsChunkCopy);
		% write out the inputData
		display(['writing HDF5 file: ' saveDir])
		if isempty(options.hdfStart)
			h5write(saveDir,options.datasetname, inputData);
		else
			h5write(saveDir,options.datasetname, inputData, options.hdfStart, options.hdfCount);
		end
		display('success!!!');
		success = 1;
	catch err
		success = 0;
		display('something went wrong 0_o');
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end