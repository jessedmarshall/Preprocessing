function [IcaFilters IcaTraces choices] = ICAchooser(IcaFilters,IcaTraces,inputID,nICs,varargin)
    % biafra ahanonu
    % started updated: 2013.10.08
    % based on code written by maggie carr
    %
    % inputs
        % IcaFilters
        % IcaTraces
        % inputID
        % nICs: number of ICs to choose
    %
    % changelog
        % updated: 2013.10.xx changed to ginput and altered UI to show more relevant information, now shows a cellmap overlayed with the current filter, etc.
        % updated: 2013.11.01 [15:48:56]
            % Finished removing all cell array indexing by day, increase maintainability.
            % Input is now filters and traces instead of loading a directory inside fxn (which is cryptic). Output is filtered traces.
            % Can now move forward AND back, 21st century stuff. Also changed some of the other controls to make UI more user friendly.
        % updated: 2013.11.03 [12:45:03] added a panel so that you can see the average trace around all spikes in an IC filter's trace along with several other improvements.
        % updated: 2013.11.04 [10:30:40] changed invalid subscripting to valid, previous way involved negating choices, prone to error.
        % updated: 2013.11.13 [09:25:24] added the ability to loop around and pre-maturely exit
    %--------------------------------------------------------------------------


    % set default options
    options.nICs = nICs;
    % get options
    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end

    % determine number of IC filters to investigate
    if isempty(nICs)
        nICs = size(IcaFilters,1);
    end

    % create a cell map to overlay current IC filter onto
    cellmap = createCellMap(IcaFilters);

    % remove small ICs
    [~, ~, valid] = removeSmallICs(IcaFilters, IcaTraces);
    nICs = size(IcaFilters,1);
    display(['#ICs: ' num2str(nICs)]);

    % Since 0=invalid, 1=valid, -1=unknown, set all '1' to unknown
    valid(find(valid==1)) = -1;
    % valid = ones(1,size(IcaFilters,1))*-1;
    choices = chooseICs(1:nICs, IcaFilters,IcaTraces,cellmap, valid);
    % assume all skips were good ICs that user forgot to enter
    valid = choices(find(choices==-1))==1;
    valid = find(valid);

    % get good traces
    IcaFilters = IcaFilters(valid,:,:);
    IcaTraces = IcaTraces(valid,:);

