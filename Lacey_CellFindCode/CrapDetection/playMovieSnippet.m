function playFrame=playMovieSnippet(figHandle,imgs,startFrame,framesToShow, cellROIs,currentCellInd,xLims,yLims,clims)

nFrames=size(imgs,3);
playFrame=startFrame;
while playFrame<min(startFrame+framesToShow,nFrames)
    options.noTitle=1;
    displayFrameWithCells(figHandle,imgs,playFrame,cellROIs,currentCellInd,xLims,yLims,clims,options);
    playFrame=playFrame+1;
    pause(1/10)
end