function [eventMatrix, positionVec] = makeDecodingMatrices(eventTimes,...
    positionVec, numFramesBack, smoothLength)

%%% Written by Lacey Kitch in 2012-2014

%%% INPUTS
% eventTimes : neuron event timings.
%     eventTimes can have two possible structures:
%       - Cell array vector, size [1 nCells] or [nCells 1], where each entry
%       contains event times for that neuron. For example eventTimes{3}
%       contains a list of event times for neuron 3.
%       - Binary (logical or single or double) matrix indicating eventTimes.
%       Size is [nCells nFrames], and entry is 1 at one time point for each
%       event, and 0 otherwise.
% positionVec : Binned positional information. Range is from 1 to
%       maximum bin number. Vector containing binned position information
%       for all trials together. Size is [nFrames 1] or [1 nFrames].
% numFramesBack - number of past frames to use for decoding
%       features (uses past burst/event information, NOT past position
%       information, as described in Ziv et al 2013)
% smoothLength - number of frames that each burst is smoothed to
%       last for. smoothLength of 6 works well for 20hz movies on a linear
%       track.


%%% OUTPUTS
% eventMatrix : binary event/feature matrix for input into testDecoder and
%   trainDecoder
% positionVec : binned position vector properly aligned to eventMatrix, for
%   input into testDecoder and trainDecoder


if isa(eventTimes, 'double') || isa(eventTimes, 'single') || isa(eventTimes, 'logical')
    eventTimes = convertEventMatToCell(eventTimes);
end

nFrames=length(positionVec);
nCells=length(eventTimes);

eventMatrix=zeros(nFrames, nCells);
if nFrames>0 && nCells>0
    smoothVec=ones(1,smoothLength);
    for cInd=1:nCells
        thisEventTrace=zeros(1,nFrames);
        thisEventTrace(eventTimes{cInd})=1;
        eventMatrix(:,cInd)=conv(thisEventTrace, smoothVec, 'same');
    end
    eventMatrix(eventMatrix>1)=1;


    if size(positionVec,1)>1
        positionVec=positionVec';
    end
    [eventMatrix,positionVec]=getPastFutureMatrix(eventMatrix, positionVec, numFramesBack);

    eventMatrix=sparse(eventMatrix);  % time x numfeatures (cells*(pf+1))
end