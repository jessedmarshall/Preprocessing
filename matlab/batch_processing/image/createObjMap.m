function [cellmap] = createObjMap(inputImages,varargin)
    % creates a cellmap from a ZxXxY input matrix of input images
    % biafra ahanonu
    % started: 2013.10.12
    % inputs
        %
    % outputs
        %
    % changelog
        % 2013.12.15 [22:43:23] converted to a matrix operation, much faster...
    % TODO
        %

    %========================
    options.exampleOption = '';
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    if isempty(inputImages)
        cellmap = [];
    else
        cellmap = squeeze(max(inputImages,[],1));
    end

    % OLD CODE
    % cellmap = [];
    % icstocheck = size(IcaFilters,1);
    % for i = 1:icstocheck
    %     if ~isempty(IcaFilters(i,:,:))
    %         if isempty(cellmap)
    %             cellmap = squeeze(IcaFilters(i,:,:));;
    %         else
    %             cellmap = max(cellmap,squeeze(IcaFilters(i,:,:)));
    %         end
    %     end
    % end