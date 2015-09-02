function [meanErrors, stdErrors, medianErrors, quartileErrors, numCells] = decodeWithDifferentNumCells(eventTimes, binnedTrace, nFramesByTrial, binSize, varargin)

options.makeTrialPlots=0;
options.saveTrialPlots=0;
options.savePath=[];
options.makeErrorHistogram=0;
options.numFramesBack=0;
options.smoothLength=6;
options.numSteps=20;
options.numSamplings=10;
options.maxNum=100000;
options=getOptions(options, varargin);

nCellsTotal=length(eventTimes);
numCells=round(linspace(10,min(nCellsTotal, options.maxNum),options.numSteps));
meanErrors=zeros(length(numCells),options.numSamplings);
stdErrors=zeros(length(numCells),options.numSamplings);
medianErrors=zeros(length(numCells),options.numSamplings);
quartileErrors=zeros(length(numCells),options.numSamplings);
for nCellsInd=1:length(numCells)
    nCells=numCells(nCellsInd);
    disp(sprintf('nCells %d of %d', nCellsInd, length(numCells))) %#ok<DSPS>
    for sInd=1:options.numSamplings
        theseCells=randperm(nCellsTotal,nCells);
        [~,~,thisAllErrors]=crossValidateDecoder(eventTimes(theseCells), binnedTrace, nFramesByTrial, binSize, 'options', options);
        meanErrors(nCellsInd,sInd)=mean(thisAllErrors);
        stdErrors(nCellsInd,sInd)=std(thisAllErrors);
        medianErrors(nCellsInd,sInd)=median(thisAllErrors);
        quartileErrors(nCellsInd,sInd)=prctile(thisAllErrors,75)-prctile(thisAllErrors,25);
    end
end
