function frameToFit = getFrameToFit(icTrace, imgs, noiseSigma, nValsToUse)

highInds=find(icTrace>3*noiseSigma);

if length(highInds)>10
    nValsToUse=min(nValsToUse,length(highInds));
    icTrace=icTrace(highInds);
end

[~,sortedInds]=sort(icTrace, 'descend');

nValsToUse=min(min(length(highInds),nValsToUse),length(sortedInds));
sortedInds=highInds(sortedInds(1:nValsToUse));

frameToFit=mean(imgs(:,:,sortedInds),3);