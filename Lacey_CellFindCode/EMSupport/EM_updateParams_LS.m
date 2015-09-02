function [thisMuX, thisMuY, thisSigX, thisSigY, thisTheta, changeParam, estTraces] =...
    EM_updateParams_LS(logLik,...
    thisMuX, thisMuY, thisSigX, thisSigY, thisTheta,...
    muXVals, muYVals, sigXVals, sigYVals, thetaVals,...
    imgs, varargin)

% Written by Lacey Kitch in 2013

if ~isempty(varargin)
	options=varargin{1};
else
	options=[];
end
    
% store old parameters and find most likely new parameters from logLik
oldMuX=thisMuX;
oldMuY=thisMuY;
oldSigX=thisSigX;
oldSigY=thisSigY;
oldTheta=thisTheta;
[~, muxInds]=max(logLik{1},[],2);
[~, muyInds]=max(logLik{2},[],2);
[~, sigxInds]=max(logLik{3},[],2);
[~, sigyInds]=max(logLik{4},[],2);
[~, thetaInds]=max(logLik{5},[],2);
nCells=length(thisMuX);
for cInd=1:nCells
    thisMuX(cInd)=muXVals(cInd,muxInds(cInd));
    thisMuY(cInd)=muYVals(cInd,muyInds(cInd));
    thisSigX(cInd)=sigXVals(cInd,sigxInds(cInd));
    thisSigY(cInd)=sigYVals(cInd,sigyInds(cInd));
    thisTheta(cInd)=thetaVals(cInd,thetaInds(cInd));
end


% calculate change in parameters as a fraction of the "unit" for that
% parameter:
%   1 pixel for centroids
%   0.5 pixel for widths
%   20 degrees for angle
changeParam=sum(abs(thisMuX-oldMuX))+...
        sum(abs(thisMuY-oldMuY))+...
        sum(abs(thisSigX-oldSigX)/0.5)+...
        sum(abs(thisSigY-oldSigY)/0.5)+...
        sum(abs(thisTheta-oldTheta)/(20*pi/180));   
% average over all cells and all 5 parameters
changeParam=changeParam/nCells/5;

% from file EM_updateParams_LS on 12/12/13 at 1:26pm


% calculate most likely traces given new shape parameters (uses LS, and
% does not recopy imgs, but uses slices of it
%imgSize=size(imgs(:,:,1));
%cellImgs=calcCellImgs([thisMuX, thisMuY, thisSigX, thisSigY, thisTheta], imgSize);
%estTraces=calculateTraces(cellImgs, imgs, options);
estTraces=[];
