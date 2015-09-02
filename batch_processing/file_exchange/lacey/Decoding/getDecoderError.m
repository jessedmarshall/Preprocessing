function [meanError, medianError, allErrors] = getDecoderError(decodedPos, truePos, nBinsPerArm)

d = getRAMbinDistances(nBinsPerArm);


allErrors=zeros(1,length(decodedPos));
for fr=1:length(decodedPos)
    allErrors(fr)=d(decodedPos(fr),truePos(fr));
end

meanError=mean(allErrors);
medianError=median(allErrors);