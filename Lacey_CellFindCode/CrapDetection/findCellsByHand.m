function [cellROIs, currentFrame] = findCellsByHand(dsImgs, xLims, yLims, varargin)

cellROIs=cell(2000,1);
currentFrame=1;
currentCellInd=0;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'cellROIs')
        nROIs=length(options.cellROIs);
        cellROIs(1:nROIs)=options.cellROIs;
        for cInd=1:length(cellROIs)
            if ~isfield(cellROIs{cInd}, 'unsure')
                cellROIs{cInd}.unsure=0;
            end
        end
        disp(['Loaded in ' num2str(nROIs) ' cell ROIs'])
        currentCellInd=nROIs;
        clear nROIs
    end
    
    if isfield(options, 'currentFrame')
        currentFrame=options.currentFrame;
    end
end

nFrames=size(dsImgs,3);

maxVals=max(dsImgs,[],3);
minVals=min(dsImgs,[],3);
CLimBottom=prctile(minVals(:),50);
CLimTop=prctile(maxVals(:),99);
clims=[CLimBottom CLimTop];
h=figure(21);
g=figure(17);
notDone=1;
maxImgMode=1;
nFrMax=20;
while notDone
    if maxImgMode
        thisMaxImg=max(dsImgs(:,:,currentFrame:min(currentFrame+nFrMax,nFrames)),[],3);
        hAx=displayFrameWithCells(h,thisMaxImg,1,cellROIs,currentCellInd,xLims,yLims,clims);
        xlabel(['Frame ' num2str(currentFrame)])
    else
        hAx=displayFrameWithCells(h, dsImgs,currentFrame,cellROIs,currentCellInd,xLims,yLims,clims);
    end
    k=waitforbuttonpress();
    % get current character
    % compare to options: forward, back, roi (if click), delete roi (if
    % backspace)...
    if ~k
        % if mouse click, draw an roi
        try
            currentCellInd=currentCellInd+1;
            thisCellEllipse=imellipse(hAx);
            thisBorder=thisCellEllipse.getVertices();
            thisMask=thisCellEllipse.createMask();
            info=regionprops(thisMask, 'Centroid');
            thisCentroid=info.Centroid;
            thisMask=sparse(thisMask);
            cellROIs{currentCellInd}.border=thisBorder;
            cellROIs{currentCellInd}.mask=thisMask;
            cellROIs{currentCellInd}.centroid=thisCentroid;
            cellROIs{currentCellInd}.foundFrame=currentFrame;
            cellROIs{currentCellInd}.unsure=0;
        catch
            disp('That did not work, try again? :)')
            currentCellInd=currentCellInd-1;
        end
    else
        switch get(h, 'CurrentCharacter')
            case 'd'
                % delete a selected ROI
                foundCellInd=identifyFoundCell(h,cellROIs,currentCellInd);
                cellROIs=cellROIs([1:foundCellInd-1, foundCellInd+1:end]);
                currentCellInd=currentCellInd-1;
            case 'l'
                % move frame forward
                currentFrame=min(currentFrame+1,nFrames);
            case 'k'
                % move frame backward
                currentFrame=max(currentFrame-1,1);
            case 'o'
                % move frame forward 20 frames
                currentFrame=min(currentFrame+20,nFrames);
            case 'i'
                % move frame forward 20 frames
                currentFrame=max(currentFrame-20,1);
            case 'p'
                % play 20 frames from the current frame
                playMovieSnippet(h,dsImgs,currentFrame,20,cellROIs,currentCellInd,xLims,yLims,clims);
                if ~maxImgMode
                    currentFrame=thisFrame;
                end
            case 's'
                foundCellInd=identifyFoundCell(h,cellROIs,currentCellInd);
                cellROIs{foundCellInd}.unsure=mod(cellROIs{foundCellInd}.unsure+1,2);
            case 'c'
                % select an identified cell and replay its first
                % identification point in another window
                try 
                    foundCellInd=identifyFoundCell(h,cellROIs,currentCellInd);
                    foundFrame=cellROIs{foundCellInd}.foundFrame;
                    playFrame=playMovieSnippet(g,dsImgs,max(foundFrame-7,1),30,cellROIs,currentCellInd,xLims,yLims,clims);
                    displayFrameWithCells(g,max(dsImgs(:,:,foundFrame:playFrame),[],3),...
                        1,cellROIs,currentCellInd,xLims,yLims,clims);
                catch
                    disp('That did not work, try again? :)')
                end
            case 'q'
                % quit
                notDone=0;
            case 'm'
                maxImgMode=mod(maxImgMode+1,2);
        end
    end
end
cellROIs=cellROIs(1:currentCellInd);
