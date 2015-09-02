function [inputMatricies] = createCombinedMatrix(inputMatricies,varargin)
	% horizontally concatenates movies.
	% biafra ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputMatricies - cell array of paths to matricies or a cell array of matricies
	% outputs
		%

	% changelog
		%
	% TODO
		% maybe make dimesion 2 spatially the same so the movie is flush?

	%========================
	% number of frames in each movie to load, [] = all, 1:500 would be 1st to 500th frame.
	options.frameList = [];
	% whether to convert movie to double on load, not recommended
	options.convertToDouble = 0;
	% name of HDF5 dataset name to load
	options.inputDatasetName = '/1';
	% string to a movie, preferably AVI
	options.recordMovie = 0;
	% amount of pixels around the border to crop in primary movie
	options.pxToCrop = [];
	% downsample combined movie
	options.downsampleFactorFinal = 1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		nMatrix = length(inputMatricies);
		% if given paths, load the movies in and get max size of movies
		matrixDims = zeros([nMatrix 3]);
		for matrixNo = 1:nMatrix
			if strcmp(class(inputMatricies{matrixNo}),'char')
				inputMatricies{matrixNo} = loadMovieList(inputMatricies{matrixNo},'convertToDouble',options.convertToDouble,'frameList',options.frameList,'inputDatasetName',options.inputDatasetName);
			end
			matrixDims(matrixNo,:) = size(inputMatricies{matrixNo});
		end
		%
		maxDims = max(matrixDims,[],1)
		%
		for matrixNo = 1:nMatrix
			thisMatrixDims = size(inputMatricies{matrixNo});
			dimsDiff = maxDims-thisMatrixDims;
			dimsDiff(1) = 0;
			inputMatricies{matrixNo} = padarray(inputMatricies{matrixNo},dimsDiff,NaN,'post');
			inputMatricies{matrixNo} = permute(inputMatricies{matrixNo},[2 1 3]);
			size(inputMatricies{matrixNo})
		end
		inputMatricies = horzcat(inputMatricies{:});
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end