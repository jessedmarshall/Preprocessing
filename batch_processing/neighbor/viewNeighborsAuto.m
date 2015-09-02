function viewNeighborsAuto(IcaFilters, IcaTraces, neighborsCell, varargin)
    % view the neighboring cells, their traces and trace correlations
    % biafra ahanonu
    % started 2013.11.01
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
    %     eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    cellmap = createObjMap(IcaFilters);
    % cell vector info
    cellvec(1) = 1;
    cellvec(2) = size(IcaFilters,1);
    valid = zeros(1,cellvec(2));

    openFigure(21,'full')
    subplot(2,3,3)
    imagesc(cellmap)
    % axis image
    % axis off ij square
    colormap gray;title(['cellmap']);hold on

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

    exitLoop = 0;
    nCells = cellvec(2);
    cellnum = 1;

    % instructions
    instructionStr =  ' | down:bad | up:good | f:finished | g:(goto IC) | s:(set remaining ICs to bad) | ICs are assumed good ';

    % reshape to (x,y,z) indexing for compatibility
    IcaFilters = permute(IcaFilters, [2 3 1]);
    while exitLoop==0
        directionOfNextChoice = 0;
        % bold green the main cell
            thisFilt = squeeze(IcaFilters(:,:,cellnum));
            set(mainCellHandle, 'AlphaData', thresholdImages(thisFilt)/4);
            neighborMap = createObjMap(permute(IcaFilters(:,:,neighborsCell{cellnum,1}),[3 1 2]));
            set(neighborCellHandle, 'AlphaData', neighborMap*2);
        % plot the traces
            subplot(2,3,[1:2 4:5])
            nList = [cellnum neighborsCell{cellnum,1}(:)'];
            plotSignalsGraph(IcaTraces, 'plotList', nList(:));
            title(instructionStr);
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
            colorbar; colormap jet;
            % colormap hot

            % imagesc(l);
            xlabel('cells');
            ylabel('cells');
            title(['#' num2str(cellnum) '/' num2str(nCells) ' correlations']);

        [x,y,reply]=ginput(1);
        [valid directionOfNextChoice exitLoop cellnum] = respondToUserInput(reply,cellnum,valid,directionOfNextChoice,exitLoop,nCells);

        % pause(0.001);
        cellnum=cellnum+directionOfNextChoice;
        % loop if user gets to either end
        if cellnum<=0
            cellnum = nCells;
        elseif i>nCells;
            cellnum = 1;
        end
    end

    % [x,y] = findCentroid(thisFilt);
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


function [valid directionOfNextChoice exitLoop i] = respondToUserInput(reply,i,valid,directionOfNextChoice,exitLoop,nCells)
    % decide what to do based on input (not a switch due to multiple comparisons)
    if isequal(reply, 3)|isequal(reply, 110)|isequal(reply, 31)
        % n key or right click
        directionOfNextChoice=1;
        % display('invalid IC');
        % set(fig1,'Color',[0.8 0 0]);
        valid(i) = 0;
    elseif isequal(reply, 28)
        % go back, left
        directionOfNextChoice=-1;
    elseif isequal(reply, 29)
        % go forward, right
        directionOfNextChoice=1;
    elseif isequal(reply, 102)
        exitLoop=1;
        % user clicked 'f' for finished, exit loop
        % i=nCells+1;
    elseif isequal(reply, 103)
        % if user clicks 'g' for goto, ask for which IC they want to see
        icChange = inputdlg('enter IC #'); icChange = str2num(icChange{1});
        if icChange>nCells|icChange<1
            % do nothing, invalid command
        else
            i = icChange;
            directionOfNextChoice = 0;
        end
    elseif isequal(reply, 115)
        % 's' if user wants to get ride of the rest of the ICs
        display(['classifying the following ICs as bad: ' num2str(i) ':' num2str(nCells)])
        valid(i:nCells) = 0;
        exitLoop=1;
    elseif isequal(reply, 121)|isequal(reply, 1)|isequal(reply, 30)
        % y key or left click
        directionOfNextChoice=1;
        % display('valid IC');
        % set(fig1,'Color',[0 0.8 0]);
        valid(i) = 1;
    else
        % forward=1;
        % valid(i) = 1;
    end