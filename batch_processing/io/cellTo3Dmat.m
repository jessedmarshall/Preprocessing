function outMatrix = cellTo3Dmat(inputCell,varargin)
	% converts input cell to 3D matrix
	% biafra ahanonu
    % updated: 2013.10.08 [11:11:17]
    % inputs
    	%
    % outputs
    	%
    % changelog
    	%
    % TODO
    	%

    %========================
    options.exampleOption = 'doSomething';
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    % 	eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    % get length
    lengthCell = length(inputCell);
    %Convert cell array back to 3D matrix
    tempCell = cell2mat(inputCell);
    [r,c]=size(tempCell)
    outMatrix = permute(reshape(tempCell',[r,c/lengthCell,lengthCell]),[2,1,3]);