function [options] = getOptions(options,varargin)
    % biafra ahanonu
    % started: 2013.11.04
    % gets default options for a function
    %
    % inputs
        % options - structure with options given
        % varargin - as stated
    % to unpack in calling function use:
    % %========================
    % % old way of saving, only temporary until full switch
    % options.movieType = 'tiff';
    % % get options
    % options = getOptions(options,varargin);
    % % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %     eval([fn{i} '=options.' fn{i} ';']);
    % end
    % %========================

    %Process options
    validOptions = fieldnames(options);
    varargin = varargin{1};
    for i = 1:2:length(varargin)
        val = varargin{i};
        if ischar(val)
            %display([varargin{i} ': ' num2str(varargin{i+1})]);
            if ~isempty(strmatch(val,validOptions))
                % way more elegant
                options.(val) = varargin{i+1};
                % eval(['options.' val '=' num2str(varargin{i+1}) ';']);
            end
        else
            continue;
        end
    end
    %display(options);