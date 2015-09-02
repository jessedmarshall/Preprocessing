function [thisMuXInds, thisMuYInds, thisSigXInds, thisSigYInds, thisThetaInds]=...
    getParamInds(muXVals, muYVals, sigXVals, sigYVals, thetaVals,...
    thisMuX, thisMuY, thisSigX, thisSigY, thisTheta)

% Written by Lacey Kitch in 2013

nCells=size(muXVals,1);
thisMuXInds=zeros(1,nCells);
thisMuYInds=zeros(1,nCells);
thisSigXInds=zeros(1,nCells);
thisSigYInds=zeros(1,nCells);
thisThetaInds=zeros(1,nCells);
for cInd=1:nCells
    thisMuXInd=find(round(10000*muXVals(cInd,:))==round(10000*thisMuX(cInd)));
    thisMuYInd=find(round(10000*muYVals(cInd,:))==round(10000*thisMuY(cInd)));
    thisSigXInd=find(round(10000*sigXVals(cInd,:))==round(10000*thisSigX(cInd)));
    thisSigYInd=find(round(10000*sigYVals(cInd,:))==round(10000*thisSigY(cInd)));
    thisThetaInd=find(round(10000*thetaVals(cInd,:))==round(10000*thisTheta(cInd)));
    if isempty(thisMuXInd)
        thisMuXInds(cInd)=floor(nCells/2);
    else
        thisMuXInds(cInd)=thisMuXInd;
    end
    if isempty(thisMuYInd)
        thisMuYInds(cInd)=floor(nCells/2);
    else
        thisMuYInds(cInd)=thisMuYInd;
    end
    if isempty(thisSigXInd)
        thisSigXInds(cInd)=floor(nCells/2);
    else
        thisSigXInds(cInd)=thisSigXInd;
    end
    if isempty(thisSigYInd)
        thisSigYInds(cInd)=floor(nCells/2);
    else
        thisSigYInds(cInd)=thisSigYInd;
    end
    if isempty(thisThetaInd)
        thisThetaInds(cInd)=floor(nCells/2);
    else
        thisThetaInds(cInd)=thisThetaInd;
    end
end

% from file getParamInds on 12/12/13 at 11:39am