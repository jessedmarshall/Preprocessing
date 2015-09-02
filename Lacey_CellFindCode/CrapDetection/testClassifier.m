function [classifications, scores] = testClassifier(classifier, cellTraces, cellParams,...
    eventTrigImages, eventTimes, noiseSigmas, varargin)

haveFeatures=0;
useSVM=1;
useGLM=0;
if ~isempty(varargin)
    options=varargin{1};
    
    if isfield(options, 'featureValues')
        haveFeatures=1;
        featureValues=options.featureValues;
    end

    if isfield(options, 'useSVM')
        useSVM=options.useSVM;
        useGLM=~useSVM;
    end
    
else
    options=[];
end

if ~haveFeatures
    featureValues = calcFeatures(cellTraces, cellParams,...
        eventTrigImages, eventTimes, noiseSigmas);
end

if useSVM
    classifications = svmclassify(classifier.svmStruct, featureValues);
    svm = classifier.svmStruct;
    sv = svm.SupportVectors;
    alphaHat = svm.Alpha;
    bias = svm.Bias;
    kfun = svm.KernelFunction;
    kfunargs = svm.KernelFunctionArgs;
    scores = kfun(sv,featureValues,kfunargs{:})'*alphaHat(:) + bias;
elseif useGLM
    scores=glmval(classifier.B, featureValues, 'logit');
    classifications = round(scores);
end