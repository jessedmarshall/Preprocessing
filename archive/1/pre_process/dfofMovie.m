function [dfofMatrix inputMovieF0] = dfofMovie(inputMovie, varargin)
    % biafra ahanonu
    % started 2013.11.09 [09:12:36]
    % dfof a movie

    % check that input is not empty
    if isempty(inputMovie)
        return;
    end
    %========================
    % old way of saving, only temporary until full switch
    options.normalizationType = 'NA';
    % get options
    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end
    %========================

    % get the movie F0
    display('getting F0...')
    inputMovieF0 = mean(inputMovie,3);
    % imagesc(inputMovieF0);
    % bsxfun for fast matrix divide
    display('dividing movie by F0...')
    dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));