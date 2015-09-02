function peakAsymmetries = calcPeakAsymmetries(allCellTraces, eventTimes, cellStdDevs)

nCells=size(allCellTraces,1);
peakAsymmetries=zeros(nCells,1);
for cInd=1:nCells
    thisTrace=allCellTraces(cInd,:);
    thisStd=cellStdDevs(cInd);
    peaksUsed=0;
    for evInd=1:length(eventTimes{cInd})
        evTime=eventTimes{cInd}(evInd);
        traceBefore=thisTrace(1:evTime);
        traceAfter=thisTrace(evTime+1:end);
        troughTime=find(traceBefore<thisStd, 1, 'last');
        peakTime=find(traceAfter<thisStd, 1, 'first')+evTime;
        if ~isempty(peakTime) && ~isempty(troughTime)
            peakAsymmetries(cInd)=peakAsymmetries(cInd)+peakTime-troughTime;
            peaksUsed=peaksUsed+1;
        end
    end
    if peaksUsed>0
        peakAsymmetries(cInd)=peakAsymmetries(cInd)/peaksUsed;
    end
end



        