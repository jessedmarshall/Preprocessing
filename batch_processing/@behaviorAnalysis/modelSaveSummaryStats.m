function obj = modelSaveSummaryStats(obj)
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
    obj.sumStats.pctTtest{1,1} = nan;
    obj.sumStats.numMI2sigma{1,1} = nan;
    obj.sumStats.numTtest{1,1} = nan;
    obj.sumStats.zscore{1,1} = nan;
    obj.sumStats.zscoresPost{1,1} = nan;
    obj.sumStats.zscoresPre{1,1} = nan;
    obj.sumStats.signalFiringModulation{1,1} = nan;
    obj.sumStats.signalFiringModulationShuffle{1,1} = nan;
    obj.sumStats.stimulusOverlay{1,1} = nan;
    obj.sumStats.overlapMI{1,1} = nan;
    obj.sumStats.overlapTtest{1,1} = nan;
    obj.sumStats.overlapMINum{1,1} = nan;
    obj.sumStats.overlapTtestNum{1,1} = nan;
    obj.sumStats.overlapMIPct{1,1} = nan;
    obj.sumStats.overlapTtestPct{1,1} = nan;
    zScoreString = {'All','Ttest','NotTtest','MI'};
    for alignIdxToUse=1:length(zScoreString)
        eval(['obj.sumStats.zscore' zScoreString{alignIdxToUse} '{1,1} = nan;']);
        eval(['obj.sumStats.dfofRange' zScoreString{alignIdxToUse} '{1,1} = nan;']);
        eval(['obj.sumStats.zscorePre' zScoreString{alignIdxToUse} '{1,1} = nan;']);
        eval(['obj.sumStats.zscorePost' zScoreString{alignIdxToUse} '{1,1} = nan;']);
        eval(['obj.sumStats.zscoreRange' zScoreString{alignIdxToUse} '{1,1} = nan;']);
    end
    % ============================
    [fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
    for thisFileNumIdx = 1:nFilesToAnalyze
    % for thisFileNum = 1:nFiles
        thisFileNum = fileIdxArray(thisFileNumIdx);
        obj.fileNum = thisFileNum;
        % obj.fileNum = thisFileNum;
        subject = obj.subjectStr{obj.fileNum};
        assay = obj.assay{obj.fileNum};
        assayType = obj.assayType{obj.fileNum};
        assayNum = obj.assayNum{obj.fileNum};
        nIDs = length(obj.stimulusNameArray);
        display(repmat('=',1,21))
        % display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
        display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
        % for idNum = 1:nIDs
        for idNumIdx = 1:length(idNumIdxArray)
            idNum = idNumIdxArray(idNumIdx);
            obj.stimNum = idNum;
            display([num2str(idNum) '/' num2str(nIDs) ' | extracting/saving summary stats: ' nameArray{idNum}])
            obj.stimNum = idNum;
            % ============================
            stimTimeSeq = obj.stimulusTimeSeq{idNum};
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

            obj = incrementSummaryStats(obj);
            % add identifier information
            obj.sumStats.pctMI2sigma{end,1} = nanmean(sigModSignals);
            obj.sumStats.pctTtest{end,1} = nanmean(ttestSignals);
            obj.sumStats.numMI2sigma{end,1} = nansum(sigModSignals);
            obj.sumStats.numTtest{end,1} = nansum(ttestSignals);
            % add summary stats
            obj.sumStats.zscore{end,1} = (zscoresPost-zscoresPre);
            obj.sumStats.zscoresPost{end,1} = zscoresPost;
            obj.sumStats.zscoresPre{end,1} = zscoresPre;
            obj.sumStats.signalFiringModulation{end,1} = (alignedSigPost-alignedSigPre);
            obj.sumStats.signalFiringModulationShuffle{end,1} = NaN;
            %
            zScoreString = {'All','Ttest','NotTtest','MI'};
            for alignIdxToUse=1:length(alignedSignalArray)
                alignedSignal = alignedSignalArray{alignIdxToUse};
                alignedSignalShuffledMean = alignedSignalShuffledMeanArray{alignIdxToUse};
                alignedSignalShuffledStd = alignedSignalShuffledStdArray{alignIdxToUse};
                zscoresExtra = (alignedSignal-alignedSignalShuffledMean)./alignedSignalShuffledStd;

                zscoresPreExtra = nanmean(zscoresExtra(lenTimeseqHalf-10:lenTimeseqHalf));
                zscoresPostExtra = nanmean(zscoresExtra(lenTimeseqHalf:lenTimeseqHalf+10));
                zscoresRangeExtra = nanmean(zscoresExtra(lenTimeseqHalf+stimTimeSeq));
                dfofRange = nanmean(alignedSignal(lenTimeseqHalf+stimTimeSeq))/nansum(sigModSignals);

                eval(['obj.sumStats.dfofRange' zScoreString{alignIdxToUse} '{end,1} = (dfofRange);']);
                eval(['obj.sumStats.zscorePre' zScoreString{alignIdxToUse} '{end,1} = (zscoresPreExtra);']);
                eval(['obj.sumStats.zscorePost' zScoreString{alignIdxToUse} '{end,1} = (zscoresPostExtra);']);
                eval(['obj.sumStats.zscoreRange' zScoreString{alignIdxToUse} '{end,1} = (zscoresRangeExtra);']);
        	end

            % for idNum2 = 1:nIDs
            for idNumIdx = 1:length(idNumIdxArray)
                idNum2 = idNumIdxArray(idNumIdx);
                if idNum2==idNum
                    continue
                end
                obj = incrementSummaryStats(obj);
                obj.sumStats.stimulus{end,1} = [nameArray{idNum} ' & ' nameArray{idNum2}];
                display(num2str([idNum idNum2]))
                if length(obj.sigModSignals{obj.fileNum,idNum})==length(obj.sigModSignals{obj.fileNum,idNum2})
                     overlapMIScore = sum(obj.sigModSignals{obj.fileNum,idNum} & obj.sigModSignals{obj.fileNum,idNum2})/sum(obj.sigModSignals{obj.fileNum,idNum} | obj.sigModSignals{obj.fileNum,idNum2});
                     numShuffle = 500;
                        nMIStim1 = sum(obj.sigModSignals{obj.fileNum,idNum});
                        nMIStim2 = sum(obj.sigModSignals{obj.fileNum,idNum2});
                        nSignals = length(obj.sigModSignals{obj.fileNum,idNum});
                     for nShuffle = 1:numShuffle
                        vector1 = zeros([1 nSignals]); vector1(randsample([1:nSignals],nMIStim1)) = 1;
                        vector2 = zeros([1 nSignals]); vector2(randsample([1:nSignals],nMIStim2)) = 1;
                        overlapShuffleMI{nShuffle} = [vector1(:) vector2(:)];
                        overlapShuffleMI{nShuffle} = sum(prod(overlapShuffleMI{nShuffle},2))/sum(sum(overlapShuffleMI{nShuffle},2));
                    end
                    % overlapMIScore
                    % hist([overlapShuffleMI{:}],20)
                    % [overlapShuffleMI{:}]
                    % pause
                    overlapShuffleMIMean = nanmean([overlapShuffleMI{:}]);
                    overlapShuffleMIStd = nanstd([overlapShuffleMI{:}]);
                    obj.sumStats.overlapMI{end,1} = (overlapMIScore-overlapShuffleMIMean)/overlapShuffleMIStd;
                    obj.sumStats.overlapMINum{end,1} = sum(obj.sigModSignals{obj.fileNum,idNum} & obj.sigModSignals{obj.fileNum,idNum2});
                    obj.sumStats.overlapMIPct{end,1} = overlapMIScore;
                    % obj.sumStats.overlapMI

                    % obj.sumStats.overlapMINum{1,1} = nan;
                    % obj.sumStats.overlapTtestNum{1,1} = nan;
                    % obj.sumStats.overlapMIPct{1,1} = nan;
                    % obj.sumStats.overlapTtestPct{1,1} = nan;
                end
                if length(obj.ttestSignSignals{obj.fileNum,idNum})==length(obj.ttestSignSignals{obj.fileNum,idNum2})
                     overlapMIScore = sum(obj.ttestSignSignals{obj.fileNum,idNum} & obj.ttestSignSignals{obj.fileNum,idNum2})/sum(obj.ttestSignSignals{obj.fileNum,idNum} | obj.ttestSignSignals{obj.fileNum,idNum2});
                     numShuffle = 500;
                        nMIStim1 = sum(obj.ttestSignSignals{obj.fileNum,idNum});
                        nMIStim2 = sum(obj.ttestSignSignals{obj.fileNum,idNum2});
                        nSignals = length(obj.ttestSignSignals{obj.fileNum,idNum});
                     for nShuffle = 1:numShuffle
                        vector1 = zeros([1 nSignals]); vector1(randsample([1:nSignals],nMIStim1)) = 1;
                        vector2 = zeros([1 nSignals]); vector2(randsample([1:nSignals],nMIStim2)) = 1;
                        overlapShuffleMI{nShuffle} = [vector1(:) vector2(:)];
                        overlapShuffleMI{nShuffle} = sum(prod(overlapShuffleMI{nShuffle},2))/sum(sum(overlapShuffleMI{nShuffle},2));
                    end
                    overlapShuffleMIMean = nanmean([overlapShuffleMI{:}]);
                    overlapShuffleMIStd = nanstd([overlapShuffleMI{:}]);
                    obj.sumStats.overlapTtest{end,1} = (overlapMIScore-overlapShuffleMIMean)/overlapShuffleMIStd;
                    obj.sumStats.overlapTtestNum{end,1} = sum(obj.ttestSignSignals{obj.fileNum,idNum} & obj.ttestSignSignals{obj.fileNum,idNum2});
                    obj.sumStats.overlapTtestPct{end,1} = overlapMIScore;
                end
                % if length(obj.ttestSignSignals{obj.fileNum,idNum})==length(obj.ttestSignSignals{obj.fileNum,idNum2})
                %     obj.sumStats.overlapTtest{end,1} = sum(obj.ttestSignSignals{obj.fileNum,idNum} & obj.ttestSignSignals{obj.fileNum,idNum2})/sum(obj.ttestSignSignals{obj.fileNum,idNum} | obj.ttestSignSignals{obj.fileNum,idNum2});
                % end
            end
        end
    end

	% write out summary statistics
    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_summary8.tab'];
    display(['saving data to: ' savePath])
	writetable(struct2table(obj.sumStats),savePath,'FileType','text','Delimiter','\t');
end

function obj = incrementSummaryStats(obj)
    % % add identifier information
    % obj.sumStats.subject{end+1,1} = obj.subjectStr{obj.fileNum};
    % obj.sumStats.assay{end+1,1} = obj.assay{obj.fileNum};
    % obj.sumStats.assayType{end+1,1} = obj.assayType{obj.fileNum};
    % obj.sumStats.assayNum{end+1,1} = obj.assayNum{obj.fileNum};
    % obj.sumStats.stimulus{end+1,1} = obj.stimulusNameArray{obj.stimNum};

    sumStatsNameList = fieldnames(obj.sumStats);
    % sumStatsNameList
    for sumStatNo = 1:length(sumStatsNameList)
        % sumStatsNameList{sumStatNo}
        obj.sumStats.(sumStatsNameList{sumStatNo}){end+1,1} = NaN;
    end

    % add identifier information
    obj.sumStats.subject{end,1} = obj.subjectStr{obj.fileNum};
    obj.sumStats.assay{end,1} = obj.assay{obj.fileNum};
    obj.sumStats.assayType{end,1} = obj.assayType{obj.fileNum};
    obj.sumStats.assayNum{end,1} = obj.assayNum{obj.fileNum};
    obj.sumStats.stimulus{end,1} = obj.stimulusNameArray{obj.stimNum};

    % obj.sumStats.pctMI2sigma{end+1,1} = NaN;
    % obj.sumStats.pctTtest{end+1,1} = NaN;
    % % add summary stats
    % obj.sumStats.zscore{end+1,1} = NaN;
    % obj.sumStats.zscoresPost{end+1,1} = NaN;
    % obj.sumStats.zscoresPre{end+1,1} = NaN;
    % obj.sumStats.signalFiringModulation{end+1,1} = NaN;
    % obj.sumStats.signalFiringModulationShuffle{end+1,1} = NaN;
    % obj.sumStats.stimulusOverlay{end+1,1} = NaN;
    % obj.sumStats.overlapMI{end+1,1} = NaN;
    % obj.sumStats.overlapTtest{end+1,1} = NaN;
    % zScoreString = {'All','Ttest','NotTtest','MI'};
    % for alignIdxToUse=1:length(obj.alignedSignalArray{obj.fileNum,obj.stimNum})
    %     eval(['obj.sumStats.zscore' zScoreString{alignIdxToUse} '{end+1,1} = NaN;']);
    %     eval(['obj.sumStats.zscorePre' zScoreString{alignIdxToUse} '{end+1,1} = NaN;']);
    %     eval(['obj.sumStats.zscorePost' zScoreString{alignIdxToUse} '{end+1,1} = NaN;']);
    %     eval(['obj.sumStats.zscoreRange' zScoreString{alignIdxToUse} '{end+1,1} = NaN;']);
    % end
end
