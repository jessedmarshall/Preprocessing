function eventTimes = convertEventMatToCell(eventMat)

%%% Written by Lacey Kitch in 2012-2014

nCells=size(eventMat,1);
% eventTimes=cell(nTrials,1);
for cInd=1:nCells

    eventTimes{cInd}=find(eventMat(cInd,:));

end