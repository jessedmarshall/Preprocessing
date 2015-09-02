function positionVecs = binPositionVecs(positionVecs, binCenters)

for trInd=1:length(positionVecs)
    thisnFrames=length(positionVecs{trInd});
    for frInd=1:thisnFrames
        [~,binInd]=min(abs(positionVecs{trInd}(frInd)-binCenters));
        positionVecs{trInd}(frInd)=binInd;
    end
end