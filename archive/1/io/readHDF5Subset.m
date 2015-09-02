function [dataSubset] = readHDF5Subset(inputFilePath, offset, block, varargin)
	% biafra ahanonu
	% started 2013.11.10
	% gets a subset of data from an inputFilePath
	% based on code from MathWorks; for details, see http://www.mathworks.com/help/matlab/ref/h5d.read.html

	% filePath = 'A:\shared\test2\concatenated_2013_10_05_p111_m728_vonfrey1.h5';

	%========================
	% old way of saving, only temporary until full switch
	options.offset = 'tiff';
	options.datasetName = '1';
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
	% offset and size of the block to get
	offset = fliplr(offset);%[0 0 0]
	block = fliplr(block);%[xDim yDim 1]
	% select the hyperslab
	H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offset,[],[],block);
	% select the data subset
	dataSubset = H5D.read(dset_id,'H5ML_DEFAULT',mem_space_id,file_space_id,plist);
	% figure(100)
	% imagesc(data);
	size(dataSubset);
	% close IDs
	H5S.close(file_space_id);
	H5D.close(dset_id);
	H5F.close(fid);