function [valid] = chooseICs(IClist, IcaFilters,IcaTraces,cellmap, valid)
    % updated: 2013.11.04 [10:36:22]

    sessionID = num2str(java.lang.System.currentTimeMillis);

    %Determine whether ICs are valid or invalid
    fig1 = openFigure(1,'full');

    % location of each subplot
    cellMapPlotLoc = 1;
    tracePlotLoc = [4:6];
    filterPlotLoc = 2;
    avgSpikeTracePlot = 3;
    subplotX = 3;
    subplotY = 2;
    % instructions
    instructionStr =  ': n|right-click|down-arrow = bad IC; y|left-click|up-arrow = good IC; f = finished; g = goto particular IC; if you do not disapprove of an IC, it is assumed good ';

    % plot the cell map to provide context
    subplot(subplotY,subplotX,cellMapPlotLoc)
    imagesc(cellmap); axis off; colormap gray;
    title(['cellmap']);
    hold on
    % make a green image overlayed
    green = cat(3, zeros(size(cellmap)), ones(size(cellmap)), zeros(size(cellmap)));
    filterOverlay = imshow(green);
    hold off

    lenICList = length(IClist);
    lenICFilts = size(IcaFilters,1);
    lenICTraces = size(IcaTraces,1);
    minValTraces = min(min(IcaTraces));
    if(minValTraces<-0.05)
        minValTraces = -0.05;
    end
    maxValTraces = max(max(IcaTraces));
    IcaFilters = IcaFilters(IClist,:,:);
    IcaTraces = IcaTraces(IClist,:);


    % start with low (good) rank ICs first
    i = 1;%size(IcaFilters,1);
    reply = 0;
    % loop over chosen filters
    nFilters = size(IcaFilters,1);
    % while i<=size(IcaFilters,1)
    while reply~=102
        % only exit if user clicks 'f' for finished
    % for i = 1:size(IcaFilters,1)
        figure(1);
        forward=1;
        thisFilt = squeeze(IcaFilters(i,:,:));
        thisTrace = IcaTraces(i,:);
        cellIDStr = ['#' num2str(i) '/' num2str(lenICTraces)];

        set(fig1,'Color',[1 1 1]);
        % use thresholded IC as AlphaData for the solid green image, overlay on cell map
            subplot(subplotY,subplotX,cellMapPlotLoc)
            set(filterOverlay, 'AlphaData', thresholdICs(thisFilt)/4);
        % show the current IC filter
            subplot(subplotY,subplotX,filterPlotLoc)
            imagesc(thisFilt);
            colormap gray
            axis off;
            % ij square
            % plot the average detected spike trace
            title(['IC ' cellIDStr])
            [testpeaks] = identifySpikes(thisTrace);
            if(~isempty(testpeaks))
                subplot(subplotY,subplotX,avgSpikeTracePlot);
                    spikeROI = [-40:40];
                    extractMatrix = bsxfun(@plus,testpeaks',spikeROI);
                    extractMatrix(extractMatrix<=0)=1;
                    extractMatrix(extractMatrix>=size(IcaTraces,2))=size(IcaTraces,2);
                    % extractMatrix
                    spikeCenterTrace = reshape(IcaTraces(i,extractMatrix),size(extractMatrix));
                    avgSpikeTrace = nanmean(spikeCenterTrace);
                    traceErr = nanstd(spikeCenterTrace)/sqrt(size(spikeCenterTrace,1));
                    %
                    % errorbar(spikeROI, avgSpikeTrace, traceErr);
                    % t=1:length(traceErr);
                    % fill([spikeROI fliplr(spikeROI)],[avgSpikeTrace+traceErr fliplr(avgSpikeTrace-traceErr)],[4 4 4]/8, 'FaceAlpha', 0.4, 'EdgeColor','none')
                    plot(repmat(spikeROI, [size(spikeCenterTrace,1) 1])', spikeCenterTrace','Color',[4 4 4]/8)
                    hold on;
                    plot(spikeROI, avgSpikeTrace,'k', 'LineWidth',3)
                    hold off;
                    title(['average trace around spikes for cell ' cellIDStr])
                    ylim([minValTraces max(max(spikeCenterTrace))]);
                    box off;

                subplot(subplotY,subplotX,tracePlotLoc)
                    plot(thisTrace, 'r');
                    hold on;
                    scatter(testpeaks, thisTrace(testpeaks), 'LineWidth',0.5,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0])
                    hold off;
                    title(['trace ' cellIDStr instructionStr])
                    axis([0 length(thisTrace) minValTraces maxValTraces]);
                    box off;
            end

        if valid(i)==1
            set(fig1,'Color',[0 0.8 0]);
        elseif valid(i)==0
            set(fig1,'Color',[0.8 0 0]);
        else
            set(fig1,'Color',[0.42 0.42 0.42]);
        end

        % get user input
        [x,y,reply]=ginput(1);
        % decide what to do based on input
        if isequal(reply, 3)|isequal(reply, 110)|isequal(reply, 31)
            % n key or right click
            forward=1;
            % display('invalid IC');
            % set(fig1,'Color',[0.8 0 0]);
            valid(i) = 0;
        elseif isequal(reply, 28)
            % go back, left
            forward=-1;
        elseif isequal(reply, 29)
            % go forward, right
            forward=1;
        elseif isequal(reply, 102)
            % user clicked 'f' for finished, exit loop
            % i=nFilters+1;
        elseif isequal(reply, 103)
            % if user clicks 'g' for goto, ask for which IC they want to see
            icChange = inputdlg('enter IC #'); icChange = str2num(icChange{1});
            if icChange>nFilters|icChange<1
                % do nothing, invalid command
            else
                i = icChange;
                forward = 0;
            end
        elseif isequal(reply, 121)|isequal(reply, 1)|isequal(reply, 30)
            % y key or left click
            forward=1;
            % display('valid IC');
            % set(fig1,'Color',[0 0.8 0]);
            valid(i) = 1;
        else
            forward=1;
            valid(i) = 1;
        end
        pause(0.001);
        % progress forward
        i=i+forward;
        % loop if user gets to either end
        if i<=0
            i = nFilters;
        elseif i>nFilters;
            i = 1;
        end
        figure(1);
        save(['tmpDecisions_' sessionID '.mat'],'valid');
    end