function [meanErrors, medianErrors, allErrors]=crossValidateDecoder_SameNumTrials(eventTimes, positionVecsBinned, nFramesByTrial, binSize, varargin)

% eventTimes is a 1xnCells cell with event times
% positionVecs is a 1xnTrials cell with binned position vector (starting at 1) for each trial
% nFramesByTrial is a 1xnTrials vector with the number of frames in that
%   trial

numTrialsTrain=10;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'numTrialsTrain')
        numTrialsTrain=options.numTrialsTrain;
    end
else
    options=[];
end

nTrials=length(nFramesByTrial);
numTrialsTrain=min(numTrialsTrain,nTrials-1);
nTestRuns=min(nchoosek(nTrials,numTrialsTrain),500);
nFramesTotal=sum(nFramesByTrial);
meanErrors=zeros(1,nTrials);
medianErrors=zeros(1,nTrials);
meanErrorsEachRun=zeros(nTestRuns,nTrials);
medianErrorsEachRun=zeros(nTestRuns,nTrials);

allDecPositions=zeros(nTestRuns,nFramesTotal);
allActualPositions=zeros(nTestRuns,nFramesTotal);
frameInd=0;
for testTrial=1:nTrials
    
    disp(['Test trial ' num2str(testTrial) ' of ' num2str(nTrials)])
    
    for testRunInd=1:nTestRuns
        
        trainTrials=randperm(nTrials,numTrialsTrain+1);
        trainTrials(trainTrials==testTrial)=[];
        trainTrials=trainTrials(1:numTrialsTrain);

        [trainEventMatrix,trainPositionVec]=makeMultitrialDecodingMatrices(eventTimes,...
            positionVecsBinned, trainTrials, nFramesByTrial, options);

        [testEventMatrix,testPositionVec]=makeMultitrialDecodingMatrices(eventTimes,...
            positionVecsBinned, testTrial, nFramesByTrial, options);

        decodingStruct = trainDecoder(trainEventMatrix, trainPositionVec);

        [decodedPos,~] = testDecoder(testEventMatrix, decodingStruct);

        allDecPositions(testRunInd,frameInd+(1:nFramesByTrial(testTrial)))=decodedPos;
        allActualPositions(testRunInd,frameInd+(1:nFramesByTrial(testTrial)))=testPositionVec;

        [meanErrorsEachRun(testRunInd,testTrial),medianErrorsEachRun(testRunInd,testTrial)] = getDecoderError(decodedPos, testPositionVec, ceil(37/binSize));
    end
    frameInd=frameInd+nFramesByTrial(testTrial);
    meanErrors(testTrial)=mean(meanErrorsEachRun(:,testTrial));
    medianErrors(testTrial)=mean(medianErrorsEachRun(:,testTrial));
end
[~,~,allErrors] = getDecoderError(allDecPositions(:),allActualPositions(:),floor(37/binSize));


% figure
% nBins=length(unique(allErrors));
% [errHist,errBins]=hist(allErrors,nBins+3);
% bar(errBins, errHist/sum(errHist))
% set(gca, 'Fontsize',14)
% xlabel('Decoder Error (cm)')
% ylabel('Fraction timepoints')