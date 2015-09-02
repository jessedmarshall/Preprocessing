function fractionPeaksShared = calcFractionPeaksShared(allCellTraces, eventTimes, allCellParams)

nCells=length(eventTimes);
nFrames=size(allCellTraces,2);
eventBinMat=false(size(allCellTraces));
fractionPeaksShared=zeros(nCells,1);

for cInd=1:nCells
    eventBinMat(cInd,eventTimes{cInd})=1;
end

for cInd=1:nCells
    if ~isempty(eventTimes{cInd})
        thisCellX=allCellParams(cInd,1);
        thisCellY=allCellParams(cInd,2);
        thisCellNeigh=and(abs(allCellParams(:,1)-thisCellX)<10,...
            abs(allCellParams(:,2)-thisCellY)<10);
        thisCellNeigh(cInd)=0;
        peaksShared=0;
        for evInd=1:length(eventTimes{cInd})
            evTime=eventTimes{cInd}(evInd);
            selfPeakHeight=allCellTraces(cInd,evTime);
            neighHeight=allCellTraces(thisCellNeigh,evTime);
            if any(neighHeight(:)>selfPeakHeight)
                peaksShared=peaksShared+1;
            end
        end
        fractionPeaksShared(cInd)=peaksShared/length(eventTimes{cInd});
    end
end