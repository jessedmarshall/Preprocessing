function trialTraceData = extractTraceData(SpikeTraceData)
trialLen = size(SpikeTraceData(1,1).Trace,1);
numCells = size(SpikeTraceData,2);
trialTraceData = zeros(numCells,trialLen);
for i=1:numCells
    trialTraceData(i,:)=SpikeTraceData(1,i).Trace;
end