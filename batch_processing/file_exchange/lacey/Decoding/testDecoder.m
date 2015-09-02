function [decodedPos, logProbOfPos, allLogProb] = testDecoder(eventMatrix, decodingStruct)

%%% Written by Lacey Kitch in 2012-2014

%%% INPUTS
% eventMatrix : binary neuron event timings.
%       - Binary (logical or single or double) matrix indicating eventTimes.
%       Size is [nFrames nCells], and entry is 1 at one time point for each
%       event, and 0 otherwise.
%       - NOTE: often bayesian decoding with imaging data requires the use
%       of past bursting information as features. In this case
%       (non-instantaneous decoding), one needs to include these features
%       in eventMatrix. Use makeDecodingMatrices function to do this, or use
%       crossValidateDecoder to avoid the hassle of calculating it
%       yourself.
% decodingStruct : output from trainDecoder. Structure containing all parts
%   of the constructed Bayesian decoder as described in 
%   Ziv et. al., Nature Neuroscience 2013. (Lacey Kitch)

%%% OUTPUTS

% decodedPos : decoded binned position. Range is from 1 to
%   maximum bin number, and bins match position input into trainDecoder.
%       - Vector containing binned position information for the same
%       time period as eventMatrix. Size is [nFrames 1] or [1 nFrames].
% lodProbOfPos : log probability of each positional bin at each timepoint.
%   decodedPos is the bin where logProbOfPos is maximal at each timepoint.



numTestPoints=size(eventMatrix,1);
decodedPos=zeros(1,numTestPoints);
logProbOfPos=zeros(1,numTestPoints);

logProb1givenPos=decodingStruct.logProb1givenPos;
logProb0givenPos=decodingStruct.logProb0givenPos;
logProbPos=decodingStruct.logProbPos;
logProbX1=decodingStruct.logProbX1;
logProbX0=decodingStruct.logProbX0;

posValues=1:length(logProbPos);
allLogProb=zeros(numTestPoints, length(logProbPos));
for posInd=posValues
    allLogProb(:,posInd)=eventMatrix*logProb1givenPos(posInd,:)'+...
        (1-eventMatrix)*logProb0givenPos(posInd,:)'+...
        logProbPos(posInd)-(eventMatrix*logProbX1'+(1-eventMatrix)*logProbX0');
end

for posInd=1:length(decodedPos)
    [maxLogProb,maxInd]=max(allLogProb(posInd,:));
    decodedPos(posInd)=maxInd;
    logProbOfPos(posInd)=maxLogProb;
end