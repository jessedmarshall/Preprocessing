function lookAtEvents(nFramesByTrial, xPositionsResamp, yPositionsResamp, positionVecs, eventTimes)

nFramesTotal=sum(nFramesByTrial);
allPositions=zeros(nFramesTotal,1);
allXPositions=zeros(nFramesTotal,1);
allYPositions=zeros(nFramesTotal,1);
frInd=0;
for trInd=1:length(positionVecs)
    nFrames=length(positionVecs{trInd});
    allPositions(frInd+(1:nFrames))=positionVecs{trInd};
    allXPositions(frInd+(1:nFrames))=xPositionsResamp{trInd};
    allYPositions(frInd+(1:nFrames))=yPositionsResamp{trInd};
    frInd=frInd+nFrames;
    allXPositions(frInd)=nan;
    allYPositions(frInd)=nan;
end

for cInd=1:length(eventTimes)
    figure(5)
    plot(allPositions, 'k')
    hold on
    plot(eventTimes{cInd}, allPositions(eventTimes{cInd}), 'r.', 'Markersize', 20)
    hold off
    
    figure(1)
    plot(allXPositions,allYPositions, 'k')
    hold on
    plot(allXPositions(eventTimes{cInd}), allYPositions(eventTimes{cInd}), 'r.', 'Markersize', 20);
    waitforbuttonpress
    hold off
end
