function [badCellsManual, maybeCellsManual, splitCellsManual] = manualClassifyCells(eventTrigImages, cvxHulls, allCellTraces, allCellParams, eventTimes)

% Written by Lacey Kitch in 2014

framesToShow=1000;

% get cell neighbors
imgSize=size(eventTrigImages(:,:,1));
cellImgs=calcCellImgs(allCellParams, imgSize);
[neighbors, ~] = getCellNeighbors(cellImgs);

% initialize variables
nCells=size(allCellTraces,1);
badCellsManual=zeros(1,nCells);
nBadCells=0;
maybeCellsManual=zeros(1,nCells);
nMaybeCells=0;
splitCellsManual=zeros(1,nCells);
nSplitCells=0;
nFrames=size(allCellTraces,2);
if nFrames>framesToShow
    segments=1:framesToShow:nFrames;
    segments(end+1)=nFrames;
else
    segments=[1 nFrames];
end
thisEventsPerSeg=zeros(1,length(segments)-1);


% loop through cells
h=figure(121);
for cInd=1:nCells
    if ~isempty(eventTimes{cInd})   % skip cells with no events - these are automatic no
        set(h, 'CurrentCharacter', 'k');

        % find the most active time period, and show it next
        if nFrames>framesToShow
            for segInd=1:length(segments)-1
                thisEventsPerSeg(segInd)=sum(and(eventTimes{cInd}>=segments(segInd),...
                    eventTimes{cInd}<segments(segInd+1)));
            end
        end
        [~,maxSeg]=max(thisEventsPerSeg);
        firstTimeToShow=segments(maxSeg);
        lastTimeToShow=segments(maxSeg+1);
        currentSeg=maxSeg;

        % get region of image to show


        % now get user input and loop until a decision is made
        firstLoop=1;
        while ~(strcmp(get(h, 'CurrentCharacter'), 'y') || strcmp(get(h, 'CurrentCharacter'), 'n')...
                || strcmp(get(h, 'CurrentCharacter'), 'm') || strcmp(get(h, 'CurrentCharacter'), 's'))

            % plot image and trace
            if firstLoop
                figure(h); imgAx=subplot(4,1,1:3); hold off; %#ok<NASGU>
                imagesc(eventTrigImages(:,:,cInd)); hold on;
                for neighInd=1:length(neighbors{cInd})
                    ncInd=neighbors{cInd}(neighInd);
                    plot(cvxHulls{ncInd}(:,1), cvxHulls{ncInd}(:,2), 'w', 'Linewidth', 1.5)
                end
                plot(cvxHulls{cInd}(:,1), cvxHulls{cInd}(:,2), 'k', 'Linewidth', 1.5)

                traceAx=subplot(4,1,4); hold off;
                plot(allCellTraces(cInd,:)); ylim([-0.02, 0.2]); hold on;
                plot(eventTimes{cInd},allCellTraces(cInd,eventTimes{cInd}), 'k.')
                xlim(traceAx,[firstTimeToShow lastTimeToShow])

                suptitle('Cell? y/n/m/s | f: fwd in time trace | b: back in time trace')
                firstLoop=0;
            end

            % get user input
            waitforbuttonpress();
            if strcmp(get(h, 'CurrentCharacter'),'f')
                currentSeg=currentSeg+1;
                currentSeg=min(currentSeg,length(segments)-1);
                xlim(traceAx,[segments(currentSeg) segments(currentSeg+1)])
            elseif strcmp(get(h, 'CurrentCharacter'),'b')
                currentSeg=currentSeg-1;
                currentSeg=max(currentSeg,1);
                xlim(traceAx,[segments(currentSeg) segments(currentSeg+1)])
            elseif strcmp(get(h, 'CurrentCharacter'), 'z')
                leftLim = max(min(cvxHulls{cInd}(:,1))-20,1);
                rightLim = min(max(cvxHulls{cInd}(:,1))+20,imgSize(2));
                topLim = max(min(cvxHulls{cInd}(:,2))-20,1);
                bottomLim = min(max(cvxHulls{cInd}(:,2))+20,imgSize(1));
                xlim(imgAx, [leftLim, rightLim])
                ylim(imgAx, [topLim, bottomLim])
            end
        end

        % save classification
        if strcmp(get(h, 'CurrentCharacter'), 'n')
            nBadCells=nBadCells+1;
            badCellsManual(nBadCells)=cInd;
        elseif strcmp(get(h, 'CurrentCharacter'), 'm')
            nMaybeCells=nMaybeCells+1;
            maybeCellsManual(nMaybeCells)=cInd;
        elseif strcmp(get(h, 'CurrentCharacter'), 's')
            nSplitCells=nSplitCells+1;
            splitCellsManual(nSplitCells)=cInd;    
        elseif ~strcmp(get(h, 'CurrentCharacter'), 'y')
            warning('Something went wrong in manual classification')
        end
    else
        nBadCells=nBadCells+1;
        badCellsManual(nBadCells)=cInd;
    end
end
badCellsManual=badCellsManual(1:nBadCells);
maybeCellsManual=maybeCellsManual(1:nMaybeCells);
splitCellsManual=splitCellsManual(1:nSplitCells);

