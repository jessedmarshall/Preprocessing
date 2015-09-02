function [theseActiveTimes, neighborsActiveOk] = findBestActiveTimes(cInd, singleCellActiveTimes, activeTimes, minNumActiveTimes, maxNumActiveTimes, neighbors, thisf, noiseSigma)

method1=0;

%disp(['Cell ' num2str(cInd) ' had ' num2str(sum(activeTimes(cInd,:))) ' active times before excluding negative neighbor times'])
activeTimesBefore = num2str(sum(activeTimes(cInd,:)));

if ~method1
    
    minVal=-3*noiseSigma;
    neighborsNegativeTimes=sum(thisf(neighbors{cInd},:)<minVal,1)>0;
    singleCellActiveTimes(cInd,logical(neighborsNegativeTimes))=0;
    activeTimes(cInd,logical(neighborsNegativeTimes))=0;
    
    %disp(['Cell ' num2str(cInd) ' had ' num2str(sum(activeTimes(cInd,:))) ' active times after excluding negative neighbor times'])
    activeTimesAfter = num2str(sum(activeTimes(cInd,:)));
   

    neighborsActiveOk=0;
    if sum(singleCellActiveTimes(cInd,:))>minNumActiveTimes
        % if there are more than the min number of single cell active
        % times, find the times with the highest difference between self
        % and neighbors
        theseActiveTimes=find(singleCellActiveTimes(cInd,:));
        nActiveTimes=min(length(theseActiveTimes), maxNumActiveTimes);
        %disp(['single ok. nActiveTimes=' num2str(nActiveTimes)])
    else
        % if there are fewer than the min number of single cell active
        % times, find the times with the highest difference between self
        % and neighbors
        neighborsActiveOk=1;
        theseActiveTimes=find(activeTimes(cInd,:));
        nActiveTimes=min(length(theseActiveTimes), minNumActiveTimes);
        %disp(['no single. nActiveTimes=' num2str(nActiveTimes)])
    end
    fValsWhenActive=thisf(cInd,theseActiveTimes);
    neighborfValsWhenActive=thisf(neighbors{cInd},theseActiveTimes);
    meanNeighborVals=mean(neighborfValsWhenActive,1);
    meanNeighborDiffs=fValsWhenActive-meanNeighborVals;
    [~, sortedTimeInds]=sort(meanNeighborDiffs,'descend');
    theseActiveTimes=theseActiveTimes(sortedTimeInds(1:nActiveTimes));
    
        %disp([activeTimesBefore ' ' activeTimesAfter ' ' num2str(nActiveTimes)])
    
    clear fValsWhenActive sortedTimeInds meanNeighborDiffs meanNeighborVals neighborfValsWhenActive nActiveTimes

else
    neighborsActiveOk=0;
    if sum(singleCellActiveTimes(cInd,:))>minNumActiveTimes
        % find only the strongest active times, if there are more than the
        % minimum
        theseActiveTimes=find(singleCellActiveTimes(cInd,:));
        nActiveTimes=min(length(theseActiveTimes), maxNumActiveTimes);
        fValsWhenActive=thisf(cInd,theseActiveTimes);
        [~, sortedTimeInds]=sort(fValsWhenActive,'descend');
        theseActiveTimes=theseActiveTimes(sortedTimeInds(1:nActiveTimes));
        clear fValsWhenActive sortedTimeInds
    else
        neighborsActiveOk=1;
        theseActiveTimes=find(activeTimes(cInd,:));
        numNeighborsActiveAtTime=sum(activeTimes(neighbors{cInd},theseActiveTimes),1);
        if length(theseActiveTimes)>minNumActiveTimes
            [numNeighborsActiveAtTime, sortedTimeInds]=sort(numNeighborsActiveAtTime,'ascend');
            if numNeighborsActiveAtTime(minNumActiveTimes)>3
                sortedTimeInds(numNeighborsActiveAtTime>3)=[];
                theseActiveTimes=theseActiveTimes(sortedTimeInds);
            else
                theseActiveTimes=theseActiveTimes(sortedTimeInds(1:minNumActiveTimes));
            end
        else
            theseActiveTimes(numNeighborsActiveAtTime>3)=[];
        end
        clear numNeighborsActiveAtTime sortedTimeInds
    end
end

% if neighborsActiveOk
%     disp(['Cell ' num2str(cInd) ' has ' num2str(length(theseActiveTimes)) ' active times, neighbors active ok'])
% else
%     disp(['Cell ' num2str(cInd) ' has ' num2str(length(theseActiveTimes)) ' active times, neighbors active ok'])
% end