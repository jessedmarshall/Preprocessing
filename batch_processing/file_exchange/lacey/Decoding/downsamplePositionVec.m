function dsBinnedTrace = downsamplePositionVec(binnedTrace, dsFactor)

nFrames=length(binnedTrace);
nFramesNew=ceil(nFrames/dsFactor);
dsBinnedTrace=zeros(nFramesNew,1);

for fr=1:nFramesNew
    minInd=(fr-1)*dsFactor+1;
    maxInd=min(fr*dsFactor,nFrames);
    dsBinnedTrace(fr)=round(mean(binnedTrace(minInd:maxInd)));
end