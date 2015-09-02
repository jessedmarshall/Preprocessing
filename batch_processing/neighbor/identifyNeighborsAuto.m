function neighborsCell = identifyNeighborsAuto(inputImages, inputSignals, varargin)
    % this code automatically sorts through to find all obj neighbors within a certain distance of the target (boundary to boundary). the output is a cell array with vectors of the neighbor indices to each obj.
    % biafra ahanonu
    % started: 2013.11.01
    % based on code by laurie burns, started: sept 2010.
    % inputs
        % inputFilters - cell array of [x y nFilters] matrices containing each set of filters
        % inputTraces - cell array of [nFilters frames] matrices containing each set of filter traces
    % options
        % _
    % outputs
        % _
    % changelog
        % 2013.11.01 refactored so accepts ICA filters and traces as input, also changed display to it matches ICAchooser, e.g. it applies a cellmap along with the identified and new cells
    % TODO
        %

    %========================
    options.plottingOn = 0;
    options.overlapradius = 10;
    % get options
    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end
    %========================

    % cell vector info
    cellvec(1) = 1;
    cellvec(2) = size(inputImages,1);

    %% look for overlap of IC and dilated IC
    neighborsCell=cell(cellvec(2),1);
    se = strel('disk',overlapradius,0);
    % threshold ICs
    inputImages = thresholdImages(inputImages);
    % reshape to (x,y,z) indexing for compatibility
    inputImages = permute(inputImages, [2 3 1]);

    reverseStr = '';
    nSignals = cellvec(2);
    figure(222)
    for c = 1:nSignals
        % get a dilated version of the thresholded image
        thisCellDilateCopy = repmat(imdilate(squeeze(inputImages(:,:,c)),se),[1 1 size(inputImages,3)]);
        % thisCellDilateCopy = permute(thisCellDilateCopy, [3 1 2]);
        % matrix multiple, any overlap will be labeled
        res = inputImages.*thisCellDilateCopy;
        res = squeeze(sum(sum(res,2),1));
        % all cells above threshold are neighbors
        res = find(res>1);
        neighborsCell{c,1} = setdiff(res,c);

        % reduce waitbar access
        if mod(c,7)==0|c==nSignals
            reverseStr = cmdWaitbar(c,nSignals,reverseStr,'inputStr','identifying neighboring cells');
        end
        keyIn = get(gcf,'CurrentCharacter');
        if strcmp(keyIn,'f')%user wants to exit
            set(gcf,'currentch','3');drawnow;
            keyIn = get(gcf,'CurrentCharacter');
            break
        end
    end

    if plottingOn
        viewNeighborsAuto(inputImages, inputSignals, neighborsCell);
    end