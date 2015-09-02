function [outStruct] = classifySignals(inputImages,inputSignals,varargin)
    % runs a specified model on the data and attempts to train a classifier (svm, nnet, etc.) to it.
    % biafra ahanonu
    % started: 2013.08.09
    % adapted from biafra ahanonu nn_cell_classification.m
    % inputs
    %   inputImages - cell array of [nSignals x y] matrices containing each set of images corresponding to inputSignals objects.
    %   inputSignals - cell array of [nSignals frames] matrices containing each set of inputImages signals
    % outputs
    %   outStruct
    % options
    %   inputStruct - can input previously output structure, will automatically search for classifier and output structure won't overwrite the old one.
    %   classifierType - 'nnet' 'svm' 'glm'
    %   trainingOrClassify -
    %   classifier -
    %   inputTargets - cell array of [1 nSignals] vectors with 1/0 classification of good/bad
    % example
    %   % train dataset
    %   [classifyStruct] = classifySignals({inputImages},{inputSignals},'inputTargets',valid,'classifierType','glm');
    %   % classify dataset
    %   [classifyStruct] = classifySignals({inputImages},{inputSignals},'inputStruct',classifyStruct,'classifierType','nnet','trainingOrClassify','classify');

    % changelog
        % 2014.02.02 - generalized nnet classifier to include other classification schemes, finished svm classifier
        % 2014.02.10 - added glm classifier, included image feature list option, allow input of outStruct as inputStruct.
        % 2014.05.02 - fixed svm classify, needed to transpose input features matrix
        % 2014.06.20 - improved nnet, set NaN in input features to zero to avoid problems with classification.
    % TODO
        %

    %========================
    % input a previously created structure to prevent overwriting.
    options.inputStruct = [];
    % 'nnet' 'svm' 'glm' 'all'
    options.classifierType = 'svm';
    % 'training' or 'classify'
    options.trainingOrClassify = 'training';
    % previously trained classifier
    options.classifier = [];
    % known targets to classify with (or compare classifier results to)
    options.inputTargets = [];
    % list of image features to calculate using regionprops
    options.featureList = {'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity'};
    % get options
    options = getOptions(options,varargin);
    display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    % obtain features from each set of images
    numInputs = length(inputImages);
    for inputNo = 1:numInputs
        display(['getting features for ' num2str(inputNo) '/' num2str(numInputs)])
        inputFeatures{inputNo} = computeFeatures(inputImages{inputNo},inputSignals{inputNo},options);
    end
    % inputFeatures
    inputFeatures = cat(1,inputFeatures{:})';
    outStruct.inputFeatures = inputFeatures;

    if ~isempty(options.inputTargets)
        options.inputTargets = cat(2,options.inputTargets{:});
        outStruct.inputTargets = options.inputTargets;


        % valid = options.inputTargets;
        pointColors = ['g','r'];
        nameList = {'SNR','Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity','nPeaks','slopeRatio','avgFwhm','avgPeakAmplitude'};
        [figHandle figNo] = openFigure(756, '');
            for pointNum = 1:2
                pointColor = pointColors(pointNum);
                if pointNum==1
                    valid = logical(options.inputTargets);
                else
                    valid = logical(~options.inputTargets);
                end
                for i=1:length(nameList)
                    subplot(3,ceil(length(nameList)/3),i)
                        % eval(['iStat=imgStats.' nameList{i} ';']);
                        iStat = inputFeatures(i,:);
                        plot(find(valid),iStat(valid),[pointColor '.'])
                        % title(nameList{i})
                        hold on;box off;
                        xlabel('rank'); ylabel(nameList{i})
                        xlim([1 length(iStat)]);
                        % hold off
                end
            end
    end

    % replace output structure with user's input structure
    if ~isempty(options.inputStruct)
        outStruct = options.inputStruct;
    else
        outStruct.null = nan;
    end

    % add targets to output structure or get them from inputted structure
    % if strcmp('training',options.trainingOrClassify)
    %     outStruct.inputTargets = options.inputTargets;
    % elseif strcmp('classify',options.trainingOrClassify)
    %     if ~any(strcmp('inputTargets',fieldnames(outStruct)))
    %         options.inputTargets = outStruct.inputTargets;
    %     end
    % end
    classificationOption = strcat(options.classifierType,'_',options.trainingOrClassify);
    display(classificationOption)
    [figHandle figNo] = openFigure(564, '');
    switch classificationOption
        %========================
        case 'all_training'
            % train all three classifiers at once
            [outStruct.svmClassifier] = svmTrainerFxn(inputFeatures,options.inputTargets(:));
            [outStruct.nnetClassifier] = nnetTrainerFxn(inputFeatures,options.inputTargets(:));
            [outStruct.glmCoeffs] = glmTrainerFxn(inputFeatures,options.inputTargets(:));
            % break;
        case 'all_classify'
            [outStruct.svmGroups] = svmClassifyFxn(outStruct.svmClassifier,inputFeatures);
            [outStruct.nnetGroups] = nnetClassifyFxn(outStruct.nnetClassifier,inputFeatures);
            [outStruct.glmGroups] = glmClassifyFxn(outStruct.glmCoeffs,inputFeatures);
            outStruct.classifications = outStruct.glmGroups;
        case 'svm_training'
            [outStruct.svmClassifier] = svmTrainerFxn(inputFeatures,options.inputTargets(:));
            % break;
        case 'svm_classify'
            if isempty(options.classifier)
                options.classifier = outStruct.svmClassifier;
            end
            [outStruct.svmGroups] = svmClassifyFxn(options.classifier,inputFeatures);
            outStruct.classifications = outStruct.svmGroups;
            % plot confusion matrix
            if ~isempty(options.inputTargets)
                plotconfusion(options.inputTargets(:)',outStruct.svmGroups(:)')
                [c,cm,ind,per] = confusion(options.inputTargets(:)',outStruct.svmGroups(:)');
                outStruct.confusionPct = mean(per,1);
            end
            % break;
        %========================
        case 'nnet_training'
            [outStruct.nnetClassifier] = nnetTrainerFxn(inputFeatures,options.inputTargets(:));
            % break;
        case 'nnet_classify'
            if isempty(options.classifier)
                options.classifier = outStruct.nnetClassifier
            end
           [outStruct.nnetGroups] = nnetClassifyFxn(options.classifier,inputFeatures);
           outStruct.classifications = outStruct.nnetGroups;
           % size(outStruct.nnetGroups)
           % figure(99920)
           % plot(options.inputTargets(:)'+2,'k')
           % hold on
           % plot(outStruct.nnetGroups(:)','r')
           % legend({'targets','output'})
           % hold off
           % pause
           % plot confusion matrix
           if ~isempty(options.inputTargets)
               plotconfusion(options.inputTargets(:)',outStruct.nnetGroups(:)')
               [c,cm,ind,per] = confusion(options.inputTargets(:)',outStruct.nnetGroups(:)');
               outStruct.confusionPct = mean(per,1);
               mean(per,1)
           end
           % break;
        %========================
        case 'glm_training'
            [outStruct.glmCoeffs] = glmTrainerFxn(inputFeatures,options.inputTargets(:));
            % break;
        case 'glm_classify'
            if isempty(options.classifier)
                options.classifier = outStruct.glmCoeffs;
            end
            [outStruct.glmGroups] = glmClassifyFxn(options.classifier,inputFeatures);
            outStruct.classifications = outStruct.glmGroups;
            % plot confusion matrix
            if ~isempty(options.inputTargets)
                plotconfusion(options.inputTargets(:)',outStruct.glmGroups(:)')
                [c,cm,ind,per] = confusion(options.inputTargets(:)',outStruct.glmGroups(:)');
                outStruct.confusionPct = mean(per,1);
            end
            % break;
        %========================
        otherwise
            display('invalid choice specified');
            return
    end

function [inputFeatures] = computeFeatures(inputImages,inputSignals,options)
    % obtains the training features using several sub-routines

    % get the SNR for traces
    [signalSnr ~] = computeSignalSnr(inputSignals);
    % get the peak statistics
    [peakOutputStat] = computePeakStatistics(inputSignals,'waitbarOn',1);
    slopeRatio = peakOutputStat.slopeRatio;
    avgFwhm = peakOutputStat.avgFwhm;
    avgPeakAmplitude = peakOutputStat.avgPeakAmplitude;
    % get the number of spikes
    [signalPeaks, signalPeakIdx] = computeSignalPeaks(inputSignals);
    numOfPeaks = sum(signalPeaks,2);
    % Eccentricity,EquivDiameter,Area,Orientation,Perimeter,Solidity,
    [imgStats] = computeImageFeatures(inputImages, 'thresholdImages',1,'featureList',options.featureList);
    imgFeatures = cell2mat(struct2cell(imgStats))';

    % concatenate all the features together
    % inputFeatures = horzcat(signalSnr(:),imgFeatures,numOfPeaks(:),slopeRatio(:),avgFwhm(:),avgPeakAmplitude(:));
    inputFeatures = horzcat(signalSnr(:),imgFeatures,numOfPeaks(:),slopeRatio(:),avgFwhm(:),avgPeakAmplitude(:));

    % figure(900)
    % plot(inputFeatures)
    % legend({'signalSnr','sizeImageObj','numOfPeaks','slopeRatio','avgFwhm','avgPeakAmplitude'});
    % pause

function [svmClassifier] = svmTrainerFxn(inputFeatures,inputTargets)
    % train SVM
    optionsStruct = statset('Display','iter');
    size(inputFeatures)
    size(inputTargets(:))
    svmClassifier = svmtrain(inputFeatures,inputTargets,'options',optionsStruct);

function [svmGroups] = svmClassifyFxn(svmClassifier,inputFeatures)
    % classify SVM based on svmtrain support vectors
    size(inputFeatures')
    size(svmClassifier.SupportVectors)
    inputFeatures(isnan(inputFeatures)) = 0;
    svmGroups = svmclassify(svmClassifier,inputFeatures');%'showplot',true

function [nnetClassifier] = nnetTrainerFxn(inputFeatures,inputTargets)
    % trains a neural network classifier
    % create a network
    nnetClassifier = feedforwardnet([56 9 4]);
    nnetClassifier.trainFcn = 'trainscg';
    % train network
    % myCluster = parcluster('local');
    % myCluster.NumWorkers = 6;
    % saveProfile(myCluster);
    % matlabpool open
    %net = train(net,trainingSet,targets,'useGPU','yes');
    % [nnetClassifier tr] = train(nnetClassifier,inputFeatures,inputTargets,'useParallel','yes','showResources','yes');
    inputFeatures(isnan(inputFeatures)) = 0;
    [nnetClassifier tr] = train(nnetClassifier,inputFeatures,inputTargets(:)','showResources','yes');
    % matlabpool close

    % ploterrhist(targets - net(trainingSet))

function [nnetGroups] = nnetClassifyFxn(nnetClassifier,inputFeatures)
    % scores inputs based on train and feedforwardnet
    inputFeatures(isnan(inputFeatures)) = 0;
    nnetGroups = sim(nnetClassifier,inputFeatures);

function [glmCoeffs] = glmTrainerFxn(inputFeatures,inputTargets)
    % trains a glm using a normal distribution
    glmCoeffs = glmfit(inputFeatures',inputTargets,'normal');

function [glmGroups] = glmClassifyFxn(glmCoeffs,inputFeatures)
    % classifies features into groups based on coefficients from glmfit
    inputFeatures(isnan(inputFeatures)) = 0;
    glmGroups = glmval(glmCoeffs,inputFeatures','identity');