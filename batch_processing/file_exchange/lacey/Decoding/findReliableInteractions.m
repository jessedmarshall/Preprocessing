function [newEventMat, indsRIs, occRIs] = findReliableInteractions(eventMatrix)

nFrames=size(eventMatrix,2);
nCells=size(eventMatrix,1);

numEvents=sum(eventMatrix,1);

maxNumEvents=max(numEvents);

occRIs=cell(maxNumEvents,1); % cell of arrays holding counts of the RIs
indsRIs=cell(maxNumEvents,1); % cell of arrays holding indices of the RIs
matIndsRIs=cell(maxNumEvents,1); % cell of arrays holding indices into the new cell event mat, of the RIs
newEventMat=[eventMatrix; nan(1000,nFrames)];
lastNewMatInd=nCells;

for sizeRI=2:maxNumEvents
    
    activeTimes=find(numEvents>=sizeRI);
    
    guessMaxNumRIs=min(round((nCells/20)^sizeRI),10^5);
    indsRIs{sizeRI}=zeros(guessMaxNumRIs,sizeRI);
    occRIs{sizeRI}=zeros(guessMaxNumRIs,1);
    matIndsRIs{sizeRI}=zeros(guessMaxNumRIs,1);
    lastRIind=0;
    
    for t=activeTimes
        
        cellCombos = combntns(find(eventMatrix(:,t)>0),sizeRI);
        cellCombos = sort(cellCombos, 2);
        
        for comboInd=1:size(cellCombos,1)
            
            [bool, loc] = ismember(cellCombos(comboInd,:), indsRIs{sizeRI}, 'rows');
            if bool
                occRIs{sizeRI}(loc)=occRIs{sizeRI}(loc)+1;
                if occRIs{sizeRI}(loc)==3
                    lastNewMatInd=lastNewMatInd+1;
                    matIndsRIs{sizeRI}(loc)=lastNewMatInd;
                    newEventMat(lastNewMatInd,:)=0;
                    newEventMat(lastNewMatInd,t)=1;
                elseif occRIs{sizeRI}(loc)>3
                    newEventMat(matIndsRIs{sizeRI}(loc),t)=1;
                end
            else
                lastRIind=lastRIind+1;
                indsRIs{sizeRI}(lastRIind,:)=cellCombos(comboInd,:);
                occRIs{sizeRI}(lastRIind)=1;
            end

        end
    end
    indsRIs{sizeRI}=indsRIs{sizeRI}(1:lastRIind,:);
    occRIs{sizeRI}=occRIs{sizeRI}(1:lastRIind);
    
end

newEventMat(sum(isnan(newEventMat),2)==nFrames,:)=[];
