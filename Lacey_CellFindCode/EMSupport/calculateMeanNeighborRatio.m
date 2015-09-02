function [meanNeighborRatios, ratioToMeanNeighbor, meanNeighborDifference] = calculateMeanNeighborRatio(cInd, theseActiveTimes, neighbors, thisf)

meanNeighborRatios=zeros(1,length(theseActiveTimes));
ratioToMeanNeighbor=zeros(1,length(theseActiveTimes));
meanNeighborDifference=zeros(1,length(theseActiveTimes));

for timeInd=1:length(theseActiveTimes)
    
    activeTime=theseActiveTimes(timeInd);
    
    selfVal=thisf(cInd,activeTime);
    
    neighborVals=thisf(neighbors{cInd}, activeTime);
    neighborVals(neighborVals<0.0005)=0.0005;
    
    meanNeighborRatios(timeInd)=mean(selfVal*(1./neighborVals));
    
    meanNeighborDifference(timeInd)=mean(selfVal-neighborVals);
    
    ratioToMeanNeighbor(timeInd)=selfVal/mean(neighborVals);
   
end