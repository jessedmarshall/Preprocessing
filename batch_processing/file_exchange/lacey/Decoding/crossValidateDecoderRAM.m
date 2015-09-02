function [meanErrors, medianErrors, allErrors, allDecPositions, allActualPositions,...
    logProbPos, decodingStruct, allEventMatrix]=crossValidateDecoderRAM(eventTimes, positionVecsBinned, nFramesByTrial, binSize, varargin)

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
% positionVecsBinned : binned positional information. Range is from 1 to
%   maximum bin number.
%     positionVecsBinned can have two possible structures:
%       - Cell array vector, size [1 nTrials] or [nTrials 1], with binned
%       position vectors in each trial entry. For example positionVecBinned{3}
%       contains a vector with binned position information for trial 3.
%       - Matrix containing binned position information for all trials
%       together. Size is [nFrames 1] or [1 nFrames].
% nFramesByTrial : vector with number of frames in each trial. if you use
%     2nd option for structure of eventTimes and positionVecs, and do not care
%     about trial structure, you can use any numbers in nFramesByTrial, as long
%     as they add up to total nFrames
% binSize : the size, in cm, of the position bins. This is just for error
%   reporting. Typical sizes are 3-10cm.
% options : options structure. Use input format crossValidateDecoder(... , 'options', options)
%    options.numFramesBack - number of past frames to use for decoding
%       features (uses past burst/event information, NOT past position
%       information, as described in Ziv et al 2013)
%    options.smoothLength - number of frames that each burst is smoothed to
%       last for. smoothLength of 6 works well for 20hz movies on a linear
%       track.

%%% OUTPUTS
% meanErrors : mean errors calculated for each trial, trained on the rest
%   of the trials
% medianErrors : median errors calculated for each trial, trained on the
%   rest of the trials
% all Errors : all of the cross validated errors, so that you can do your
%   own statistics

options.numFramesBack=8;
options.smoothLength=6;
options=getOptions(options, varargin);

if ~isa(positionVecsBinned, 'cell')
    positionVecsBinned=convertPosMatToCell(positionVecsBinned, nFramesByTrial);
end

if isa(eventTimes, 'double') || isa(eventTimes, 'single') || isa(eventTimes, 'logical')
    eventTimes = convertEventMatToCell(eventTimes);
end

nTrials=length(nFramesByTrial);
nFramesTotal=sum(nFramesByTrial);
meanErrors=zeros(1,nTrials);
medianErrors=zeros(1,nTrials);

allDecPositions=zeros(1,nFramesTotal);
allActualPositions=zeros(1,nFramesTotal);
frameInd=0;
for testTrial=1:nTrials
    
    trainTrials=1:nTrials;
    trainTrials(testTrial)=[];
    
    [trainEventMatrix,trainPositionVec]=makeMultitrialDecodingMatrices(eventTimes,...
        positionVecsBinned, trainTrials, nFramesByTrial, 'options', options);
    
    [testEventMatrix,testPositionVec]=makeMultitrialDecodingMatrices(eventTimes,...
        positionVecsBinned, testTrial, nFramesByTrial, 'options', options);
    
    decodingStruct = trainDecoder(trainEventMatrix, trainPositionVec);
    
    [decodedPos,~,thisLogProbPos] = testDecoder(testEventMatrix, decodingStruct);
    if testTrial==1
        logProbPos=zeros(size(thisLogProbPos,2),nFramesTotal);
    end
    
    allDecPositions(frameInd+(1:nFramesByTrial(testTrial)))=decodedPos;
    allActualPositions(frameInd+(1:nFramesByTrial(testTrial)))=testPositionVec;
    logProbPos(:,frameInd+(1:nFramesByTrial(testTrial)))=thisLogProbPos';
    frameInd=frameInd+nFramesByTrial(testTrial);
    
%    figure;
%     plot(testPositionVec*4, 'k', 'Linewidth',2)
%     hold on
%     plot(decodedPos*4, 'r.')
    

    [meanErrors(testTrial),medianErrors(testTrial)] = getDecoderError(decodedPos, testPositionVec, ceil(37/binSize));
end
[~,~,allErrors] = getDecoderError(allDecPositions,allActualPositions,ceil(37/binSize));


trainTrials=1:nTrials;

[allEventMatrix, trainPositionVec] = makeMultitrialDecodingMatrices(eventTimes,...
    positionVecsBinned, trainTrials, nFramesByTrial, 'options', options);
decodingStruct = trainDecoder(allEventMatrix, trainPositionVec);


% figure
% nBins=length(unique(allErrors));
% [errHist,errBins]=hist(allErrors,nBins+3);
% bar(errBins, errHist/sum(errHist))
% set(gca, 'Fontsize',14)
% xlabel('Decoder Error (cm)')
% ylabel('Fraction timepoints')