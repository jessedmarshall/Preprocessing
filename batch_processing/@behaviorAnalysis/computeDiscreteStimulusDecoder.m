function obj = computeDiscreteStimulusDecoder(obj)
	% for testing out new algorithms, currently mahalanobis distances
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%
	% dependencies
		% NOTE: this currently depends on Lacey's decoding functions, see trainDecoder.m, testDecoder.m

	% changelog
		%
	% TODO
		%

	options.numFramesBack = 1
	options.smoothLength = 3

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	obj.detailStats = [];
	obj.detailStats.frame = [];
    obj.detailStats.value = [];
    obj.detailStats.stimulusOriginal = {};
    obj.detailStats.stimulusDecoded = {};
    obj.detailStats.decodeType = {};
    obj.detailStats.subject = {};
    obj.detailStats.assay = {};
    obj.detailStats.assayType = {};
    obj.detailStats.assayNum = {};
	obj.detailStats

	scnsize = get(0,'ScreenSize');
	[showNoStimuliIdx, ok] = listdlg('ListString',{'yes','no'},'ListSize',[scnsize(3)*0.2 scnsize(4)*0.2],'Name','show no stimuli trials?');

	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			nameArray = obj.stimulusNameArray;
			saveNameArray = obj.stimulusSaveNameArray;
			idArray = obj.stimulusIdArray;
			assayTable = obj.discreteStimulusTable;
			%
			[IcaTraces IcaFilters signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj);
			% signalPeaks = IcaTraces;
			nIDs = length(obj.stimulusNameArray);
			nSignals = size(IcaTraces,1);
			if isempty(IcaFilters);continue;end;
			% IcaTraces = obj.rawSignals{obj.fileNum};
			% IcaFilters = obj.rawImages{obj.fileNum};
			% signalPeaks = obj.signalPeaks{obj.fileNum};
			%
			options.dfofAnalysis = obj.dfofAnalysis;
			options.stimTriggerOnset = obj.stimTriggerOnset;
			options.picsSavePath = obj.picsSavePath;
			thisFileID = obj.fileIDArray{obj.fileNum};
			subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
			framesPerSecond = obj.FRAMES_PER_SECOND;
			timeSeq = obj.timeSequence;
			%
			subject = obj.subjectNum{obj.fileNum};
			subjectStr = obj.subjectStr{obj.fileNum};
			assay = obj.assay{obj.fileNum};
			assayType = obj.assayType{obj.fileNum};
			assayNum = obj.assayNum{obj.fileNum};
			%
			% sigModSignalsAll = obj.sigModSignalsAll{obj.fileNum};
			% =====================
			postStimulusTimeSeq = obj.postStimulusTimeSeq;
			postStimulusTimeSeq = -10:10;
			MICRON_PER_PIXEL = obj.MICRON_PER_PIXEL;
			% =====================
			nIDs = length(obj.stimulusNameArray);
			colorArray = hsv(nIDs);
			idNumCounter = 1;
			thisFigNo = 1100
			% =====================
			nIterations = 6;

			decodeConfusionMatIter = {};
			decodeConfusionMatIterShuffle = {};
			decodingStruct = {};
			for iterationNo = 1:nIterations
				idNumCounter = 2;
				nIDs = length(idNumIdxArray);
				stimVectorTrain = zeros([obj.nFrames{obj.fileNum} 1]);
				stimVectorTest = zeros([obj.nFrames{obj.fileNum} 1]);
				idNumAnalyzed = [];
				for idNumIdx = 1:(nIDs+1)
					if idNumIdx<=nIDs
						idNum = idNumIdxArray(idNumIdx);
						obj.stimNum = idNum;
						% obtain stimulus information
						% display('---')
						stimVector = obj.modelGetStim(idArray(idNum));
						if isempty(stimVector); continue; end;
						stimTimeSeq = obj.stimulusTimeSeq{idNum};
						stimTimeSeq = -5:0;
						stimVectorSpread = spreadSignal(stimVector,'timeSeq',stimTimeSeq);
						% only look at the point decoding
						% stimVectorSpread = stimVector;
						stimIdx = find(stimVectorSpread);
						nStimPts = length(stimIdx);
						if nStimPts<12
							continue
							stimIdx = [stimIdx stimIdx-1 stimIdx-2 stimIdx-3];
						end
						nStimPts = length(stimIdx)
						nStimIdxTrain = sort(randperm(nStimPts,round(nStimPts*0.8)));
						nStimIdxTest = sort(setdiff(1:nStimPts,nStimIdxTrain));
						% stimIdx
						% stimIdx(nStimIdxTrain)
						% stimIdx(nStimIdxTest)
						idNumAnalyzed(idNumIdx) = idNum;
						stimVectorTrain(stimIdx(nStimIdxTrain)) = idNumCounter;
						stimVectorTest(stimIdx(nStimIdxTest)) = idNumCounter;
					else
						if showNoStimuliIdx==2
							continue
						end
						display('calculating no stimuli values...')
						nStimPts = length(find(stimVectorTrain));
						% find all points in a trial when a stimulus did not occur
						noStimuliIdx = find(~stimVectorTrain|~stimVectorTest);
						% stimVector = zeros([1 nStimPts]);
						noStimuliIdx = noStimuliIdx(randperm(length(noStimuliIdx),nStimPts));
						stimIdx = noStimuliIdx;
						% stimVectorTrain(noStimuliIdx) = 1;
						nStimPts = length(stimIdx);
						nStimIdxTrain = randperm(nStimPts,round(nStimPts*0.8));
						nStimIdxTest = setdiff(1:nStimPts,nStimIdxTrain);
						stimVectorTrain(stimIdx(nStimIdxTrain)) = 1;
						stimVectorTest(stimIdx(nStimIdxTest)) = 1;

						stimName = 'no stimuli';
						stimTimeSeq = 0;
					end
					idNumCounter = idNumCounter + 1;
				end
				idNumAnalyzed = idNumAnalyzed(find(idNumAnalyzed));
				idxToTrain = find(stimVectorTrain);
				idxToTest = find(stimVectorTest);
				stimVectorTrain(~stimVectorTrain) = [];
				stimVectorTest(~stimVectorTest) = [];
				stimVectorIter{iterationNo} = stimVectorTrain;
				% =======
				% =======
				signalPeaks = IcaTraces;
				% signalPeaks = signalPeaks+1;
				signalPeaksTmp = signalPeaks(:,idxToTrain);
				size(signalPeaksTmp')
				size(stimVectorTrain(:))
				% decodingStruct{iterationNo} = NaiveBayes.fit(signalPeaksTmp',stimVectorTrain(:),'Distribution', 'mn');
				if iterationNo<=floor(nIterations/2)
					decodingStruct{iterationNo} = NaiveBayes.fit(signalPeaksTmp',stimVectorTrain(:),'Distribution', 'normal');
					% decodingStruct{iterationNo} = NaiveBayes.fit(signalPeaksTmp',stimVectorTrain(:),'Distribution', 'mv');
				else
					% if shuffling, change signal IDs
					decodingStruct{iterationNo} = NaiveBayes.fit(signalPeaksTmp(randperm(size(signalPeaksTmp,1)),:)',stimVectorTrain(:),'Distribution', 'normal');
					% decodingStruct{iterationNo} = NaiveBayes.fit(signalPeaksTmp(randperm(size(signalPeaksTmp,1)),:)',stimVectorTrain(:),'Distribution', 'mv');
				end
				% =======
				numFramesBack = options.numFramesBack;
				smoothLength = options.smoothLength;
				% [eventMatrix, positionVecTrain] = makeDecodingMatrices(signalPeaksTmp,stimVectorTrain, numFramesBack, smoothLength);
				% decodingStruct = trainDecoder(eventMatrix, positionVecTrain);
				% =======
				signalPeaksTmp = signalPeaks(:,idxToTest);
				% if iterationNo<=floor(nIterations/2)
				% 	signalPeaksTmp = signalPeaks(:,idxToTest);
				% else
				% 	% if shuffling, change signal IDs
				% 	signalPeaksTmp = signalPeaks(randperm(size(signalPeaks,1)),idxToTest);
				% end
				% =======
				% [eventMatrix, positionVecTest] = makeDecodingMatrices(signalPeaksTmp,stimVectorTest, numFramesBack, smoothLength);
				% [decodedPos, logProbOfPos, allLogProb] = testDecoder(eventMatrix, decodingStruct);
				% =======
				positionVecTest = stimVectorTest;
				decodedPos = decodingStruct{iterationNo}.predict(signalPeaksTmp');
				% display decoder performance
				viewDecoderPerformance();
				if iterationNo<=floor(nIterations/2)
					set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 5])
					obj.modelSaveImgToFile([],'bayesDecodingStim_','current',strcat(obj.fileIDArray{obj.fileNum}));
				else
				end

				% rows = known labels, columns = predicted labels
				C = confusionmat(positionVecTest(:)',decodedPos(:)');
				% confusionmat(positionVecTest(:)',positionVecTest(:)');
				nPerGroup = diag(confusionmat(positionVecTest(:)',positionVecTest(:)'));
				nPerGroup = repmat(nPerGroup,1,size(C,1));
				% C
				% nPerGroup
				decodeConfusionMat = C./nPerGroup;
				decodeConfusionMat = decodeConfusionMat';
				% display confusion matrix
				[~, ~] = openFigure(thisFigNo+400, '');
				viewDecoderConfusionMat();
				decodeConfusionMat = decodeConfusionMat';
				if iterationNo<=floor(nIterations/2)
					decodeConfusionMatIter{iterationNo} = decodeConfusionMat;
				else
					% if these are shuffle iterations, store in a separate variable
					decodeConfusionMatIterShuffle{iterationNo} = decodeConfusionMat;
				end
			end
			decodeConfusionMatIter = cat(3,decodeConfusionMatIter{:});
			decodeConfusionMatIter = nanmean(decodeConfusionMatIter,3);
			decodeConfusionMat = decodeConfusionMatIter';
			[~, ~] = openFigure(thisFigNo+400, '');
			clf
			subX = 1;subY = 2;
			subplot(subX,subY,1)
			viewDecoderConfusionMat();
			% set(gca,'XTickLabel',{''});
			rotateXLabels(gca(), 20)
			%
			decodeConfusionMatIterShuffle = cat(3,decodeConfusionMatIterShuffle{:});
			decodeConfusionMatIterShuffle = nanmean(decodeConfusionMatIterShuffle,3);
			decodeConfusionMat = decodeConfusionMatIterShuffle';
			[~, ~] = openFigure(thisFigNo+400, '');
			subplot(subX,subY,2)
			viewDecoderConfusionMat();title('shuffled signal IDs');
			rotateXLabels(gca(), 20)

			decodeConfusionMatResidual = decodeConfusionMatIter-decodeConfusionMatIterShuffle;
			% decodeConfusionMat = decodeConfusionMatResidual';
			% [~, ~] = openFigure(thisFigNo+400, '');
			% subplot(subX,subY,3)
			% viewDecoderConfusionMat();title('residual(original,shuffled)');
			% caxis([-1,1])
			% rotateXLabels(gca(), 30)
			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 15 7])
			obj.modelSaveImgToFile([],'bayesDecodingStimConfusion_','current',strcat(obj.fileIDArray{obj.fileNum}));
			% tril(decodeConfusionMat,0);

			if showNoStimuliIdx==2
				stimNames = {nameArray{idNumAnalyzed}};
			else
				stimNames = {'no action',nameArray{idNumAnalyzed}};
			end
			[p,q] = meshgrid(1:length(stimNames), 1:length(stimNames));
			% idPairs = [p(:) q(:)];

			% decodeConfusionMatIter
			decodeConfusionCell = {decodeConfusionMatIter,decodeConfusionMatIterShuffle,decodeConfusionMatResidual};
			decodeConfusionStr = {'original','shuffle','residual'};
			for decodeNum = 1:length(decodeConfusionCell)
				numPtsToAdd = length(decodeConfusionCell{decodeNum}(:));
				obj.detailStats.frame(end+1:end+numPtsToAdd,1) = 1:numPtsToAdd;
				obj.detailStats.value(end+1:end+numPtsToAdd,1) = decodeConfusionCell{decodeNum}(:);
				obj.detailStats.stimulusOriginal(end+1:end+numPtsToAdd,1) = {stimNames{q}};
			    obj.detailStats.stimulusDecoded(end+1:end+numPtsToAdd,1) = {stimNames{p}};
			    obj.detailStats.decodeType(end+1:end+numPtsToAdd,1) = {decodeConfusionStr{decodeNum}};
				obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subjectStr};
				obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
				obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
				obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
			end

			idNumCounter = 2;
			if length(idNumIdxArray)<=5
				xPlot = 1
				yPlot = length(idNumIdxArray);
			else
				[xPlot yPlot] = getSubplotDimensions(length(idNumIdxArray)+1);
			end
			decodedPos = decodingStruct{1}.predict(signalPeaks');
			decodedPosShuffle = decodingStruct{end}.predict(signalPeaks');
			[~, ~] = openFigure(thisFigNo+4689, '');
				clf
			for idNumIdx = 1:length(idNumIdxArray)
				idNum = idNumIdxArray(idNumIdx);
				% idNumAnalyzed(idNumCounter) = idNum;
				obj.stimNum = idNum;
				% obtain stimulus information
				% display('---')
				stimVector = obj.modelGetStim(idArray(idNum));
				if isempty(stimVector); continue; end;
				stimTimeSeq = obj.stimulusTimeSeq{idNum};
				stimTimeSeq = [-150:150];
				stimVectorSpread = spreadSignal(stimVector,'timeSeq',stimTimeSeq);
				% find(stimVector)
				% size(decodedPos)
				% signalPeaksTmp = signalPeaks(:,find(stimVectorSpread));
				% decodedPos = decodingStruct{1}.predict(signalPeaks');
				stimVectorSpread = spreadSignal(stimVector,'timeSeq',stimTimeSeq);
				% size(decodedPos)
				% size(stimVector)
				decodedPosCorrect = decodedPos(:)==stimVectorSpread(:)*idNumCounter;
				decodedPosCorrectShuffle = decodedPosShuffle(:)==stimVectorSpread(:)*idNumCounter;

				% figure(292929)
					% plot(decodedPos,'r');hold on
					% plot(stimVectorSpread*idNumCounter,'g');hold off
					% zoom on
					% pause
					% plot(decodedPosCorrect,'r');hold on
					% plot(stimVector,'g');hold off
					% pause
				tmpTimeSeq = [-50:50];
				decodedPosStimAligned = alignSignal(double(decodedPosCorrect(:))', stimVector,tmpTimeSeq,'returnFormat','perSignalStimResponseMean');
				decodedPosStimAlignedShuffle = alignSignal(double(decodedPosCorrectShuffle(:))', stimVector,tmpTimeSeq,'returnFormat','perSignalStimResponseMean');
				% decodedPosStimAligned = nanmedian(decodedPosStimAligned,1);
				% size(decodedPosStimAligned)
				% decodedPosStimAligned
				% decodedPosStimAligned = nanmean(decodedPosStimAligned,1);
				[~, ~] = openFigure(thisFigNo+4689, '');
					subplot(xPlot,yPlot,idNumIdx)
					plot(tmpTimeSeq/framesPerSecond,decodedPosStimAligned); hold on;
					plot(tmpTimeSeq/framesPerSecond,decodedPosStimAlignedShuffle,'r')
					xval = length(tmpTimeSeq)/2;
					xval = 0;
					x=[xval,xval];
					% y=[minValTraces maxValTraces];
					y=[0 1];
					plot(x,y,'k');
					hold off
					if idNumIdx==1
						xlabel('frames')
						ylabel('probability(decoder outputs stimulus)')
						legend({'normal','shuffled'});legend('boxoff');
					end
					title([obj.fileIDNameArray{obj.fileNum},num2str(length(find(stimVector))),nameArray(idNum)])
					% ,' stim num=',num2str(idNumCounter)
				idNumCounter = idNumCounter + 1;

				decodeConfusionCell = {decodedPosStimAligned,decodedPosStimAlignedShuffle};
				decodeConfusionStr = {'original','shuffle'};
				for decodeNum = 1:length(decodeConfusionCell)
					numPtsToAdd = length(decodeConfusionCell{decodeNum}(:));
					obj.detailStats.frame(end+1:end+numPtsToAdd,1) = tmpTimeSeq;
					obj.detailStats.value(end+1:end+numPtsToAdd,1) = decodeConfusionCell{decodeNum}(:);
					obj.detailStats.stimulusOriginal(end+1:end+numPtsToAdd,1) = {nameArray{idNum}};
				    obj.detailStats.stimulusDecoded(end+1:end+numPtsToAdd,1) = {'linePlots'};
				    obj.detailStats.decodeType(end+1:end+numPtsToAdd,1) = {decodeConfusionStr{decodeNum}};
					obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subjectStr};
					obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
					obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
					obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
				end
			end
			% [~, ~] = openFigure(thisFigNo+4689, '');
				% subplot(xPlot,yPlot,length(idNumIdxArray)+1)
				% plot(1,1); hold on;plot(1,1,'r');legend({'normal','shuffled'});legend('boxoff');axis off;
			if length(idNumIdxArray)<=4
				set(gcf,'PaperUnits','inches','PaperPosition',[0 0 17 7])
			else
				set(gcf,'PaperUnits','inches','PaperPosition',[0 0 15 15])
			end
			obj.modelSaveImgToFile([],'bayesDecodingStimTimeSeq_','current',strcat(obj.fileIDArray{obj.fileNum}));

			% write out summary statistics
		 %    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_mahal.tab'];
		 %    display(['saving data to: ' savePath])
			% writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	% write out summary statistics
    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_decoder.tab'];
    display(['saving data to: ' savePath])
	writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
	% obj.detailStats = [];

	%% functionname: function description
	function [] = viewDecoderPerformance()
		[~, ~] = openFigure(thisFigNo, '');
			clf
			% plotconfusion(decodedPos(:)',positionVec(:)')
			plot(decodedPos,'.k','MarkerSize', 24)
			hold on
			% plot(positionVec+nanmax(decodedPos),'k')
			% plot(positionVecTrain,'.r')
			plot(positionVecTest,'.g')
			positionVecCopy = positionVecTest;
			% positionVecCopy(positionVecCopy==1) = NaN;
			equalPts = (positionVecCopy==decodedPos);
			% plot(1:length(positionVec),equalPts,'b.')
			plot(equalPts/2,'b')
			legend({'decoded','original'})
			% idNumAnalyzed
			% nameArray{idNumAnalyzed}
			yAxisLabels = {'performance','no action',nameArray{idNumAnalyzed}};
			NumTicks = length(yAxisLabels);
			L = get(gca,'YLim');
			set(gca,'YTick',linspace(L(1),L(2),NumTicks))
			set(gca,'YTickLabel',yAxisLabels)
			lhand = get(gca,'ylabel');
			set(lhand,'fontsize',20)
			xlabel('frames')
			title(obj.fileIDNameArray{obj.fileNum})
			zoom on
	end
	function [] = viewDecoderConfusionMat()
			imagesc(decodeConfusionMat)
			% C./nPerGroup
			% sum(C./nPerGroup,2)
			if showNoStimuliIdx==2
				yAxisLabels = {nameArray{idNumAnalyzed}};
			else
				yAxisLabels = {'no action',nameArray{idNumAnalyzed}};
			end
			yAxisLabels = cellfun(@(x) {' ',x}',yAxisLabels,'UniformOutput',false);
			yAxisLabels = getit(yAxisLabels);
			NumTicks = length(yAxisLabels);
			yAxisLabels{end+1} = ' ';
			L = get(gca,'XLim');
			set(gca,'XTick',linspace(L(1),L(2),NumTicks+1))
			L = get(gca,'YLim');
			set(gca,'YTick',linspace(L(1),L(2),NumTicks+1))
			%
			set(gca,'YTickLabel',yAxisLabels)
			set(gca,'XTickLabel',yAxisLabels)
			title(obj.fileIDNameArray{obj.fileNum})
			% rotateXLabels(gca,45);
			% xlabel('original action')
			ylabel('decoded action')
			colorbar
			caxis([0,1])
			colormap(obj.colormap);
	end

end
function c=getit(c)
	if iscell(c)
	    c = cellfun(@getit, c, 'UniformOutput', 0);
	    c = cat(2,c{:});
	else
	    c = {c};
	end
end