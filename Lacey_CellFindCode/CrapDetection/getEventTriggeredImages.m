function eventTrigImages = getEventTriggeredImages(imgs, eventTimes, ...
    cellParams, varargin)

% Written by Lacey Kitch in 2014

maxNumEvents=10000;
if ~isempty(varargin)
    options=varargin{1};
    
    if isfield(options, 'maxNumEvents')
        maxNumEvents=options.maxNumEvents;
    end
end

nCells=size(eventTimes,1);
imgSize=size(imgs(:,:,1));
eventTrigImages=nan([imgSize,nCells]);
for cInd=1:nCells
    
    nEvents=length(eventTimes{cInd});
    
    if nEvents>0
        
        mux=cellParams(cInd,1);
        muy=cellParams(cInd,2);
        sigx=cellParams(cInd,3);
        sigy=cellParams(cInd,4);
        theta=cellParams(cInd,5);
        
        xWidth=max(sigx*cos(theta), sigy);
        xWidth=max(2.5*xWidth,4);
        yHeight=max(sigx*sin(theta), sigy);
        yHeight=max(2.5*yHeight,4);
        
        leftLim=max(round(mux-xWidth),1);
        rightLim=min(round(mux+xWidth),imgSize(2));
        topLim=max(round(muy-yHeight),1);
        bottomLim=min(round(muy+yHeight),imgSize(1));
        
        if nEvents>maxNumEvents
            eventImgMaxVals=zeros(1,nEvents);
            cellImg=calcCellImgs(cellParams(cInd,:), imgSize);
            binCellImg=cellImg;
            binCellImg(binCellImg<0.4*max(binCellImg(:)))=0;
            binCellImg(binCellImg>0)=1;
            binCellImg=logical(binCellImg);
            for evInd=1:nEvents
                thisFrame=imgs(:,:,eventTimes{cInd});
                thisCellInFrame=thisFrame(binCellImg);
                eventImgMaxVals(evInd)=max(thisCellInFrame(:));
            end
            [~,sortedInds]=sort(eventImgMaxVals,'descend');
            eventTimesToUse=eventTimes{cInd}(sortedInds(1:maxNumEvents));

        else
            eventTimesToUse=eventTimes{cInd};
        end
        eventTrigImages(topLim:bottomLim,leftLim:rightLim,cInd)=...
                mean(imgs(topLim:bottomLim,leftLim:rightLim,eventTimesToUse),3);
    end
end


