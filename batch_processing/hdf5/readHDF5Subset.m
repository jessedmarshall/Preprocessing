function [dataSubset] = readHDF5Subset(inputFilePath, offset, block, varargin)
	% gets a subset of data from an HDF5 file
	% biafra ahanonu
	% started: 2013.11.10
	% based on code from MathWorks; for details, see http://www.mathworks.com/help/matlab/ref/h5d.read.html
	% inputs
		%
		% offset = [xOffset yOffset frameOffset]
		% block = [xDim yDim frames]
	% options
		% datasetName = hierarchy where data is stored in HDF5 file
	% changelog
		% 2013.11.30 [17:59:14]
		% 2014.01.15 [09:59:53] cleaned up code, removed unnecessary options

	%========================
	% old way of saving, only temporary until full switch
	options.datasetName = '/1';
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% get file info
	% hinfo = hdf5info(inputFilePath);
	% hReadInfo = hinfo.GroupHierarchy.Datasets(1);
	% xDim = hReadInfo.Dims(1);
	% yDim = hReadInfo.Dims(2);

	% open fid to hdf5 dataset
	plist = 'H5P_DEFAULT';
	fid = H5F.open(inputFilePath);
	dset_id = H5D.open(fid,options.datasetName);
	dims = fliplr(block);%[xDim yDim 1]
	mem_space_id = H5S.create_simple(length(dims),dims,[]);
	file_space_id = H5D.get_space(dset_id);

	% offset and size of the block to get, flip dimensions so in format that H5S wants
	offset = fliplr(offset);
	block = fliplr(block);

	% select the hyperslab
	H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offset,[],[],block);
	% select the data subset
	dataSubset = H5D.read(dset_id,'H5ML_DEFAULT',mem_space_id,file_space_id,plist);

	% close IDs
	H5S.close(file_space_id);
	H5D.close(dset_id);
	H5F.close(fid);