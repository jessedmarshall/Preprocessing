function [decodeErrors, decodeErrorsMed, spatialScaleVals, spatialScaleMax, spatialScaleMean] = decodeErrorVsSpatialScale(eventTimes, centroids, binnedPosition, nFramesByTrialDS, binSize, varargin)

numShuffles=1000;
numCells=50;

spatialScaleVals = 50:5:100; % these are radii

decodeErrors=zeros(numShuffles, length(spatialScaleVals));
decodeErrorsMed=decodeErrors;
spatialScaleMax=decodeErrors;
spatialScaleMean=decodeErrors;
numUniqueSets=zeros(length(spatialScaleVals),1);

maxY=max(centroids(:,2));
minY=min(centroids(:,2));
maxX=max(centroids(:,1));
minX=min(centroids(:,1));
radInd=0;
%unqInd=0;
for rad=spatialScaleVals
    radInd=radInd+1;
    %theseSets=cell(numShuffles,1);
    fprintf('Spatial scale: radius %d um \n', rad)
    for shufInd=1:numShuffles
        
        failed=1;
        numTries=0;
        
        while failed==1 && numTries<50
        
            thisX=rand*(maxX-minX-2*rad)+minX+rad;
            thisY=rand*(maxY-minY-2*rad)+minY+rad;

            validCells=find(and(centroids(:,1)>thisX-rad,...
                and(centroids(:,1)<thisX+rad,...
                and(centroids(:,2)>thisY-rad,...
                centroids(:,2)<thisY+rad))));

            if length(validCells)<numCells
                fprintf('Not enough cells. Radius is %d \n', rad)
                numTries=numTries+1;
                failed=1;
            else
                failed=0;
                
                theseInds=randperm(length(validCells),numCells);
                theseCells=validCells(theseInds);
%                 if unqInd>0
%                     notUnique
%                     for setInd=1:unqInd
%                         if length(intersect(theseCells, theseSets{setInd}))==length(theseCells)
%                             notUnique=1;
%                         end
%                     end
                
                theseDistances=pdist(centroids(theseCells,:));
                spatialScaleMax(shufInd,radInd)=max(theseDistances);
                spatialScaleMean(shufInd,radInd)=mean(theseDistances);

                decodeOptions.makeTrialPlots=0;
                decodeOptions.saveTrialPlots=0;
                decodeOptions.makeErrorHistogram=0;
                decodeOptions.numFramesBack=0;
                decodeOptions.smoothLength=6;
                [meanErrors, medianErrors, allErrors]=crossValidateDecoder(eventTimes(theseCells), binnedPosition, nFramesByTrialDS, binSize, 'options', decodeOptions);
                decodeErrors(shufInd,radInd)=mean(allErrors);
                decodeErrorsMed(shufInd,radInd)=mean(medianErrors);
            end
            if numTries>50
                disp('Failed 50 times.')
            end
        end
    end
end