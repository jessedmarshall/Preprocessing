function [classifier, featureValues] = trainClassifier(classifications, cellTraces, cellParams,...
    eventTrigImages, eventTimes, noiseSigmas, varargin)

haveFeatures=0;
useSVM=0;
useGLM=1;
C=1;
svmSig=1;
if ~isempty(varargin)
    options=varargin{1};
    
    if isfield(options, 'featureValues')
        haveFeatures=1;
        featureValues=options.featureValues;
    end
    
    if isfield(options, 'useSVM')
        useSVM=options.useSVM;
    end
    
    if isfield(options, 'C')
        C=options.C;
    end
    if isfield(options, 'svmSig')
        svmSig=options.svmSig;
    end
else
    options=[];
end

if ~haveFeatures
    disp('Calculating Features...')
    featureValues = calcFeaturesMultiDataset(cellTraces, cellParams,...
        eventTrigImages, eventTimes, noiseSigmas, options);
end

classifier=struct();

if useSVM
    SVMopts=[];
    SVMopts.MaxIter=10000000;
    classifier.svmStruct=svmtrain(featureValues,logical(classifications),...
        'kernel_function', 'rbf', 'autoscale', 'false', 'rbf_sigma', svmSig, 'boxconstraint', C, 'options', SVMopts);
end

if useGLM
    if size(classifications,2)>1
        classifications=classifications';
    end
    classifier.B=glmfit(featureValues,logical(classifications),'binomial', 'link', 'logit');
end




