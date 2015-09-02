function neighborsCell = identifyNeighborsAuto(IcaFilters, IcaTraces, varargin)
% laurie burns, sept 2010.

% biafra ahanonu
% updated starting 2013.11.01
% refactored so accepts ICA filters and traces as input, also changed display to it matches ICAchooser, e.g. it applies a cellmap along with the identified and new cells

% this code automatically sorts through to find all cell neighbors within a certain distance of the target (boundary to boundary). the output is a cell with the vector of the neighbor indices in the target cell's entry.

% options
options.plottingOn = 1;
options.overlapradius = 10;
% get options
options = getOptions(options,varargin);
% unpack options into current workspace
fn=fieldnames(options);
for i=1:length(fn)
    eval([fn{i} '=options.' fn{i} ';']);
end

% cell vector info
cellvec(1) = 1;
cellvec(2) = size(IcaFilters,1);

%% look for overlap of IC and dilated IC
neighborsCell=cell(cellvec(2),1);
se = strel('disk',overlapradius,0);
cellmap = createCellMap(IcaFilters);
% reshape to (x,y,z) indexing for compatibility
IcaFilters = permute(IcaFilters, [2 3 1]);
% threshold ICs
waitbarHandle = waitbar(0, 'thresholding filters...');
for iFilt = 1:size(IcaFilters,3)
    if(mod(iFilt,3)==0)
        waitbar(iFilt/size(IcaFilters,3),waitbarHandle)
    end
    IcaFilters(:,:,iFilt) = thresholdICs(IcaFilters(:,:,iFilt));
end
close(waitbarHandle);

waitbarHandle = waitbar(0, 'identifying neighboring cells...');
for c = 1:cellvec(2)
    % get a dilated version of the thresholded image
    thisCellDilateCopy = repmat(imdilate(squeeze(IcaFilters(:,:,c)),se),[1 1 size(IcaFilters,3)]);
    % thisCellDilateCopy = permute(thisCellDilateCopy, [3 1 2]);
    % matrix multiple, any overlap will be labeled
    res = IcaFilters.*thisCellDilateCopy;
    res = squeeze(sum(sum(res,2),1));
    % all cells above threshold are neighbors
    res = find(res>1);
    neighborsCell{c,1} = setdiff(res,c);

    % reduce waitbar access
    if(mod(c,3)==0)
        waitbar(c/cellvec(2),waitbarHandle)
    end
end
close(waitbarHandle);

%% if want to plot it
if plottingOn
    openFigure(21,'full')
    subplot(2,3,3)
    imagesc(cellmap)
    axis image
    % axis off ij square
    colormap gray
    title(['cellmap']);
    hold on

    % make a green image overlayed
    green = cat(3, zeros(size(cellmap)), ones(size(cellmap)), zeros(size(cellmap)));
    red = cat(3, ones(size(cellmap)), zeros(size(cellmap)), zeros(size(cellmap)));
    hold on
    mainCellHandle = imshow(green);
    neighborCellHandle = imshow(red);
    % hold off

    % hold on
    % for c=1:size(IcaFilters,1)
    %     % contour(gaussblur(IcaFilters(c,:,:),2),1)
    %     [x,y] = findCentroid(squeeze(IcaFilters(c,:,:)));
    %     text(x-2,y,num2str(c),'fontsize',10)
    % end
    % clear c x y

    for cellnum = cellvec(1):cellvec(2)
        % bold green the main cell
            thisFilt = squeeze(IcaFilters(:,:,cellnum));
            [x,y] = findCentroid(thisFilt);
            set(mainCellHandle, 'AlphaData', thresholdICs(thisFilt)/4);
            % hmain = text(x-2,y,num2str(cellnum),'fontsize',10,'fontweight','bold','color','r');
            %     handle_array = cell(10,1);
            % handle_array = [];

            % for d = 1:length(neighborsCell{cellnum,1})
            %     %         counter = counter + 1;
            %     c = neighborsCell{cellnum,1}(d);
            %     thisNeighborFilt = squeeze(IcaFilters(c,:,:));
            %     [x,y] = findCentroid(thisNeighborFilt);
            %     h = text(x-2,y,num2str(c),'fontsize',10,...
            %         'fontweight','bold','color','b');
            %     handle_array{d,1} = h;
            %     %             neighborVector = cat(1,neighborVector,c);
            %     %         end
            % end
            neighborMap = createCellMap(permute(IcaFilters(:,:,neighborsCell{cellnum,1}),[3 1 2]));
            set(neighborCellHandle, 'AlphaData', neighborMap*2);
        % plot the traces
            subplot(2,3,[1:2 4:5])
            nList = [cellnum neighborsCell{cellnum,1}(:)'];
            plotIcaTraces(IcaTraces, nList(:));
        % plot correlations
            subplot(2,3,6)
            % check if two IC traces have correlation
            % l=corrcoef(IcaTraces(nList(:),:)');
            % check neighbor correlation
            z=xcorr(IcaTraces(nList(:),:)');
            z0 = zeros(size(IcaTraces(nList(:),:)',2));
            zMax = max(z);
            z0 = reshape(zMax, [size(z0)]);
            imagesc(z0)
            colorbar
            % colormap hot

            % imagesc(l);
            xlabel('cells');
            ylabel('cells');
            title(['correlations for neighbors of cell#' num2str(cellnum)]);

        % imagesc(neighborMap*2);
        %     neighborsCell{cellnum,1} = neighborVector;
        pause()
        % delete(hmain);
        % for hnum = 1:length(handle_array)
        %     delete(handle_array{hnum,1})
        % end
    end
end