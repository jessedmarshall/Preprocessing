function obj = viewStimTrigTraces(obj)
	% DESCRIPTION
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%
	% file-exchange
		% tight_subplot used - http://www.mathworks.com/matlabcentral/fileexchange/27991-tight-subplot/content//tight_subplot.m

	% changelog
		%
	% TODO
		%

	% =====================
	userDefaults = {'5','25','25','1','20'};
	if obj.guiEnabled~=1
		scnsize = get(0,'ScreenSize');
    	usrIdxChoice = inputdlg({'number of signals to display','number before frames','number after frames','show all trace plot','max number trials'},'options',1,userDefaults);
	else
		usrIdxChoice = userDefaults;
	end

	% options.frameList = [1:500];
    numSignalsToDisplay = str2num(usrIdxChoice{1});
    preOffset = str2num(usrIdxChoice{2});
    postOffset = str2num(usrIdxChoice{3});
    allTracePlotShow = str2num(usrIdxChoice{4});
    maxTrials = str2num(usrIdxChoice{5});
	% =====================
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
		thisFileNum = fileIdxArray(thisFileNumIdx);
		obj.fileNum = thisFileNum;
		% fileNum = obj.fileNum;
		display(repmat('#',1,21))
		display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
		% =====================
		% for backwards compatibility, will be removed in the future.
		nameArray = obj.stimulusNameArray;
		saveNameArray = obj.stimulusSaveNameArray;
		idArray = obj.stimulusIdArray;
		assayTable = obj.discreteStimulusTable;
		%
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		% IcaTraces = signalPeaks;
		nIDs = length(obj.stimulusNameArray);
		nSignals = size(IcaTraces,1);
		% IcaTraces = obj.rawSignals{obj.fileNum};
		% IcaFilters = obj.rawImages{obj.fileNum};
		% signalPeaks = obj.signalPeaks{obj.fileNum};
		%
		usTimeAfterCS = 10;
		options.dfofAnalysis = obj.dfofAnalysis;
		options.stimTriggerOnset = obj.stimTriggerOnset;
		options.picsSavePath = obj.picsSavePath;
		thisFileID = obj.fileIDArray{obj.fileNum};
		timeSeq = obj.timeSequence;
		subject = obj.subjectNum{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
		framesPerSecond = obj.FRAMES_PER_SECOND;
		% =====================
		nIDs = length(obj.stimulusNameArray);
		colorArray = hsv(nIDs);
		idNumCounter = 1;
		% =====================
		for idNumIdx = 1:length(idNumIdxArray)
			idNum = idNumIdxArray(idNumIdx);
			obj.stimNum = idNum;
			try
				% =====================
				display(repmat('=',1,7))
				display([num2str(idNum) '/' num2str(nIDs) ': analyzing ' nameArray{idNum}])

				% ===============================================================
				% obtain stimulus information
				idArray(idNum)
				stimVector = obj.modelGetStim(idArray(idNum));
				if isempty(stimVector); continue; end;
				framesToAlign = find(stimVector);
				% maxTrials = 100;
				if length(framesToAlign)>=maxTrials
					% framesToAlign = framesToAlign(1:20);
					framesToAlign = framesToAlign(randperm(length(framesToAlign),maxTrials));
				end
				% =======================
				% plotSignalsGraph(IcaTraces(:,:),'LineWidth',2.5);
				% for frame=1:length(framesToAlign)
				% 	yL = get(gca,'YLim');
				% 	line([framesToAlign(frame) framesToAlign(frame)],yL,'Color','r');
				% end
				% zoom on;
				% pause
				% =======================
				% preOffset = 50;
				% postOffset = 50;
				nPoints = size(IcaTraces,2);
				timeVector = [-preOffset:postOffset];
				framesToAlign(find((framesToAlign<preOffset))) = [];
				framesToAlign(find((framesToAlign>(nPoints-postOffset)))) = [];
				% framesToAlign = framesToAlign(1:5);
				peakIdxs = bsxfun(@plus,timeVector,framesToAlign(:))';
				peakIdxsEnd = bsxfun(@plus,timeVector,framesToAlign(:))';

				% peakIdxs
				% peakIdxs(:)
				[~, ~] = openFigure(777, '');
				clf
				% peakIdxs(:)
				useInformativeCells = 0;
				if ~isempty(obj.sigModSignals)&~isempty(obj.sigModSignals{1,1})&useInformativeCells
					titleMod = 'significant signals';
					display('')
					stimTimeSeq = obj.stimulusTimeSeq{idNum};
					% alignSignalAll = alignSignal(signalPeaks,stimVector,stimTimeSeq,'returnFormat','count:[nSignals nAlignmemts]');
					% % sort by cells most responsive right after stimuli
					% alignSignalAllSum = sum(alignSignalAll,2);
					% [responseN reponseScoreIdx] = sort(alignSignalAllSum,'descend');
					% IcaTracesTmp = IcaTraces(reponseScoreIdx,:);
					% signalPeaksTmp = signalPeaks(reponseScoreIdx,:);
					% signalPeaksArrayTmp = signalPeaksArray(reponseScoreIdx);

					sigModSignals = obj.sigModSignals{obj.fileNum,idNum};
					% significantArray = obj.significantArray{obj.fileNum}{obj.stimNum}.('MI');
					significantArray = obj.significantArray{obj.fileNum}{obj.stimNum};
					significantArray(isnan(significantArray)) = -10;
					significantArray(isinf(significantArray)) = 10;
					[responseN reponseScoreIdx] = sort(significantArray,'descend');
					% responseN(:)'
					IcaTracesTmp = IcaTraces(reponseScoreIdx,:);
					IcaFiltersTmp = IcaFilters(reponseScoreIdx,:,:);
					signalPeaksTmp = signalPeaks(reponseScoreIdx,:);
					signalPeaksArrayTmp = signalPeaksArray(reponseScoreIdx);
					% if ~isempty(sigModSignals)
					% 	% sigModSignals(reponseScoreIdx)
					% else
					% 	% IcaTracesTmp = IcaTracesTmp;
					% end
				else
					display('ratio...')
					stimTimeSeq = obj.stimulusTimeSeq{idNum};
					% IcaTraces
					% signalPeaks
					stimTimeSeq = -10:10;
					stimTimeSeq
					stimVectorMod = zeros(size(stimVector));
					stimVectorMod(framesToAlign) = 1;
					% alignSignalAll = alignSignal(signalPeaks,stimVectorMod,stimTimeSeq,'returnFormat','count:[nSignals nAlignmemts]');
					% alignSignalAll = alignSignal(IcaTraces,stimVectorMod,stimTimeSeq,'returnFormat','count:[nSignals nAlignmemts]');
					alignSignalAll = alignSignal(IcaTraces,stimVectorMod,stimTimeSeq,'returnFormat','perSignalStimResponseCount');
						alignSignalAll = alignSignalAll';
					% alignSignalPre = alignSignal(IcaTraces,stimVector,[-10:0],'returnFormat','count:[nSignals nAlignmemts]');
					% alignSignalPost = alignSignal(IcaTraces,stimVector,[0:10],'returnFormat','count:[nSignals nAlignmemts]');
					% alignSignalAll
					size(alignSignalAll)
					alignSignalAllSum = sum(alignSignalAll,2);
					% alignSignalAllSum = mean(alignSignalAll,2);
					% alignSignalRatio = mean(alignSignalPost,2)-mean(alignSignalPre,2);
					% alignSignalRatio
					% alignSignalAllSum
					alignSignalAll = alignSignal(IcaTraces,stimVectorMod,stimTimeSeq);
					alignSignalAllSum = sum(alignSignalAll((round(end/2)+7:end),:),1);
					alignSignalAllSum = sum(alignSignalAll(((round(end/2)-7)):round(end/2),:),1);
					alignSignalAllSum2 = sum(alignSignalAll((round(end/2):(round(end/2)+7)),:),1);
					sortMetric = alignSignalAllSum-alignSignalAllSum2;

					[responseN reponseScoreIdx] = sort(sortMetric,'descend');
					% alignSignalAll = alignSignalAll(reponseScoreIdx,:);
					% [responseN reponseScoreIdx] = sort(alignSignalRatio,'descend');
					% responseN
					titleMod = '';
					IcaTracesTmp = IcaTraces(reponseScoreIdx,:);
					IcaFiltersTmp = IcaFilters(reponseScoreIdx,:,:);
					signalPeaksTmp = signalPeaks(reponseScoreIdx,:);
					signalPeaksArrayTmp = signalPeaksArray(reponseScoreIdx);
				end

				% [~, ~] = openFigure(776, '');
				% 	lenTimeSeq = length(timeVector);
				% 	IcaTracesTmpDisplay = IcaTraces(:,peakIdxs);
				% 	IcaTracesTmpTmp = reshape(IcaTracesTmpDisplay,nSignals,lenTimeSeq,length(framesToAlign));
				% 	[inputMovieX inputMovieY inputMovieZ] = size(IcaTracesTmpTmp);
				% 	IcaTracesTmpDisplayCell = squeeze(mat2cell(IcaTracesTmpTmp,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
				% 	% sortMetricAll = cellfun(@(x) sum(x(:,(round(end/2)-5):round(end/2)),2)-sum(x(:,round(end/2):(round(end/2)+5)),2),IcaTracesTmpDisplayCell,'UniformOutput',0);
				% 	sortMetricAll = cellfun(@(x) sum(x(:,round(end/2):(round(end/2)+5)),2),IcaTracesTmpDisplayCell,'UniformOutput',0);
				% 	sortMetricAll = nansum(cat(2,sortMetricAll{:}),2);
				% 	[responseN reponseScoreIdx] = sort(sortMetricAll,'descend');
				% 	% reponseScoreIdx
				% 	imagesc((IcaTracesTmpDisplay(reponseScoreIdx,:)))
				% 	colorbar;xlabel('frames');ylabel('cells');
				% 	continue

				% 	%
				% 	for rowNo = 1:size(alignSignalAll,1)
				% 		rowIdx(rowNo,1) = find(alignSignalAll(rowNo,:)==max(alignSignalAll(rowNo,:)));
				% 		rowIdx(rowNo,2) = max(alignSignalAll(rowNo,:));
				% 	end
				% 	rowIdx = sum(rowIdx,2);
				% 	[responseN reponseScoreIdx] = sort(rowIdx,'descend');
				% 	%
				% 	imagesc(alignSignalAll(reponseScoreIdx,:))
				% 	colorbar;xlabel('frames');ylabel('cells');
				% 	continue

					% M = size(IcaTracesTmp,1);
					% N = size(IcaTracesTmp,2);
					% hold on
					% for k = floor(lenTimeSeq/2):lenTimeSeq:N
					%     x = [k k];
					%     y = [1 M];
					%     plot(x,y,'Color','r','LineStyle','-','LineWidth',1);
					%     % plot(x,y,'Color','k','LineStyle',':');
					% end
					% thisIdx = 1;
					% for k = 0:lenTimeSeq:N
					% 	if k==N
					% 		continue
					% 	end
					%     x = [k k];
					%     y = [1 M];
					%     plot(x,y,'Color','k','LineStyle','-');

					%     % text(k+round(lenTimeSeq/2),-15,num2str(obj.assayNum{globalStimIdx{stimNo}{thisIdx}}),'FontSize',8);
					%     % sessionTypeIdx = find(strcmp(assayTypeList,obj.assayType{globalStimIdx{stimNo}{thisIdx}}));
					%     % rectangle('Position',[k,0,lenTimeSeq,sessionTypeIndicatorHeight],'EdgeColor',sessionTypeColors(sessionTypeIdx,:),'FaceColor',sessionTypeColors(sessionTypeIdx,:))
					%     thisIdx = thisIdx+1;
					%     % plot(x,y,'Color','k','LineStyle',':');
					%     % insertText(movieTmp(:,:,frameNo),[0 0],[fileInfo.subject '_' fileInfo.assay],...
					%     % 'BoxColor','white',...
					%     % 'AnchorPoint','LeftTop',...
					%     % 'BoxOpacity',1)
					% end
					% hold off

				if size(IcaTracesTmp,1)>=numSignalsToDisplay;endAmt=numSignalsToDisplay;else endAmt=size(IcaTracesTmp,1);end
				IcaTracesTmp = IcaTracesTmp(1:endAmt,:);
				IcaFiltersTmpTmp = IcaFiltersTmp(1:endAmt,:,:);
				signalPeaksTmp = signalPeaksTmp(1:endAmt,:);
				signalPeaksArrayTmp = signalPeaksArrayTmp(1:endAmt);

				[signalSnr a] = computeSignalSnr(IcaTracesTmp,'testpeaks',signalPeaksTmp,'testpeaksArray',signalPeaksArrayTmp);
				[signalSnr sortedIdx] = sort(signalSnr,'descend');
				% [signalSnr sortedIdx] = sort(signalSnr,'descend');
				IcaTracesTmp = IcaTracesTmp(sortedIdx,:);
				IcaFiltersTmp(1:endAmt,:,:) = IcaFiltersTmpTmp(sortedIdx,:,:);
				signalPeaksTmp = signalPeaksTmp(sortedIdx,:);
				signalPeaksArrayTmp = signalPeaksArrayTmp(sortedIdx);

				[xPlot yPlot] = getSubplotDimensions(size(IcaTracesTmp,1)+1);
				wSize = 0.01;
				% ha = tight_subplot(Nh, Nw, gap, marg_h, marg_w)
				[~, ~] = openFigure(777, '');
				ha = tight_subplot(xPlot,yPlot,[wSize wSize],[wSize*6 wSize*6],[wSize*2 *7 wSize]);
				% [~, ~] = openFigure(778, '');
					% haLine = tight_subplot(xPlot*yPlot,1,[wSize wSize],[wSize wSize],[wSize*7 wSize]);
				minValTraces = nanmin(IcaTracesTmp(:));
				maxValTraces = nanmax(IcaTracesTmp(:));

				[~, ~] = openFigure(777, '');
				axes(ha(1));
					[groupedImagesRates] = groupImagesByColor(IcaFiltersTmp,[1:endAmt repmat(0.8,[1 size(IcaFiltersTmp,1)-endAmt])]);
					thisCellmap = createObjMap(groupedImagesRates);
					imagesc(thisCellmap);
					% colorbar;
					axis off;box on;
					colormap(obj.colormap);
				for idNumSubplot = 1:size(IcaTracesTmp,1)
					% [~, ~] = openFigure(778, '');
						IcaTracesTmpTmp = IcaTracesTmp(idNumSubplot,:);
						% axes(haLine(idNumSubplot));
						% plot(IcaTracesTmpTmp(:))

					% subplot(xPlot,yPlot,idNumSubplot)
					[~, ~] = openFigure(777, '');
					axes(ha(idNumSubplot+1));

					% viewLineFilledError(nanmean(IcaTracesTmpTmp(:)),nanstd(IcaTracesTmpTmp(:)),'xValues',timeSeq);
					viewLineFilledError(repmat(nanmean(IcaTracesTmpTmp(:)),[1 length(timeVector)]),repmat(nanstd(IcaTracesTmpTmp(:)),[1 length(timeVector)]),'lineColor',repmat(0.9,[1 3]),'xValues',timeVector/framesPerSecond);
					hold on;

					% add in zero line
					xval = 0;
					x=[xval,xval];
					% y=[minValTraces maxValTraces];
					y=[minValTraces maxValTraces*0.75];
					plot(x,y,'r'); box off;
					hold on

					% size(peakIdxs)
					x = reshape(IcaTracesTmpTmp(peakIdxs),size(peakIdxs))';
					% size(x)
					% imagesc(x)
					plot(repmat(timeVector/framesPerSecond, [size(x,1) 1])', x','Color',[4 4 4]/8)
					% plotSignalsGraph(x','LineWidth',2.5);
					hold on;
					plot(timeVector/framesPerSecond, nanmean(x,1),'k', 'LineWidth',3);box off;

					% add in detected peaks
					f = framesToAlign(:);
					% IcaTracesTmpTmp(signalPeaksArrayTmp{idNumSubplot})
					peakArrayTmp = signalPeaksArrayTmp{idNumSubplot};
					peakArrayTmp = intersect(peakIdxs,peakArrayTmp);
					for testPeakNo=1:length(peakArrayTmp)
						testPeakIdx = peakArrayTmp(testPeakNo);
						[c index] = min(abs(f-testPeakIdx));
						closestValues = f(index); % Finds first one only!
						% testPeakIdx-closestValues
						scatter((testPeakIdx-closestValues)/framesPerSecond, IcaTracesTmpTmp(testPeakIdx),10,'LineWidth',0.1,'MarkerFaceColor',[0 0 0], 'MarkerEdgeColor',[0 0 0]);
					end
					if idNumSubplot==(yPlot)
						hold off;
						% title(['signal transients '])
						xlabel('seconds','fontsize',20);ylabel('\DeltaF/F','fontsize',20);
						ylim([minValTraces maxValTraces]);
					else
						axis off;
						box off;
					end
					axis tight
				end
				suptitle([subjAssayIDStr ' | ' nameArray{idNum} ' | ' num2str(length(framesToAlign(:))) ' | red = stimulus, gray = 2\sigma signal']);
				% ginput(1);
				drawnow
				set(gcf,'PaperUnits','inches','PaperPosition',[0 0 15 7])
				obj.modelSaveImgToFile([],['stimTrigTracesIndividual_' filesep saveNameArray{idNum}],'current',[]);
				% ===============================================================
				% pause
				if allTracePlotShow==1
					[~, ~] = openFigure(779, '');
					% size(IcaTracesTmp)
					% if size(IcaTracesTmp,1)>=numSignalsToDisplay;endAmt=numSignalsToDisplay;else endAmt=size(IcaTracesTmp,1);end
					% peakIdxs(:)
					for i=2:size(IcaTracesTmp,1)
						movAvgFiltSize = 3;
						IcaTracesTmp(i,:) = filtfilt(ones(1,movAvgFiltSize)/movAvgFiltSize,1,IcaTracesTmp(i,:));
					end
					offset = length(timeVector)/2;
					peakIdxsTmp = peakIdxs(:);
					IcaTracesTmp(:,peakIdxsTmp(find(diff(peakIdxsTmp)>1))) = NaN;
					IcaTracesTmp = IcaTracesTmp(:,peakIdxs(:));
					removeIdx = length(timeVector):length(timeVector):size(IcaTracesTmp,2);
					IcaTracesTmp(:,removeIdx) = NaN;
					% imagesc(IcaTracesTmp*2)
					plotSignalsGraph(IcaTracesTmp,'LineWidth',1.5);
					% centerLineoffset = length(timeVector)-postOffset;
					lineLoc = -postOffset;
					areaBegin = -2*offset;
					areaEnd = 0;
					for frame=0:(length(framesToAlign)-1)
						yL = get(gca,'YLim');
						lineLoc = lineLoc+2*offset;
						areaBegin = areaBegin+2*offset;
						areaEnd = areaEnd+2*offset;
						if mod(frame,2)==0
							hold on;
							H = area([areaBegin areaEnd], [yL(2) yL(2)]);
							h=get(H,'children');
							% set(h,'FaceAlpha',0.5,'FaceColor',[0.9 0.9 0.9],'EdgeColor','none');
							set(h,'FaceColor',[0.95 0.95 0.95],'EdgeColor','none');
							hold on;
						else
							hold on;
							H = area([areaBegin areaEnd], [yL(2) yL(2)]);
							h=get(H,'children');
							% set(h,'FaceAlpha',0.5,'FaceColor',[0.7 0.7 0.7],'EdgeColor','none');
							set(h,'FaceColor',[0.85 0.85 0.85],'EdgeColor','none');
							hold on;
						end
						line([lineLoc lineLoc],yL,'Color','r','LineWidth',1);
						% [lineLoc2-2*offset+1 lineLoc2]
						% [yL yL]
						% line([lineLoc2 lineLoc2],yL,'Color','g');
					end
					hold on;
					% imagesc(IcaTracesTmp*2); colormap gray;
					plotSignalsGraph(IcaTracesTmp,'LineWidth',1.5);
					xAxisLabels = 0/framesPerSecond:10:size(IcaTracesTmp,2)/framesPerSecond;
					NumTicks = length(xAxisLabels);
					L = get(gca,'XLim');
					set(gca,'XTick',linspace(L(1),L(2),NumTicks))
					set(gca,'XTickLabel',xAxisLabels)
					hold off;

					xlabel('seconds','fontsize',40);ylabel('\DeltaF/F','fontsize',40);
					title([subjAssayIDStr ' | ' nameArray{idNum} ' | red = stimulus, gray = cropped region']);
				end
				% ginput(1);
				% ===============================================================
				drawnow
				idNumCounter = idNumCounter + 1;
				set(gcf,'PaperUnits','inches','PaperPosition',[0 0 20 10])
				obj.modelSaveImgToFile([],['stimTrigTraces_' filesep saveNameArray{idNum}],'current',[]);
				% pause
			catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
			end
		end
		% close(figNoAll);

		% obj.figNoAll = obj.figNoAll + 1;
		% obj.figNo = figNo;
		% obj.figNames = figNames;
	end
end
function [inputMovie] = convertInputMovieToCell(inputMovie)
    %Get dimension information about 3D movie matrix
    [inputMovieX inputMovieY inputMovieZ] = size(inputMovie);
    reshapeValue = size(inputMovie);
    %Convert array to cell array, allows slicing (not contiguous memory block)
    inputMovie = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
end
function [inputMovie] = tmpFunctionHere(inputMovie)
	[~, ~] = openFigure(776, '');
		options.videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
		vidList = getFileList(obj.videoDir,options.videoTrialRegExp);
		[xPlot yPlot] = getSubplotDimensions(length(framesToAlign));
		downsampleFactor = 4;
		length(framesToAlign)
		for trialNo = 1:length(framesToAlign)
			% subplot(xPlot,yPlot,trialNo)
			% behaviorMovie2 = loadMovieList(vidList,'convertToDouble',0,'frameList',bsxfun(@plus,framesToAlign(trialNo),0:2)*downsampleFactor,'treatMoviesAsContinuous',1);
			thisMovie1 = convertInputMovieToCell(loadMovieList(vidList,'convertToDouble',0,'frameList',bsxfun(@plus,framesToAlign(trialNo),-2:2)*downsampleFactor,'treatMoviesAsContinuous',1));
			thisMovie1 = cat(2,thisMovie1{:});
			imagesc(thisMovie1);
			ginput(1);
		end
		% continue
end