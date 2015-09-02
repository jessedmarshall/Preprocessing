function [outputMovie movieSize Npixels Ntime] = loadMovieList(movieList, varargin)
	% biafra ahanonu
	% started: 2013.11.01
	% load movies, automatically concatenate
	%
	% inputs
		% movieList = full path names for movies to concatenate

	%========================
	% old way of saving, only temporary until full switch
	options.movieType = 'tiff';
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
	    eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	[pathstr,name,ext] = fileparts(movieList{1});
	if strcmp(ext,'.h5')|strcmp(ext,'.hdf5')
		options.movieType = 'hdf5';
	elseif strcmp(ext,'.tif')|strcmp(ext,'.tiff')
		options.movieType = 'tiff';
	end

	numMovies = length(movieList);
	for iMovie=1:numMovies
	    thisMovie = movieList{iMovie};
	    display(['loading ' num2str(iMovie) '/' num2str(numMovies) ': ' thisMovie])
	    % depending on movie type, load differently
		switch options.movieType
			case 'tiff'
	    		tmpMovie = load_tif_movie(thisMovie,1);
	    		tmpMovie = tmpMovie.Movie;
			case 'hdf5'
				hinfo = hdf5info(thisMovie);
				hReadInfo = hinfo.GroupHierarchy.Datasets(1);
				% read in the file
				tmpMovie = hdf5read(hReadInfo);
			otherwise
				return;
		end
	    if(iMovie==1)
	        outputMovie(:,:,:) = tmpMovie;
	    else
	        outputMovie(:,:,end+1:end+length(tmpMovie)) = tmpMovie;
	    end
	    clear tmpMovie;
	end

	% hinfo = hdf5info('A:\shared\concatenated_2013_07_05_p62_m728_MAG1.h5');
	% DFOF = hdf5read(hinfo.GroupHierarchy.Datasets(1));
	% get size of movie
	% DFOFsize = size(DFOF.Movie);
	movieSize = size(outputMovie);
	Npixels = movieSize(1)*movieSize(2);
	Ntime = movieSize(3);
	% Convert the movie to single
	% DFOF=single(DFOF);
	outputMovie=double(outputMovie);