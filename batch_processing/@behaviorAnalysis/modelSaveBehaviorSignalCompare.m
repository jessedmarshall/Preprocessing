function obj = modelSaveBehaviorSignalCompare(obj)
	% DESCRIPTION
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

    nameArray = obj.stimulusNameArray;
    saveNameArray = obj.stimulusSaveNameArray;
    idArray = obj.stimulusIdArray;
    timeSeq = obj.timeSequence;
    zScoreTime = 10;
    if strcmp(obj.analysisType,'group')
        nFiles = length(obj.rawSignals);
    else
        nFiles = 1;
    end
    % ============================
    % reset summary stats
    obj.sumStats = {};
    obj.sumStats.subject{1,1} = nan;
    obj.sumStats.assay{1,1} = nan;
    obj.sumStats.assayType{1,1} = nan;
    obj.sumStats.assayNum{1,1} = nan;
    obj.sumStats.stimulus{1,1} = nan;
    obj.sumStats.pctMI2sigma{1,1} = nan;
    obj.sumStats.zscore{1,1} = nan;
    obj.sumStats.zscoresPost{1,1} = nan;
    obj.sumStats.zscoresPre{1,1} = nan;
    obj.sumStats.signalFiringModulation{1,1} = nan;
    obj.sumStats.signalFiringModulationShuffle{1,1} = nan;
    zScoreString = {'All','Ttest','NotTtest','MI'};
    for alignIdxToUse=1:length(zScoreString)
        eval(['obj.sumStats.zscore' zScoreString{alignIdxToUse} '{1,1} = nan;']);
    end
    % ============================
    for thisFileNum = 1:nFiles
        obj.fileNum = thisFileNum;
        subject = obj.subjectStr{obj.fileNum};
        assay = obj.assay{obj.fileNum};
        assayType = obj.assayType{obj.fileNum};
        assayNum = obj.assayNum{obj.fileNum};
        nIDs = length(obj.stimulusNameArray);
        for idNum = 1:nIDs
            display([num2str(idNum) '/' num2str(nIDs) ' | extracting/saving summary stats: ' nameArray{idNum}])
            % ============================
            alignedSignalArray = obj.alignedSignalArray{obj.fileNum,idNum};
            alignedSignalShuffledMeanArray = obj.alignedSignalShuffledMeanArray{obj.fileNum,idNum};
            alignedSignalShuffledStdArray = obj.alignedSignalShuffledStdArray{obj.fileNum,idNum};
            if isempty(obj.alignedSignalArray{obj.fileNum,idNum})
                continue;
            end
            alignedSignal = obj.alignedSignalArray{obj.fileNum,idNum}{1};
            if isempty(alignedSignal)
                continue;
            end
            alignedSignalShuffledMean = obj.alignedSignalShuffledMeanArray{obj.fileNum,idNum}{1};
            alignedSignalShuffledStd = obj.alignedSignalShuffledStdArray{obj.fileNum,idNum}{1};
            sigModSignals = obj.sigModSignals{obj.fileNum,idNum};
            ttestSignals = obj.ttestSignSignals{obj.fileNum,idNum};
            % ============================
            lenTimeseqHalf = floor(length(timeSeq)/2);
            % calculate Zscore
            zscores = (alignedSignal-alignedSignalShuffledMean)./alignedSignalShuffledStd;
            zscoresPost = nanmean(zscores(lenTimeseqHalf+1:lenTimeseqHalf+zScoreTime));
            zscoresPre = nanmean(zscores(lenTimeseqHalf-zScoreTime:lenTimeseqHalf));

            % look at number of significant points before and after stimulus onset
            alignedSig = alignedSignal>(alignedSignalShuffledMean+1.96*alignedSignalShuffledStd);
            alignedSigPost = nanmean(alignedSig(lenTimeseqHalf+1:lenTimeseqHalf+zScoreTime));
            alignedSigPre = nanmean(alignedSig(lenTimeseqHalf-zScoreTime:lenTimeseqHalf));

            % add identifier information
            obj.sumStats.subject{end+1,1} = subject;
            obj.sumStats.assay{end+1,1} = assay;
            obj.sumStats.assayType{end+1,1} = assayType;
            obj.sumStats.assayNum{end+1,1} = assayNum;
            obj.sumStats.stimulus{end+1,1} = nameArray{idNum};
            obj.sumStats.pctMI2sigma{end+1,1} = nanmean(sigModSignals);
            obj.sumStats.pctTtest{end+1,1} = nanmean(ttestSignals);
            % add summary stats
            obj.sumStats.zscore{end+1,1} = (zscoresPost-zscoresPre);
            obj.sumStats.zscoresPost{end+1,1} = zscoresPost;
            obj.sumStats.zscoresPre{end+1,1} = zscoresPre;
            obj.sumStats.signalFiringModulation{end+1,1} = (alignedSigPost-alignedSigPre);
            obj.sumStats.signalFiringModulationShuffle{end+1,1} = NaN;
            %
            zScoreString = {'All','Ttest','NotTtest','MI'};
            for alignIdxToUse=1:length(alignedSignalArray)
                alignedSignal = alignedSignalArray{alignIdxToUse};
                alignedSignalShuffledMean = alignedSignalShuffledMeanArray{alignIdxToUse};
                alignedSignalShuffledStd = alignedSignalShuffledStdArray{alignIdxToUse};
                zscoresExtra = (alignedSignal-alignedSignalShuffledMean)./alignedSignalShuffledStd;
                zscoresPostExtra = nanmean(zscoresExtra(lenTimeseqHalf+1:lenTimeseqHalf+10));
                eval(['obj.sumStats.zscore' zScoreString{alignIdxToUse} '{end+1,1} = (zscoresPostExtra);']);
        	end
        end
    end

	% write out summary statistics
    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_summary5.tab'];
    display(['saving data to: ' savePath])
	writetable(struct2table(obj.sumStats),savePath,'FileType','text','Delimiter','\t');
end