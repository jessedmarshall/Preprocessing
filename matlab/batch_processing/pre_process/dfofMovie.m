function [dfofMatrix inputMovieF0] = dfofMovie(inputMovie, varargin)
    % does deltaF/F for a movie using bsxfun for faster processing.
    % biafra ahanonu
    % started 2013.11.09 [09:12:36]
    % inputs
        % inputMovie - either a [x y t] matrix or a char string specifying a HDF5 movie.
    % outputs
        %
    % changelog
        % 2013.11.22 [17:49:34]
    % TODO
        %

    %========================
    options.inputDatasetName = '/1';
    options.dfofType = 'divide';
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

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

    inputMovieClass = class(inputMovie);
    if strcmp(inputMovieClass,'char')
        inputMovie = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName);
        % [pathstr,name,ext] = fileparts(inputFilePath);
        % options.newFilename = [pathstr '\concat_' name '.h5'];
    end
    inputMovieClass = class(inputMovie);

    % get the movie F0
    display('getting F0...')
    inputMovieF0 = zeros([size(inputMovie,1) size(inputMovie,2)]);
    for row=1:size(inputMovie,1)
        % inputMovieF0 = nanmean(inputMovie,3);
        inputMovieF0(row,:) = nanmean(squeeze(inputMovie(row,:,:)),2);
    end
    % [figHandle figNo] = openFigure(54666, '');
    % imagesc(inputMovieF0)
    % pause
    % convert to single
    if ~strcmp(inputMovieClass,'single')
        inputMovieF0 = cast(inputMovieF0,'single');
        inputMovie = cast(inputMovie,'single');
    end
    % bsxfun for fast matrix divide
    switch dfofType
        case 'divide'
            display('F(t)/F0...')
            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
            dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
        case 'dfof'
            display('F(t)/F0 - 1...')
            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
            dfofMatrix = bsxfun(@ldivide,inputMovieF0,inputMovie);
            dfofMatrix = dfofMatrix-1;
        case 'minus'
            display('F(t)-F0...')
            % dfofMatrix = bsxfun(@ldivide,double(inputMovieF0),double(inputMovie));
            dfofMatrix = bsxfun(@minus,inputMovie,inputMovieF0);
        otherwise
            return;
    end