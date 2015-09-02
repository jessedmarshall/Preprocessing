function [eventTimes, eventsCell] = detectEvents2(cellTraces, varargin)

% This version of batch event detection uses's Maggie's version of event
%   detection, which calculates the std dev of each trace separately
% It doesn't allow varying the options from default right now, since the
%   options structures are different

nCells=size(cellTraces,1);
eventsCell=cell(nCells,1);
eventTimes=cell(nCells,1);

for cInd=1:nCells
    eventsCell{cInd}=detectBursts(cellTraces(cInd,:));
    eventTimes{cInd}=eventsCell{cInd}.peakind;
end
