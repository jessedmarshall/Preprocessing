function obj = viewCorr(obj)
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

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	obj.detailStats = [];
	obj.detailStats.distance = [];
    obj.detailStats.value = [];
    obj.detailStats.stimulus1 = {};
    obj.detailStats.corrGroup = {};
    obj.detailStats.subject = {};
    obj.detailStats.assay = {};
    obj.detailStats.assayType = {};
    obj.detailStats.assayNum = {};
	obj.detailStats

	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			nameArray = obj.stimulusNameArray;
			saveNameArray = obj.stimulusSaveNameArray;
			idArray = obj.stimulusIdArray;
			assayTable = obj.discreteStimulusTable;
			%
			[IcaTraces IcaFilters signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj);
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
			timeSeq = obj.timeSequence;
			framesPerSecond = obj.FRAMES_PER_SECOND;
			%
			subject = obj.subjectNum{obj.fileNum};
			assay = obj.assay{obj.fileNum};
			assayType = obj.assayType{obj.fileNum};
			assayNum = obj.assayNum{obj.fileNum};
			%
			if ~isempty(obj.sigModSignalsAll)
				sigModSignalsAll = obj.sigModSignalsAll{obj.fileNum};
				sigModIdx = 1;
				sigModSignalsAllTmp = zeros([nSignals nIDs]);
				for idIdx = 1:length(obj.stimulusNameArray)
					[stimVector] = modelGetStim(obj,idArray(idIdx));
					if ~isempty(stimVector)
						sigModSignalsAllTmp(:,idIdx) = obj.ttestSignSignals{obj.fileNum,idIdx};
						sigModIdx = sigModIdx + 1;
					end
				end
				sigModSignalsAll = sigModSignalsAllTmp;
				sigModSignalsAll = logical(sigModSignalsAll);
				% sigModSignalsAll
			else
				sigModSignalsAll = [];
			end
			% =====================
			postStimulusTimeSeq = obj.postStimulusTimeSeq;
			postStimulusTimeSeq = -10:10;
			MICRON_PER_PIXEL = obj.MICRON_PER_PIXEL;
			% =====================
			nIDs = length(obj.stimulusNameArray);
			colorArray = hsv(nIDs);
			idNumCounter = 1;
			% =====================
			% calculate pairwise distances
			try
				xCoords = obj.objLocations{obj.fileNum}(valid,1);
				yCoords = obj.objLocations{obj.fileNum}(valid,2);
			catch
				[xCoords yCoords] = findCentroid(IcaFilters);
				% continue;
			end
			dist = pdist([xCoords(:) yCoords(:)]);
			npts = length(xCoords);
			% distanceMatrix = diag(realmax*ones(1,npts))+squareform(dist);
			distanceMatrix = diag(zeros(1,npts))+squareform(dist);
			% =====================
			for idNum = 0:nIDs
				try
					% =====================
					if idNum==0
						signalPeaksTmp = signalPeaks;
						IcaTracesTmp = IcaTraces;
						% continue
						distanceMatrixTmp = distanceMatrix;
					else
						display(repmat('=',1,21))
						display([num2str(idNum) '/' num2str(nIDs) ': analyzing ' nameArray{idNum}])
						% get stimulus vector
						[stimVector] = modelGetStim(obj,idArray(idNum));
						% stimVector = output.stimVector;
						if isempty(stimVector);continue;end;
						stimIdx = find(stimVector);
						stimIdx = bsxfun(@plus,stimIdx(:),postStimulusTimeSeq(:)');
						signalPeaksTmp = signalPeaks(:,stimIdx);
						IcaTracesTmp = IcaTraces(:,stimIdx);
						distanceMatrixTmp = distanceMatrix;

						% if size(sigModSignalsAll,2)>idNum
						% 	signalPeaksTmp = signalPeaksTmp(sigModSignalsAll(:,idNum),:);
						% 	IcaTracesTmp = IcaTracesTmp(sigModSignalsAll(:,idNum),:);
						% 	distanceMatrixTmp = distanceMatrix(sigModSignalsAll(:,idNum),sigModSignalsAll(:,idNum));
						% else
						% 	continue;
						% end
					end

					viewPerCellCorr = 0;
					if viewPerCellCorr==1&&~isempty(sigModSignalsAll)
						idx1List = find(sigModSignalsAll(:,idNum));
						for idx1=1:length(idx1List)
							iii = idx1List(idx1);
							clf
							idx2List = find(sigModSignalsAll(:,idNum+1));
							subplotNum = 1;
							nIdx2 = 16;
							for idx2=1:nIdx2
								iii2 = idx2List(idx2);
								[xPlot yPlot] = getSubplotDimensions(nIdx2);
								subplot(xPlot,yPlot,subplotNum)
								thisStimSeq = -1:1;
								% ==================================
								[stimVector] = modelGetStim(obj,idArray(idNum));
								% stimVector = output.stimVector;
								if isempty(stimVector);continue;end;
								stimIdx = find(stimVector);
								stimIdx = bsxfun(@plus,stimIdx(:),thisStimSeq(:)');
								signalPeaksTmp = signalPeaks(:,stimIdx);
								IcaTracesTmp = IcaTraces(:,stimIdx);
								distanceMatrixTmp = distanceMatrix;
								% ==================================
								plot(IcaTracesTmp(iii,:),IcaTracesTmp(iii2,:),'r.','markersize',5);
								hold on;
								% ==================================
								[stimVector] = modelGetStim(obj,idArray(idNum+1));
								% stimVector = output.stimVector;
								if isempty(stimVector);continue;end;
								stimIdx = find(stimVector);
								stimIdx = bsxfun(@plus,stimIdx(:),thisStimSeq(:)');
								signalPeaksTmp = signalPeaks(:,stimIdx);
								IcaTracesTmp = IcaTraces(:,stimIdx);
								distanceMatrixTmp = distanceMatrix;
								% ==================================
								plot(IcaTracesTmp(iii,:),IcaTracesTmp(iii2,:),'b.','markersize',5)

								if subplotNum==1
									legend({nameArray{[idNum idNum+1]}})
								end
								title([num2str(iii) ' | ' num2str(iii2)])
								xlabel(num2str(iii));
								ylabel(num2str(iii2));
								drawnow
								subplotNum = subplotNum+1;
							end
							pause
						end
					end

					% [RHO,PVAL] = corr(IcaTracesTmp(:,:)',IcaTracesTmp(:,:)','type','Pearson');
					[RHO,PVAL] = corr(signalPeaksTmp(:,:)',signalPeaksTmp(:,:)','type','Pearson');
					RHO = diag(NaN(1,size(RHO,1)))+RHO;
					RHOtmp = RHO;
					corrGroup = 'all';
					addMetricDetailStats();

					% plot Rho vs. distance
					[figHandle ~] = openFigure(obj.figNoAll, '');
						if idNum==0;clf;end
						[xPlot yPlot] = getSubplotDimensions(nIDs+1);
						subplot(xPlot,yPlot,idNum+1)
						plot(distanceMatrixTmp(:)/MICRON_PER_PIXEL,RHOtmp(:),'k.', 'markersize', 1);
						if size(sigModSignalsAll,2)>idNum&idNum~=0&sum(sum(sigModSignalsAll(:,idNum)))>0
							hold on

							% sigModSignalsAll(:,idNum)
							distanceMatrixTmp = distanceMatrix(sigModSignalsAll(:,idNum),sigModSignalsAll(:,idNum));
							RHOtmp = RHO(sigModSignalsAll(:,idNum),sigModSignalsAll(:,idNum));
							plot(distanceMatrixTmp(:)/MICRON_PER_PIXEL,RHOtmp(:),'r+', 'markersize', 1);
							hold off
						end
						if idNum~=0
							title(nameArray{idNum})
							axis([0 xMAX -0.1 1]);
						else
							xlabel('distance (\mum)');
							ylabel('pairwise correlation (Pearson)');
							title('whole session');
							xMAX = nanmax(distanceMatrixTmp(:)/MICRON_PER_PIXEL);
							axis([0 xMAX -0.1 1]);
						end
						drawnow
					%
					[figHandle ~] = openFigure(obj.figNoAll+1, '');
						if idNum==0;clf;end
						[xPlot yPlot] = getSubplotDimensions(nIDs+1);
						subplot(xPlot,yPlot,idNum+1)
						bins=0:0.1:1;[n, xout] = hist(RHO(:),bins);bar(xout, n, 'barwidth', 1, 'basevalue', 1, 'FaceColor',[0 0 0]);set(gca,'YScale','log')
						if size(sigModSignalsAll,2)>idNum&idNum~=0&sum(sum(sigModSignalsAll(:,idNum)))>0
							hold on
							distanceMatrixTmp = distanceMatrix(sigModSignalsAll(:,idNum),sigModSignalsAll(:,idNum));
							RHOtmp = RHO(sigModSignalsAll(:,idNum),sigModSignalsAll(:,idNum));
							bins=0:0.1:1;[n, xout] = hist(RHOtmp(:),bins);bar(xout, n, 'barwidth', 1, 'basevalue', 1, 'FaceColor',[1 0 0]);set(gca,'YScale','log')
							hold off

							corrGroup = 'informative';
							addMetricDetailStats();
						end
						% axis tight;
						if idNum~=0
							title(nameArray{idNum})
							xlim([0 1])
						else
							xlabel('pairwise correlation (Pearson)');
							ylabel('count');
							title('whole session');
							xlim([0 1])
						end
						drawnow

					idNumCounter = idNumCounter + 1;
					% =====================
					analysisTwo = 0;
					if analysisTwo==1
						[figHandle ~] = openFigure(obj.figNoAll, '');
						% look at the pairwise correlation between the neurons
						[r p] = corrcoef(signalPeaksTmp(1:end,:)');
						corrLinkage = linkage(r,'average','euclidean');
						% corrLinkage
						% dendrogram(corrLinkage);
						% pause
						maxNumClusters = 10;
						% spikeCorrClusters = cluster(corrLinkage,'maxclust',maxNumClusters);
						spikeCorrClusters = cluster(corrLinkage,'cutoff',1.445,'criterion','distance');
						nSpikeCorrClusters = length(unique(spikeCorrClusters));
						[Y,idx] = sort(spikeCorrClusters,1,'ascend');
						correlationMatrixSorted = r(idx,idx);
						correlationMatrixSorted(correlationMatrixSorted==1) = NaN;
						[objmapSpikeCorrClusters] = groupImagesByColor(IcaFilters,spikeCorrClusters);
						objmapSpikeCorrClusters = createObjMap(objmapSpikeCorrClusters);
						objmapSpikeCorrClusters(1,1) = maxNumClusters;

						[xPlot yPlot] = getSubplotDimensions(nIDs+1);

						subplot(1,2,1)
						z=xcorr(signalPeaksTmp');
						z0 = zeros(size(signalPeaksTmp',2));
						zMax = max(z);
						z0 = reshape(zMax, [size(z0)]);
							imagesc(z0); colormap jet;
							title('spikes')
						subplot(1,2,2)
						z=xcorr(IcaTracesTmp');
						z0 = zeros(size(IcaTracesTmp',2));
						zMax = max(z);
						z0 = reshape(zMax, [size(z0)]);
							imagesc(z0); colormap jet;
							title('df/f')
						suptitle(subjAssayIDStr)
					end
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
			end
			nameColor1 = ['{\color[rgb]{',num2str([0 0 0]),'}all cells}'];
			nameColor2 = ['{\color[rgb]{',num2str([1 0 0]),'}informative cells}'];
			%
			[figHandle ~] = openFigure(obj.figNoAll, '');
			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 15 15])
			suptitle([subjAssayIDStr ' | ' nameColor1 ' | ' nameColor2])
			obj.modelSaveImgToFile([],'stimTrigCorr_','current',[]);
			%
			[figHandle ~] = openFigure(obj.figNoAll+1, '');
			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 15 15])
			suptitle([subjAssayIDStr ' | ' nameColor1 ' | ' nameColor2])
			obj.modelSaveImgToFile([],'stimTrigCorrHist_','current',[]);
			% close(figNoAll);

			% obj.figNoAll = obj.figNoAll + 1;
			% obj.figNo = figNo;
			% obj.figNames = figNames;
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end

	% write out summary statistics
    savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_corrStats.tab'];
    display(['saving data to: ' savePath])
	writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
	obj.detailStats = [];

	function addMetricDetailStats()
		% ========================
		x = distanceMatrixTmp(:)/MICRON_PER_PIXEL;
		y = RHOtmp(:);
		topEdge = 100; % define limits
		botEdge = 0; % define limits
		numBins = 10; % define number of bins

		binEdges = linspace(botEdge, topEdge, numBins+1);

		[h,whichBin] = histc(x, binEdges);

		for i = 1:numBins
		    flagBinMembers = (whichBin == i);
		    binMembers     = y(flagBinMembers);
		    binMean(i)     = nanmean(binMembers);
		end
		binEdges = binEdges(1:end-1);
		% plot(binEdges,binMean)

		% ========================
		numPtsToAdd = length(binEdges);
		% numPtsToAdd
		% metricLength = 1:length(mahalDistances);
		obj.detailStats.distance(end+1:end+numPtsToAdd,1) = binEdges(:);
		obj.detailStats.value(end+1:end+numPtsToAdd,1) = binMean(:);
		if idNum==0
			obj.detailStats.stimulus1(end+1:end+numPtsToAdd,1) = {'whole_trial'};
		else
			obj.detailStats.stimulus1(end+1:end+numPtsToAdd,1) = {nameArray{idNum}};
		end
		obj.detailStats.corrGroup(end+1:end+numPtsToAdd,1) = {corrGroup};
		obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {subject};
		obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
		obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayType};
		obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
		% ========================
	end
end

