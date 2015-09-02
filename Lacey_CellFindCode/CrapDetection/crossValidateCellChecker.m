function [falsePositiveRate, falseNegativeRate, accuracy, cvClassifications, featureValues] = crossValidateCellChecker(classifications, ...
    cellTraces, cellParams, eventTrigImages, eventTimes, noiseSigmas, varargin)

% Inputs:
% cellTraces, cellParams, eventTrigImages, eventTimes, and noiseSigma - can
%   either be double as output by EM, or can be cells wherein each entry
%   contains the traces/parameters/images etc. from a single dataset, to
%   allow for differently sized traces
% classifications - should be a vector with 1s for valid cells and 0s for
%   non-valid cells. if using multiple datasets, concatenate all datasets 
%   together in the same order that they are in for the parameter cell arrays.

suppressOutput=0;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'suppressOutput')
        suppressOutput=options.suppressOutput;
    end
else
    options=[];
end


% get the features for all the cells
if ~suppressOutput
    disp('Calculating Features...')
end
featureValues = calcFeaturesMultiDataset(cellTraces, cellParams,...
    eventTrigImages, eventTimes, noiseSigmas, options);

% initialize
numCrossVals=25;
nCellsTotal=size(featureValues,1);
cellsPerCrossVal=round(nCellsTotal/numCrossVals);
cvClassifications=zeros(1,nCellsTotal);
if size(classifications,1)>1
    classifications=classifications';
end


% perform cross validation
if ~suppressOutput
    disp('Cross Validating....')
end
for cvInd=1:numCrossVals
    if ~suppressOutput
        disp(['Chunk ' num2str(cvInd)])
    end
    
    % get training and testing indices
    if cvInd<numCrossVals
        theseTestInds=(cvInd-1)*cellsPerCrossVal + (1:cellsPerCrossVal);
    else
        theseTestInds=((cvInd-1)*cellsPerCrossVal+1):nCellsTotal;
    end
    theseTrainInds=1:nCellsTotal;
    theseTrainInds(theseTestInds)=[];

    % separate out training data, get features, train svm
    trainClassifications=classifications(theseTrainInds);
    trainFeatureValues=featureValues(theseTrainInds,:);
    
    if isfield(options, 'useNumEvents') && options.useNumEvents
        noEventCells=trainFeatureValues(:,1)==0;
        trainClassifications(noEventCells)=[];
        trainFeatureValues(noEventCells,:)=[];
    end
    options.featureValues=trainFeatureValues;
    [classifier, ~] = trainClassifier(trainClassifications,[],[],[],[],[],options);
    
    % re-test on training data and throw out borderline examples
    options.featureValues=trainFeatureValues;
    [~, scores] = testClassifier(classifier,[],[],[],[],[],options);
    borderlineCells=and(scores>-1.25, scores<0);
    trainClassifications(borderlineCells)=[];
    trainFeatureValues(borderlineCells,:)=[];
    
    % re-train classifier on non borderline examples
    options.featureValues=trainFeatureValues;
    [classifier, ~] = trainClassifier(trainClassifications,[],[],[],[],[],options);
    
    % separate out test data, get features, test svm
    testFeatureValues=featureValues(theseTestInds,:);
    options.featureValues=testFeatureValues;
    [theseClassifications,~] = testClassifier(classifier,[],[],[],[],[],options);
    
    if isfield(options, 'useNumEvents') && options.useNumEvents
        noEventCells=testFeatureValues(:,1)==0;
        theseClassifications(noEventCells)=0;
    end
    
    % store classifications
    cvClassifications(theseTestInds)=theseClassifications;

end

% get overall false positive and negative rates
falsePositives=and(cvClassifications==1, classifications==0);
falseNegatives=and(cvClassifications==0, classifications==1);
falsePositiveRate=sum(falsePositives)/sum(classifications==0);
falseNegativeRate=sum(falseNegatives)/sum(classifications==1);
accuracy=1-((sum(falsePositives)+sum(falseNegatives))/nCellsTotal);