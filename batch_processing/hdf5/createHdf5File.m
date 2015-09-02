function createHdf5File(filename, datasetName, inputData, varargin)
	% creates an HDF5 file at filename under given datasetName hierarchy and saves inputData
	% biafra ahanonu
	% started: 2014.01.07
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	% Create the HDF5 file
	fcpl_id = H5P.create('H5P_FILE_CREATE');
	fapl_id = H5P.create('H5P_FILE_ACCESS');

	fid = H5F.create(filename, 'H5F_ACC_TRUNC', fcpl_id, fapl_id);

	% Create the Space for the Dataset
	initDims = size(inputData);
	h5_initDims = fliplr(initDims);
	maxDims = [initDims(1) initDims(2) -1];
	h5_maxDims = fliplr(maxDims);
	space_id = H5S.create_simple(3, h5_initDims, h5_maxDims);

	% Create the Dataset
	% datasetName = '1';
	dcpl_id = H5P.create('H5P_DATASET_CREATE');
	chunkSize = [initDims(1) initDims(2) 1];
	h5_chunkSize = fliplr(chunkSize);
	H5P.set_chunk(dcpl_id, h5_chunkSize);

	% dsetType_id = H5T.copy('H5T_NATIVE_DOUBLE');
	dsetType_id = H5T.copy('H5T_NATIVE_UINT16');

	dset_id = H5D.create(fid, datasetName, dsetType_id, space_id, dcpl_id);

	% Initial Data to Write
	% rowDim = initDims(1); colDim = initDims(2);
	initDataToWrite = rand(initDims);

	% Write the initial data
	H5D.write(dset_id, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', inputData);

	% Close the open Identifiers
	H5S.close(space_id);
	H5D.close(dset_id);
	H5F.close(fid);