function [outputMovie movieDims nPixels nFrames] = loadMovieList(movieList, varargin)
	% load movies, automatically detects type (avi, tif, or hdf5) and concatenates if multiple movies in a list
	% biafra ahanonu
	% started: 2013.11.01
	% inputs
	% 	movieList = either a char string containing a path name or a cell array containing char strings, e.g. 'pathToFile' or {'path1','path2'}
	% outputs
	% 	outputMovie
	% 	movieDims
	% 	nPixels
	% 	nFrames
	% NOTE: assume 3D movies with [x y frames] as dimensions, if movies are different sizes, use largest dimensions and align all movies to top-left corner

	% changelog
		% 2014.02.14 [14:14:39] now can load non-monotonic lists for avi and hdf5 files.
		% 2014.03.27 - several updates to speed up function, fixed several assumption issues (all movies same file type, etc.) and brought name scheme in line with other fxns
		% 2015.02.25 [15:32:10] fixed bug pertaining to treatMoviesAsContinuous not working properly if frameList was blank and only a single movie was input.
		% 2015.05.28 [02:39:51] bug fix with treatMoviesAsContinuous, the global frames weren't quite correct
	% TODO
		% MAKE tiff loading recognize frameList input
		% add preallocation by pre-reading each movie's dimensions - DONE
		% determine file type by properties of file instead of extension (don't trust input...)
		% remove need to use tmpMovie....
		% verify movies are of supported load types, remove from list if not and alert user, should be an option (e.g. return instead) - DONE
		% allow user to input frames that are global across several files, e.g. [1:500 1:200 1:300] are the lengths of each movie, so if input [650:670] in frameList, should grab 150:170 from movie 2

	% ========================
	options.supportedTypes = {'.h5','.hdf5','.tif','.tiff','.avi'};
	% movie type
	options.movieType = 'tiff';
	% hierarchy name in hdf5 where movie is
	options.inputDatasetName = '/1';
	% convert file movie to double?
	options.convertToDouble = 0;
	% 'single','double'
	options.loadSpecificImgClass = [];
	% list of specific frames to load
	options.frameList = [];
	% should the waitbar be shown?
	options.waitbarOn=1;
	% just return the movie dimensions
	options.getMovieDims = 0;
	% treat movies in list as continuous with regards to frame
	options.treatMoviesAsContinuous = 0;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
	    eval([fn{i} '=options.' fn{i} ';']);
	end

	% ========================
	% allow usr to input just a string if a single movie
    if strcmp(class(movieList),'char')
        movieList = {movieList};
    end

	% ========================
	% remove unsupported files
	for iMovie=1:length(movieList)
		thisMoviePath = movieList{iMovie};
		[options.movieType supported] = getMovieFileType(thisMoviePath);
		if supported==0
			display(['removing unsupported file from list: ' thisMoviePath])
		else
			tmpMovieList{iMovie} = movieList{iMovie};
		end
	end
	% if tmp doesn't exist, means no input files are valid, return
	if exist('tmpMovieList','var')
		movieList = tmpMovieList;
	else
		outputMovie = NaN;
		movieDims = NaN;
		nPixels = NaN;
		nFrames = NaN;
		return;
	end
	numMovies = length(movieList);

    % ========================
	% pre-read each file to allow pre-allocation of output file
	for iMovie=1:numMovies
		thisMoviePath = movieList{iMovie};
		[options.movieType supported] = getMovieFileType(thisMoviePath);
		if supported==0

		end
		switch options.movieType
			case 'tiff'
				tiffHandle = Tiff(thisMoviePath, 'r');
				tmpFrame = tiffHandle.read();
				tiffHandle.close(); clear tiffHandle
				xyDims=size(tmpFrame);
				dims.x(iMovie) = xyDims(1);
				dims.y(iMovie) = xyDims(2);
				dims.z(iMovie) = size(imfinfo(thisMoviePath),1);
			case 'hdf5'
				hinfo = hdf5info(thisMoviePath);
				datasetNames = {hinfo.GroupHierarchy.Datasets.Name};
				thisDatasetName = strmatch(options.inputDatasetName,datasetNames);
				hReadInfo = hinfo.GroupHierarchy.Datasets(thisDatasetName);
				dims.x(iMovie) = hReadInfo.Dims(1);
				dims.y(iMovie) = hReadInfo.Dims(2);
				dims.z(iMovie) = hReadInfo.Dims(3);
				tmpFrame = readHDF5Subset(thisMoviePath,[0 0 1],[dims.x(iMovie) dims.y(iMovie) 1],'datasetName',options.inputDatasetName);
			case 'avi'
				xyloObj = VideoReader(thisMoviePath);
				dims.x(iMovie) = xyloObj.Height;
				dims.y(iMovie) = xyloObj.Width;
				dims.z(iMovie) = xyloObj.NumberOfFrames;
				tmpFrame = read(xyloObj, 1);
		end
		if isempty(options.loadSpecificImgClass)
			imgClass = class(tmpFrame);
		else
			imgClass = options.loadSpecificImgClass;
		end
		% change dims.z if user specifies a list of frames
		if (~isempty(options.frameList)|options.frameList>dims.z(iMovie))&options.treatMoviesAsContinuous==0
			dims.z(iMovie) = length(options.frameList);
		end
	end
	if options.getMovieDims==1
		outputMovie = dims;
		return;
	end
	% dims
	xDimMax = max(dims.x);
	yDimMax = max(dims.y);
	switch options.treatMoviesAsContinuous
		case 0
			zDimLength = sum(dims.z);
		case 1
			if isempty(options.frameList)
				zDimLength = sum(dims.z);
			else
				zDimLength = length(options.frameList);
			end
		otherwise
			% body
	end
	% pre-allocated output structure, convert to input movie datatype
	if strcmp(imgClass,'single')|strcmp(imgClass,'double')
		if isempty(options.loadSpecificImgClass)
			% outputMovie = nan([xDimMax yDimMax zDimLength],imgClass);
		else
			display('pre-allocating single matrix...')
			outputMovie = ones([xDimMax yDimMax zDimLength],imgClass);
			% j = whos('outputMovie');j.bytes=j.bytes*9.53674e-7;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
			% return;
			outputMovie(:,:,:) = 0;
		end
	else
		% outputMovie = zeros([xDimMax yDimMax zDimLength],imgClass);
	end

	if options.treatMoviesAsContinuous==1&~isempty(options.frameList)
		% totalZ = sum(dims.z);
		zdims = dims.z;
		frameList = options.frameList;
		zdimsCumsum = cumsum([0 zdims]);
		zdims = [1 zdims];
		for i=1:(length(zdims)-1)
		    g{i} = frameList>zdimsCumsum(i)&frameList<=zdimsCumsum(i+1);
		    globalFrame{i} = frameList(g{i}) - zdimsCumsum(i);
		    dims.z(i) = length(globalFrame{i});
		end
		cellfun(@max,globalFrame,'UniformOutput',false)
		cellfun(@min,globalFrame,'UniformOutput',false)
		% pause
	else
		globalFrame = [];
	end

	% ========================
	for iMovie=1:numMovies
	    thisMoviePath = movieList{iMovie};

	    [options.movieType] = getMovieFileType(thisMoviePath);

	    if isempty(globalFrame)
	    	thisFrameList = options.frameList;
	    else
	    	thisFrameList = globalFrame{iMovie};
	    	if isempty(thisFrameList)
	    		display(['no global frames:' num2str(iMovie) '/' num2str(numMovies) ': ' thisMoviePath])
	    		continue
	    	end
	    end

	    display(['loading ' num2str(iMovie) '/' num2str(numMovies) ': ' thisMoviePath])
	    % depending on movie type, load differently
		switch options.movieType
			case 'tiff'
				if isempty(thisFrameList)
		    		tmpMovie = load_tif_movie(thisMoviePath,1);
		    		tmpMovie = tmpMovie.Movie;
		    	else
		    		tmpMovie = load_tif_movie(thisMoviePath,1,'Numberframe',thisFrameList);
		    		tmpMovie = tmpMovie.Movie;
		    	end
	    	% ========================
			case 'hdf5'
				if isempty(thisFrameList)
					hinfo = hdf5info(thisMoviePath);
					% hReadInfo = hinfo.GroupHierarchy.Datasets(1);
					datasetNames = {hinfo.GroupHierarchy.Datasets.Name};
					thisDatasetName = strmatch(inputDatasetName,datasetNames);
					hReadInfo = hinfo.GroupHierarchy.Datasets(thisDatasetName);
					% read in the file
	                % hReadInfo.Attributes
					tmpMovie = hdf5read(hReadInfo);
					if isempty(options.loadSpecificImgClass)
					else
						tmpMovie = cast(tmpMovie,imgClass);
					end
				else
					inputFilePath = thisMoviePath;
					hinfo = hdf5info(inputFilePath);
					% hReadInfo = hinfo.GroupHierarchy.Datasets(1);
					datasetNames = {hinfo.GroupHierarchy.Datasets.Name};
					thisDatasetName = strmatch(options.inputDatasetName,datasetNames);
					hReadInfo = hinfo.GroupHierarchy.Datasets(thisDatasetName);
					xDim = hReadInfo.Dims(1);
					yDim = hReadInfo.Dims(2);
					% tmpMovie = readHDF5Subset(inputFilePath,[0 0 thisFrameList(1)],[xDim yDim length(thisFrameList)],'datasetName',options.inputDatasetName);
					framesToGrab = thisFrameList;
					nFrames = length(framesToGrab);
					reverseStr = '';
					for iframe = 1:nFrames
						readFrame = framesToGrab(iframe);
						thisFrame = readHDF5Subset(inputFilePath,[0 0 readFrame-1],[xDim yDim 1],'datasetName',options.inputDatasetName);
						if isempty(options.loadSpecificImgClass)
							tmpMovie(:,:,iframe) = thisFrame;
						else
					    	% assume 3D movies with [x y frames] as dimensions
						    if(iMovie==1)
								outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),iframe) = cast(thisFrame,imgClass);
						    else
						    	zOffset = sum(dims.z(1:iMovie-1));
						    	outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),(zOffset+iframe)) = cast(thisFrame,imgClass);
						    end
						end
						reverseStr = cmdWaitbar(iframe,nFrames,reverseStr,'inputStr','loading hdf5','waitbarOn',options.waitbarOn,'displayEvery',50);
					end
				end
			% ========================
			case 'avi'
				xyloObj = VideoReader(thisMoviePath);

				if isempty(thisFrameList)
					nFrames = xyloObj.NumberOfFrames;
					framesToGrab = 1:nFrames;
				else
					nFrames = length(thisFrameList);
					framesToGrab = thisFrameList;
				end
				vidHeight = xyloObj.Height;
				vidWidth = xyloObj.Width;

				% Preallocate movie structure.
				tmpMovie = zeros(vidHeight, vidWidth, nFrames, 'uint8');

				% Read one frame at a time.
				reverseStr = '';
				iframe = 1;
				nFrames = length(framesToGrab);
				for iframe = 1:nFrames
					readFrame = framesToGrab(iframe);
				    tmpMovie(:,:,iframe) = read(xyloObj, readFrame);
		            % reduce waitbar access
		    		reverseStr = cmdWaitbar(iframe,nFrames,reverseStr,'inputStr','loading avi','waitbarOn',options.waitbarOn,'displayEvery',50);
		    		iframe = iframe + 1;
				end
			% ========================
			otherwise
				% let's just not deal with this for now
				return;
		end
		if exist('tmpMovie','var')
		    if(iMovie==1)
				outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),1:dims.z(iMovie)) = tmpMovie;
		        % outputMovie(:,:,:) = tmpMovie;
		    else
		    	% assume 3D movies with [x y frames] as dimensions
		    	zOffset = sum(dims.z(1:iMovie-1));
		    	outputMovie(1:dims.x(iMovie),1:dims.y(iMovie),(zOffset+1):(zOffset+dims.z(iMovie))) = tmpMovie;
		        % outputMovie(:,:,end+1:end+size(tmpMovie,3)) = tmpMovie;
		    end
	    	clear tmpMovie;
		else

		end
	end

	% hinfo = hdf5info('A:\shared\concatenated_2013_07_05_p62_m728_MAG1.h5');
	% DFOF = hdf5read(hinfo.GroupHierarchy.Datasets(1));
	% get size of movie
	% DFOFsize = size(DFOF.Movie);
	movieDims = size(outputMovie);
	nPixels = movieDims(1)*movieDims(2);
	nFrames = movieDims(3);
	if options.waitbarOn==1
	    display(['movie class: ' class(outputMovie)]);
	    display(['movie size: ' num2str(size(outputMovie))]);
	    display(['x-dims: ' num2str(dims.x)]);
	    display(['y-dims: ' num2str(dims.y)]);
	    display(['z-dims: ' num2str(dims.z)]);
	end
	j = whos('outputMovie');j.bytes=j.bytes*9.53674e-7;display(['movie size: ' num2str(j.bytes) 'Mb | ' num2str(j.size) ' | ' j.class]);
    % display(dims);
	% Convert the movie to single
	% DFOF=single(DFOF);
	if options.convertToDouble==1
		display('converting to double...');
		outputMovie=double(outputMovie);
	end

function [movieType supported] = getMovieFileType(thisMoviePath)
    % determine how to load movie, don't assume every movie in list is of the same type
	supported = 1;
    try
		[pathstr,name,ext] = fileparts(thisMoviePath);
	catch
		movieType = '';
		supported = 0;
	end
	% files are assumed to be named correctly (lying does no one any good)
	if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
		movieType = 'hdf5';
	elseif strcmp(ext,'.tif')|strcmp(ext,'.tiff')
		movieType = 'tiff';
	elseif strcmp(ext,'.avi')
		movieType = 'avi';
	else
		movieType = '';
		supported = 0;
	end