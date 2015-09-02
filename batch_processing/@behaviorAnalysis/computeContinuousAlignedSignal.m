function obj = computeContinuousAlignedSignal(obj)
	% align signal to a stimulus and display images
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

	%========================
	% continuous variables to analyze
	options.var1 = 'XM_cm';%XM_cm
	options.var2 = 'YM_cm';%YM_cm
	options.var3 = 'Angle';
	% cutoff value for velocity in open field analysis
	options.STIM_CUTOFF = 1.5;
	% options.STIM_CUTOFF = 0.05;
	% get options
	% options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% display('NOT FULLY CONVERTED TO CLASS METHOD YET...')
	% return

	% if strcmp(obj.analysisType,'group')
	% 	nFiles = length(obj.rawSignals);
	% else
	% 	nFiles = 1;
	% end
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:length(fileIdxArray)
		thisFileNum = fileIdxArray(thisFileNumIdx);
		fileNum = thisFileNum;
		obj.fileNum = thisFileNum;
		display(repmat('=',1,21))
		display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
		% =====================
		% videoTrialRegExpList = {'yyyy_mm_dd_pNNN_mNNN_assayNN','yymmdd-mNNN-assayNN','subject_assay'};
		% [videoTrialRegExpIdx, ok] = listdlg('ListString',videoTrialRegExpList,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','video string type (N = number)');
		% switch videoTrialRegExpIdx
		% 	case 1
		% 		options.videoTrialRegExp = fileFilterRegexp
		% 	case 2
		% 		options.videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
		% 	case 3
		% 		options.videoTrialRegExp = [obj.subjectStr{obj.fileNum} '_' obj.assay{obj.fileNum}]
		% 	otherwise
		% 		options.videoTrialRegExp = fileFilterRegexp
		% end

		% =====================
		% for backwards compatibility, will be removed in the future.
		nameArray = obj.continuousStimulusNameArray;
		saveNameArray = obj.continuousStimulusSaveNameArray;
		idArray = obj.continuousStimulusIdArray;
		% assayTable = obj.discreteStimulusTable;
		%
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		if isempty(IcaTraces); continue; end;
		nSignals = size(IcaTraces,1);
		%
		usTimeAfterCS = 10;
		options.dfofAnalysis = obj.dfofAnalysis;
		options.stimTriggerOnset = obj.stimTriggerOnset;
		options.picsSavePath = obj.picsSavePath;
		thisFileID = obj.fileIDArray{obj.fileNum};
		timeSeq = obj.timeSequence;
		subject = obj.subjectNum{obj.fileNum};
		subjectStr = obj.subjectStr{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		assayType = obj.assayType{obj.fileNum};
		framesPerSecond = obj.FRAMES_PER_SECOND;
		pxToCm = 1;
		picsSavePath = obj.picsSavePath;
		% obj.sumStats = [];
		% obj.sumStats.subject{end+1,1} = obj.subjectStr{obj.fileNum};
		% obj.sumStats.assay{end+1,1} = obj.assay{obj.fileNum};
		% obj.sumStats.assayType{end+1,1} = obj.assayType{obj.fileNum};
		% obj.sumStats.assayNum{end+1,1} = obj.assayNum{obj.fileNum};
		% obj.sumStats.stimulus{end+1,1} = obj.stimulusNameArray{obj.stimNum};
		% =====================
		nIDs = length(obj.stimulusNameArray);
		colorArray = hsv(nIDs);
		idNumCounter = 1;
		% =====================
		% CROSS-SUBJECT FIGURES
        subjectSetType = obj.assayType;
		% get a unique list of all subject types
        subjectSetTypeList = unique(subjectSetType);
		% ostruct.lists.subjectType = unique(ostruct.tables.subjectTable.type);
		% construct a pseudo-hash table for type to color
		typeColorsList = hsv(length(subjectSetTypeList));
		colorIdx = find(strmatch(assayType,subjectSetTypeList));
	    thisSubjType = assayType;
		subjColor = typeColorsList(colorIdx,:);
		% =====================
		% used to save files and make graphs
		thisID = strcat(subjectStr,'\_',assayType,'\_',assay);
		thisFileID = strcat(subjectStr,'_',assayType,'_',assay);
		% =====================
		% obtain stimulus information
		class(idArray(find(ismember(nameArray,options.var1))))
		iioptions.array = 'continuousStimulusArray';
		iioptions.nameArray = 'continuousStimulusNameArray';
		iioptions.idArray = 'continuousStimulusIdArray';
		iioptions.stimFramesOnly = 1;
		movement.XM = obj.modelGetStim(idArray(find(ismember(nameArray,options.var1))),'options',iioptions);
		movement.YM = obj.modelGetStim(idArray(find(ismember(nameArray,options.var2))),'options',iioptions);
		movement.Angle = obj.modelGetStim(idArray(find(ismember(nameArray,options.var3))),'options',iioptions);
		% if isempty(stimVector); continue; end;
	    % =====================
		% get the movement comparison data
		% movement.XM = movement.XM*framesPerSecond/pxToCm;
		% movement.YM = movement.YM*framesPerSecond/pxToCm;
		outputData = compareSignalToMovement(IcaTraces,movement,'makePlots',1,'signalPeaks',signalPeaks,'signalPeakIdx',signalPeaksArray);
	    % =====================
	    % stim constants
	    STIM_CUTOFF = options.STIM_CUTOFF;
	    % subject = str2num(strrep(strrep(ostruct.subject{fileNum},'m',''),'f',''));
	    % ostruct.curentSubject = ostruct.subject{fileNum};
	    % assay = ostruct.assay{fileNum};
	    % =====================
	    % YM = outputData.downsampledXM;
	    % XM = outputData.downsampledYM;
	    subjSpeed = outputData.downsampledVelocity*framesPerSecond;
	    percentSignalsActive = smooth(sum(signalPeaks,1),5,'moving')/size(signalPeaks,1);
	    obj = addValuesToDetailStats(obj,thisFileNumIdx,length(fileIdxArray),subjSpeed,percentSignalsActive,{'speed_pactive'});
	    % [obj] = addValuesToDetailStats(obj,varX,varY,varType,subjectType)
	    % continue;
	    % =====================
	    %
		% thisVel = outputData.downsampledVelocity*options.framesPerSecond/(ostruct.sumStats.pxToCm(fileNum));
		thisVel = outputData.downsampledVelocity*framesPerSecond;
		% thisVel(:)'
		avgPeaksPerPt = outputData.avgPeaksPerPt*framesPerSecond;
		% avgPeaksPerPt = sum(IcaTraces,1);
		signalPeaks = outputData.signalPeaks;
		% signalPeaks = IcaTraces;
		signalPeaksRaw = IcaTraces;
	    stimVectorRaw = thisVel;
	    stimVector = thisVel>STIM_CUTOFF;
	    figure(929)
		    plot(thisVel,'r'); hold on;
		    plot(avgPeaksPerPt,'b'); hold off;
		    legend({'velocity','firing rate'})
	    % =====================
		% get the correlation between the two
		obj.sumStats.pearsonStimBehavior(fileNum,1) = corr(avgPeaksPerPt(:), stimVectorRaw(:),'type','Pearson');
	    obj.sumStats.spearmanStimBehavior(fileNum,1) = corr(avgPeaksPerPt(:), stimVectorRaw(:),'type','Spearman');
		fitvals = polyfit(avgPeaksPerPt, stimVectorRaw,1);
		obj.sumStats.slopeStimBehavior(fileNum,1) = fitvals(1);
	    % =====================
		% get percent time in center of arena
		YM = outputData.downsampledXM;
		XM = outputData.downsampledYM;
		maxX = max(XM);
		maxY = max(YM);
		minVal = 0.33; maxVal = 0.66;
		indxY = (YM>round(maxY*minVal))&(YM<round(maxY*maxVal));
		indxX = (XM>round(maxX*minVal))&(XM<round(maxX*maxVal));
		obj.sumStats.pctTimeCenter(fileNum,1) = sum(indxY&indxX)/length(XM);
	    % =====================
		% look at total movement
		obj.sumStats.totalDistance(fileNum,1) = sum(stimVectorRaw);

		% =====================
		% =====================
		viewLocationFiringRates()
		% =====================
		% =====================
		% look at movement in the video aligned
		% movieVelocity = outputData.velocity*options.framesPerSecond/(ostruct.sumStats.pxToCm(fileNum));
		% timeSeq = [-20:20];
		% nPoints = length(stimVectorRaw);
		% onsetIdx = find([0 diff(stimVector)]==1);
		% onsetIdx = onsetIdx*4;
		% peakIdxs = bsxfun(@plus,timeSeq',onsetIdx);
		% peakIdxs(find(peakIdxs<1)) = 1;
		% peakIdxs(find(peakIdxs>nPoints)) = 1;
		% inputVel = stimVectorRaw(ceil(peakIdxs(:)/4));
		% inputVel(inputVel>10) = NaN;
		% % peakIdxs
		% peakIdxs = peakIdxs(1:1000);
		% % behaviorMovie = behaviorMovie(:,:,peakIdxs);
		% % load movie
		% vidList = getFileList(options.videoDir,trialRegExp);
		% peakIdxs(:)
		% behaviorMovie = loadMovieList(vidList{1},'convertToDouble',options.convertToDouble,'frameList',peakIdxs(:));
		% playMovie(behaviorMovie,'extraLinePlot',inputVel);
		% playMovie(behaviorMovie);
		% =====================
		% ADD DISCRETE TABLE VECTOR
		display('adding movement values to discrete array...')
		stimVectorArray = {find([0 diff(stimVector)]==1), find([0 diff(stimVector)]==-1), find(stimVector), find(~stimVector)};
		for stimID = 1:length(stimVectorArray)
			obj.('discreteStimulusArray'){obj.fileNum}.(['s' num2str(stimID)]) = stimVectorArray{stimID};
		end
		obj.stimulusNameArray = {'movementInitiation','movementTermination','movementON','movementOFF'};
		obj.stimulusSaveNameArray = obj.stimulusNameArray;
		obj.stimulusIdArray = [1 2 3 4];
		obj.stimulusTimeSeq = {[-5:5],[-5:5],[0:10],[-10:0]};
		% return;
		% continue;
		% =====================
		timeSeq = [-20:20];
		nSignals = size(IcaTraces,1);
		% get the signal aligned to movement, initiation and termination
		nShuffles = 5;
		stimVectorArray = {stimVector, [0 diff(stimVector)]==1, [0 diff(stimVector)]==-1};
		stimNameArray = {'movementAll','movementInitiation','movementTermination'};
		for stimID = 1:length(stimVectorArray)
			signalAlignedMovement{stimID} = alignSignal(signalPeaksRaw, stimVectorArray{stimID},timeSeq,'overallAlign',1)/nSignals;
			% shuffle to get Z scores
			reverseStr = '';
			for i=1:nShuffles
				alignedSignalShuffled(:,i) = alignSignal(shuffleMatrix(signalPeaksRaw,'waitbarOn',0), stimVectorArray{stimID},timeSeq,'overallAlign',1)'/nSignals;
				% alignedSignalStimShuffled(:,i) = alignSignal(signalPeaks, shuffleMatrix(stimVector,'waitbarOn',0),timeSeq,'overallAlign',1)';
				reverseStr = cmdWaitbar(i,nShuffles,reverseStr,'inputStr','shuffling alignment','waitbarOn',1,'displayEvery',1);
			end
			alignedSignalShuffledMean = mean(alignedSignalShuffled,2);
			alignedSignalShuffledStd = std(alignedSignalShuffled,0,2);
			% alignedSignalShuffledMean
			% alignedSignalShuffledStd
			lenTimeseqHalf = floor(length(timeSeq)/2);
		    % calculate Zscore
		    zscores = (signalAlignedMovement{stimID}-alignedSignalShuffledMean)./alignedSignalShuffledStd;
		    signalAlignedMovementZscore{stimID} = zscores;
		    zscoresPost = sum(zscores(lenTimeseqHalf+1:end));
		    zscoresPre = sum(zscores(1:lenTimeseqHalf));
			% SUMMARY_STATS_ADD
			obj.sumStats.(strcat(stimNameArray{stimID},'ZscorePost'))(fileNum,1) = sum(zscoresPost);
			obj.sumStats.(strcat(stimNameArray{stimID},'ZscorePre'))(fileNum,1) = sum(zscoresPre);
			obj.sumStats.(strcat(stimNameArray{stimID},'Max'))(fileNum,1) = nanmax(signalAlignedMovement{stimID});
		end
	    % =====================
		% get the sliding correlation
	    windowSize = 1e3;
		[slidingCorrelation] = computeSlidingCorrelation(avgPeaksPerPt',stimVectorRaw','windowSize',windowSize);
		% ostruct.otherdata.slidingCorrelation{fileNum} = slidingCorrelation;
		% SUMMARY_STATS_ADD
		obj.sumStats.slidingCorrStd(fileNum,1) = nanstd(slidingCorrelation);
		obj.sumStats.slidingCorrVar(fileNum,1) = nanvar(slidingCorrelation);
	    obj.sumStats.slidingCorrSkew(fileNum,1) = skewness(slidingCorrelation);
	    obj.sumStats.slidingCorrKurt(fileNum,1) = kurtosis(slidingCorrelation);
	    % =====================
		% get mutual information
		% miScores = MutualInformation(stimVector,signalPeaks);
		miScoresShuffled = mutualInformationShuffle(stimVector,signalPeaks);
		miZscores = miScoresShuffled(:,4);
		obj.modelSaveImgToFile([],'MIShuffleScores_','current',strcat(thisFileID));
		% saveFile = char(strrep(strcat(picsSavePath,'MIShuffleScores_',thisFileID,'.png'),'/',''));
		% saveas(gcf,saveFile);
		% get number significantly modulated
		sigModSignals3s = miScoresShuffled(:,1)>(miScoresShuffled(:,2)+3*miScoresShuffled(:,3));
		sigModSignals = miScoresShuffled(:,1)>(miScoresShuffled(:,2)+1.96*miScoresShuffled(:,3));
		% SUMMARY_STATS_ADD
		obj.sumStats.pctMI3sigma(fileNum,1) = sum(sigModSignals3s)/length(sigModSignals3s);
		obj.sumStats.pctMI2sigma(fileNum,1) = sum(sigModSignals)/length(sigModSignals);

		% [mapFig ooo] = openFigure(3, '');
		% 	[groupedImagesMISig] = groupImagesByColor(IcaFilters,sigModSignals');
		% 	groupedImagesMISig = createObjMap(groupedImagesMISig);
		% 	imagesc(groupedImagesMISig); colormap hot; colorbar; axis square;
		% 	title([num2str(subject) '\_' assay]);
		% % ostruct = addValuesToBigData(ostruct,1:length(gfunction(:,nGroups)),gfunction(:,nGroups),{'gfunDist'},thisSubjType);
		% saveFile = char(strrep(strcat(options.picsSavePath,'MIShuffleScoresCellmap_',thisFileID,'.png'),'/',''));
		% saveas(gcf,saveFile);
		% =====================
		% get the grouped images
		% miScoresNormalized = normalizeVector(miScores);
		% miScoresGrouped = group_equally(miScores, 10);
		miScoresGrouped = sigModSignals;
		% [groupedImages] = groupImagesByColor(IcaFilters,miScoresGrouped+1);
		[groupedImages] = groupImagesByColor(IcaFilters,miZscores);
		groupedImageCellmap = createObjMap(groupedImages);
	    % =====================
	    % firing rate grouped images
	    numPeakEvents = sum(signalPeaks,2);
	    [groupedImagesRates] = groupImagesByColor(IcaFilters,numPeakEvents);
	    groupedImageCellmapRates = createObjMap(groupedImagesRates);
	    % firing rate histogram
	    maxPeakEvents = max(numPeakEvents)+(5-mod(max(numPeakEvents),5));
	    firingRateBins = 0:5:maxPeakEvents;
	    firingRateBinCounts = histc(numPeakEvents,firingRateBins);
	    % SUMMARY_STATS_ADD
	    obj.sumStats.meanNumPeaks(fileNum,1) = nanmean(numPeakEvents);
	    % =====================
	    % movement triggered maps
	    eventROI = [-2:2];
	    stimArray = {stimVector, ~stimVector};
	    for iStim = 1:length(stimArray)
	        nEvents = sum(stimArray{iStim})*length(eventROI);
	        alignedSignalObjs = alignSignal(signalPeaksRaw, stimArray{iStim},eventROI,'overallAlign',0);
	        alignedSignalObjsEvents{iStim} = sum(alignedSignalObjs,1)/nEvents;
	        maxVal(iStim) = max(alignedSignalObjsEvents{iStim});
	    end
	    alignedSignalObjsEvents{length(stimArray)+1} = alignedSignalObjsEvents{1} - alignedSignalObjsEvents{2}
	    % ./(alignedSignalObjsEvents{1} + alignedSignalObjsEvents{2});
	    maxVal = max(maxVal);
	    nameArrayTxt = {'stimulus','not stimulus','stimulus diff'};
	    for idNumTxt = 1:length(nameArrayTxt)
	        display(['analyzing ' nameArrayTxt{idNumTxt}]);
	        [mapFig ooo] = openFigure(2, '');
	        subplot(2,ceil(length(nameArrayTxt)/2),idNumTxt)
	        % add in fake filter for normalizing across trials
	        IcaFiltersTmp = IcaFilters;
	        if ~(idNumTxt==length(nameArrayTxt))
	            IcaFiltersTmp(end+1,:,:) = 0;
	            IcaFiltersTmp(end,1,1) = 1;
	            alignedSignalObjsEvents{idNumTxt}(end+1) = maxVal;
	        end
	        [groupedImagesRates] = groupImagesByColor(IcaFiltersTmp,alignedSignalObjsEvents{idNumTxt});
	        groupedImageCellmapRates = createObjMap(groupedImagesRates);
	        imagesc(groupedImageCellmapRates); axis square;
	        box off; axis off;
	        colormap(obj.colormap);cb = colorbar('location','southoutside');
	        title([num2str(subject) '\_' assay ' ' nameArrayTxt{idNumTxt}]);
	    end
	    obj.modelSaveImgToFile([],'movementOnOffCellmap_','current',strcat(thisFileID));
	    % saveFile = char(strrep(strcat(picsSavePath,'movementOnOffCellmap_',thisFileID,'.png'),'/',''));
	    % saveas(gcf,saveFile);
	    % pause
	    % =====================
		% get centroid locations along with distance matrix
		[xCoords yCoords] = findCentroid(IcaFilters);
		dist = pdist([xCoords(:) yCoords(:)]);
		npts = length(xCoords);
		distanceMatrix = diag(realmax*ones(1,npts))+squareform(dist);
		% calculate the G-function for each group
		uniqueGroups = unique(miScoresGrouped);
		nGroups = length(uniqueGroups);
		for groupNum=1:nGroups
		    groupId = uniqueGroups(groupNum);
		    groupIdx = find(miScoresGrouped==groupId);
			minDistances = min(distanceMatrix(groupIdx,groupIdx));
			% for i=1:ceil(max(dist))
			for i=1:50
				gfunction(i,groupNum)=sum(minDistances<=i)/length(minDistances);
			end
		end

		% get shuffled distributions
		nSignals = size(miScoresShuffled,1);
		nSignificantSignals = sum(miScoresGrouped);
		nShuffles = 20;
		for shuffleNo=1:nShuffles
			groupIdx = randsample(nSignals,nSignificantSignals,false);
			minDistances = min(distanceMatrix(groupIdx,groupIdx));
			for i=1:50
				gfunctionShuffled(i,shuffleNo)=sum(minDistances<=i)/length(minDistances);
			end
		end
		gfunctionShuffledMean = mean(gfunctionShuffled,2);
		gfunctionShuffledStd = std(gfunctionShuffled,0,2);

		for i=1:(nGroups-1)
			[ktestReject(i) ktestPval(i) ktestStat(i)]  = kstest2(gfunction(:,nGroups),gfunction(:,i),'Tail','unequal');
		end
		% SUMMARY_STATS_ADD
		% use the fisher to combine p-values
		obj.sumStats.gfunctionFisher(fileNum,1) = -2*nansum(log(ktestPval));
		%
		ktestReject = [ktestReject NaN];
		ktestStatStr = arrayfun(@(x) sprintf('p<0.05 = %d',x),ktestReject,'un',0);
		% = poissrnd(lambda,m,n,...)
		% clusters = kmeans([xCoords(:) yCoords(:)],10,'Distance','sqEuclidean');
		% scatter(xCoords, yCoords, 30, clusters, 'filled')
		% clusters = clusterdata([xCoords(:) yCoords(:)],'distance','euclidean','maxclust',10);
		% =================================================================
		% struct2table(ostruct.sumStats)
		% movTable = struct2table(obj.sumStats);
		% writetable(movTable,['private\data\' ostruct.info.protocol{fileNum} '_movementSummary.tab'],'FileType','text','Delimiter','\t');
		% =================================================================
		% FIGURES
		figNo = 400;
		% if ostruct.counter==1|~any(strcmp('plots',fieldnames(ostruct)))
		if thisFileNumIdx==1
			plots.figCount = 0;
			plots.plotCount = 1;
			plots.sheight = 2;
			plots.swidth = 3;
		end

		nSignals = size(IcaTraces,1);
	    % =======
		% look at MI score distribution
	  %   [figHandle figNo] = openFigure(figNo, '');
			% hist(sum(miScores,2),30);box off;
			% title(['distribution of MI scores for ' ostruct.subject{fileNum}]);
			% xlabel('MI score');ylabel('count');
			% h = findobj(gca,'Type','patch');
			% set(h,'FaceColor',[0 0 0],'EdgeColor','w');
			% saveFile = char(strrep(strcat(options.picsSavePath,'MIscores_',thisFileID,'.png'),'/',''));
			% saveas(gcf,saveFile);
			% hold off;
		% =======
		[figHandle figNo] = openFigure(figNo, '');
			viewLineFilledError(gfunctionShuffledMean,gfunctionShuffledStd);
	    	hold on;
	    	plot(gfunction);box off; xlabel('distance (px)'); ylabel('G(d)');
	    	title(strcat(thisID, ', ', num2str(nSignals), ' | G-function distributions (i.e. spatial clustering)'));
	    	legend({'shuffled std','shuffled mean','not significant','significant'},'Location','SouthEast')
	    	obj.modelSaveImgToFile([],'Gfunction_MI_cellDistances_','current',strcat(thisFileID));
	    	% saveFile = char(strrep(strcat(picsSavePath,'Gfunction_MI_cellDistances_',thisFileID,'.png'),'/',''));
	    	% saveas(gcf,saveFile);
	    	hold off;
	    % =======
		% plot the cells colored by MI percentile
		[figHandle figNo] = openFigure(figNo, '');
			imagesc(groupedImageCellmap);
			box off; axis off;
			colormap(obj.colormap);cb = colorbar('location','southoutside');
			title(strcat(thisID, ', ', num2str(nSignals), ' | MI z-scores'));
			obj.modelSaveImgToFile([],'cellmaps_MIcolored_','current',strcat(thisFileID));
			% saveFile = char(strrep(strcat(picsSavePath,'cellmaps_MIcolored_',thisFileID,'.png'),'/',''));
			% saveas(gcf,saveFile);
			hold off;
	    % =======
	    % plot the cells colored by transients
	    [figHandle figNo] = openFigure(figNo, '');
	        imagesc(groupedImageCellmapRates);
	        box off; axis off;
	        colormap(obj.colormap);cb = colorbar('location','southoutside');
	        title(strcat(thisID, ', ', num2str(nSignals), ' firing rate (Hz)'));
	        obj.modelSaveImgToFile([],'cellmaps_transients_','current',strcat(thisFileID));
	        % saveFile = char(strrep(strcat(picsSavePath,'cellmaps_transients_',thisFileID,'.png'),'/',''));
	        % saveFile = 'private\pics\da_sd.png';
	        % saveas(gcf,saveFile);
	        hold off;
	    % =======
		% plot scatterplots of the unique functions
		% [figHandle figNo] = openFigure(figNo, '');
		% 	uniqueGroups = unique(miScoresGrouped);
		% 	nGroups = length(uniqueGroups);
		% 	suptitle(strcat(thisID, ', ', num2str(nSignals), ' cells colored by MI score quantile'));
		% 	for groupNum=nGroups:-1:1
		% 	    groupId = uniqueGroups(groupNum);
		% 	    groupIdx = find(miScoresGrouped==groupId);
		% 	    subplot(4,ceil(nGroups/4),groupNum);
		% 	    scatter(xCoords(groupIdx),yCoords(groupIdx),30,miScoresGrouped(groupIdx),'filled');
		% 	    axis off;caxis([1 nGroups+1])
		% 	    if groupNum==1
		% 	       colorbar;
		% 	    end
		% 	end
		% 	saveFile = char(strrep(strcat(options.picsSavePath,'cellmaps_MIcolored_facet_',thisFileID,'.png'),'/',''));
		% 	saveas(gcf,saveFile);
		% 	hold off;
	    % =======
		% plot the G-function scores
		% [figHandle figNo] = openFigure(figNo, '');
		% 	plot(gfunction);box off; xlabel('distance (px)'); ylabel('G(d)');
		% 	set(gca,'ColorOrder',copper(nGroups)); hold on
		% 	plot(gfunction);box off; xlabel('distance (px)'); ylabel('G(d)');
		% 	title(strcat(thisID, ', ', num2str(nSignals), ' G-function of different MI groups, X^2 = ', num2str(ostruct.data.gfunctionFisher(fileNum,1))));
		% 	legend(ktestStatStr)
		% 	saveFile = char(strrep(strcat(options.picsSavePath,'Gfunction_MI_cellDistances',thisFileID,'.png'),'/',''));
		% 	saveas(gcf,saveFile);
		% 	hold off;
			% pause
	    % =======
		% plot the sliding correlation
		[figHandle figNo] = openFigure(figNo, '');
			plot(slidingCorrelation);box off;
			xlabel('frames');ylabel('corr');
			title(strcat(thisID, ', ', num2str(nSignals), ' signals, spike and movement correlation during trial'));
			obj.modelSaveImgToFile([],'spikeMovCorr_','current',strcat(thisFileID));
			% saveFile = char(strrep(strcat(picsSavePath,'spikeMovCorr_',thisFileID,'.png'),'/',''));
			% saveas(gcf,saveFile);
			hold off;
	    % =======
		% plot the movement triggered average
		alignStr = {'all movement','movement initiation','movement termination'};
		for iSigMov=1:length(signalAlignedMovement)
			[figHandle figNo] = openFigure(figNo, '');
				plot(timeSeq,signalAlignedMovement{iSigMov}');box off;
				xlabel('frames relative to stimulus');ylabel('peaks');
				title(strcat(thisID, ', ', num2str(nSignals), ' signals, firing relative to stimulus: ',alignStr{iSigMov}));
				obj.modelSaveImgToFile([],'movTriggeredFiring_','current',strcat(thisFileID));
				% saveFile = char(strrep(strcat(picsSavePath,'movTriggeredFiring_',thisFileID,'_',num2str(iSigMov),'.png'),'/',''));
				% saveFile = 'private\pics\da_sd.png';
				% saveas(gcf,saveFile);
				hold off;
		end
	    % =======
		% plot a heatmap of the location of the firing rates at each location
		[figHandle figNo] = openFigure(figNo, '');
			allIdx = [outputData.signalPeakIdx{:}];
			yAtPeaks = outputData.downsampledXM(allIdx);
			xAtPeaks = outputData.downsampledYM(allIdx);
			yNan = isnan(yAtPeaks(:));
			xNan = isnan(xAtPeaks(:));
			yAtPeaks(yNan|xNan) = [];
			xAtPeaks(yNan|xNan) = [];
			figHandle = smoothhist2D([yAtPeaks; xAtPeaks]',7,[100,100],0.05,'image');hold on;box off;
			colormap(flipud(gray))
			set(figHandle,'MarkerEdgeColor','k','MarkerSize',14);

			xflip = [outputData.downsampledXM(1 : end - 1) fliplr(outputData.downsampledXM)];
			yflip = [outputData.downsampledYM(1 : end - 1) fliplr(outputData.downsampledYM)];
			patch(xflip, yflip, 'r', 'EdgeColor','r','EdgeAlpha', 0.2, 'FaceColor', 'none');
			% plot(outputData.downsampledXM,outputData.downsampledYM,'r');hold on;box off;
			title(strcat(thisID, ', ', num2str(nSignals), ' signals, red = path, 2D histogram = firing intensity'));
			box off; axis off;
			% colorbar
			% plot(yAtPeaks,xAtPeaks,'k.','MarkerSize',14);hold off;drawnow
			obj.modelSaveImgToFile([],'mov_vs_peaks_','current',strcat(thisFileID));
			% saveFile = char(strrep(strcat(picsSavePath,'mov_vs_peaks_',thisFileID,'.png'),'/',''));
			% saveas(gcf,saveFile);
			% [x,y,reply]=ginput(1);
			hold off;

		% plot a heatmap of the location of the firing rates at each location
		[figHandle figNo] = openFigure(figNo, '');
			subplot(plots.sheight,plots.swidth,plots.plotCount);
			% outputData.downsampledXM(stimVector); outputData.downsampledYM(stimVector)
			yValCoords = outputData.downsampledXM(stimVector);
			xValCoords = outputData.downsampledYM(stimVector);
			yNan = isnan(yValCoords(:));
			xNan = isnan(xValCoords(:));
			yValCoords(yNan|xNan) = [];
			xValCoords(yNan|xNan) = [];
			figHandle = smoothhist2D([xValCoords;yValCoords]',7,[100,100],[],'image');hold on;box off;
			colormap(flipud(gray))
			xflip = [outputData.downsampledXM(1 : end - 1) fliplr(outputData.downsampledXM)];
			yflip = [outputData.downsampledYM(1 : end - 1) fliplr(outputData.downsampledYM)];
			set(figHandle,'MarkerEdgeColor','k','MarkerSize',14);
			patch(xflip(stimVector), yflip(stimVector), 'r', 'EdgeColor','r','EdgeAlpha', 0.2, 'FaceColor', 'none');
			% plot(outputData.downsampledXM,outputData.downsampledYM,'r');hold on;box off;
			box off; axis off;
			title(strcat(thisID, ', locations during movement'));
			% colorbar
			% plot(yAtPeaks,xAtPeaks,'k.','MarkerSize',14);hold off;drawnow
			obj.modelSaveImgToFile([],'all_mov_vs_peaks_fig','current',strcat(thisFileID));
			% saveFile = char(strrep(strcat(picsSavePath,'all_mov_vs_peaks_fig',num2str(plots.figCount),'.png'),'/',''));
			% saveas(gcf,saveFile);
			% [x,y,reply]=ginput(1);
			hold off;

		% ==============
		% CROSS-SUBJECT FIGURES
	    % initialize output of multi-animal data
	    if thisFileNum==1
	        obj.detailStats.frame = [];
	        obj.detailStats.value = [];
	        obj.detailStats.varType = {};
	        obj.detailStats.subjectType = {};
	        obj.detailStats.subject = {};
	    end
	    % =======
		% plot the movement triggered average for all subjects
		alignStr = {'all_movement','movement_initiation','movement_termination'};
		alignTitleStr = {'all movement','movement initiation','movement termination'};
	    normalizeList = {'normalized','unnormalized'};
	 %    for iLoop = 1:2
		% 	for iSigMov=1:length(signalAlignedMovement)
		% 		thisMov = signalAlignedMovement{iSigMov};
		% 		[figHandle figNo] = openFigure(figNo, '');
		% 			[legendHandle] = groupColorLegend(ostruct.lists.subjectType,ostruct.lists.typeColors);

		% 			if iLoop==1
		% 				% normalize vector
		% 				range = max(thisMov) - min(thisMov);
		% 				a = (thisMov - min(thisMov)) / range;
		% 			else
		% 				a = thisMov;
		% 			end
		%             % a = thisMov/nSignals;
		% 			phandle = plot(timeSeq,a','Color',ostruct.lists.typeColors(colorIdx,:));box off;
		% 			hold on;
		% 			xlabel('frames relative to stimulus');ylabel('peaks');
		% 			title(strcat(normalizeList{iLoop},': ',alignTitleStr{iSigMov}));
		% 			saveFile = char(strrep(strcat(options.picsSavePath,'all_signalAlignedMovement',normalizeList{iLoop},'_',num2str(iSigMov),'.png'),'/',''));
		% 			% saveFile = 'private\pics\da_sd.png';
		% 			saveas(gcf,saveFile);

		%             ostruct = addValuesToBigData(ostruct,timeSeq,a,{strcat(normalizeList{iLoop},'_',alignStr{iSigMov})},thisSubjType);
		% 	end
		% end
	    % =======
	    % z scores
		% plot the movement triggered average for all subjects
	    for iLoop = 1:2
			for iSigMov=1:length(signalAlignedMovementZscore)
				thisMov = signalAlignedMovementZscore{iSigMov};
				[figHandle figNo] = openFigure(figNo, '');
					[legendHandle] = groupColorLegend(subjectSetTypeList,typeColorsList);
					if iLoop==1
						% normalize vector
						range = max(thisMov) - min(thisMov);
						a = (thisMov - min(thisMov)) / range;
					else
						a = thisMov;
					end
		            % a = thisMov/nSignals;
					phandle = plot(timeSeq,a','Color',typeColorsList(colorIdx,:));box off;
					hold on;
					xlabel('frames relative to stimulus');ylabel('peaks');
					title(strcat(normalizeList{iLoop},' Zscores: ',alignTitleStr{iSigMov}));
					obj.modelSaveImgToFile([],strcat(options.picsSavePath,'all_signalAlignedMovementZscore_',normalizeList{iLoop},'_',num2str(iSigMov)),'current',strcat(thisFileID));
					% saveFile = char(strrep(strcat(options.picsSavePath,'all_signalAlignedMovementZscore_',normalizeList{iLoop},'_',num2str(iSigMov),'.png'),'/',''));
					% saveFile = 'private\pics\da_sd.png';
					% saveas(gcf,saveFile);

		            % ostruct = addValuesToBigData(ostruct,timeSeq,a,{strcat(normalizeList{iLoop},'_',alignStr{iSigMov},'_Zscore')},thisSubjType);
		            [obj] = addValuesToBigData(obj,timeSeq,a,{strcat(normalizeList{iLoop},'_',alignStr{iSigMov},'_Zscore')},thisSubjType);
			end
		end
	    % =======
	    % all subject sliding correlation
	    [figHandle figNo] = openFigure(figNo, '');
	        [legendHandle] = groupColorLegend(subjectSetTypeList,typeColorsList);
	        phandle = plot(slidingCorrelation,'Color',subjColor);box off;
	        hold on;
	        xlabel('frames');ylabel('corr');
	        title(['spike and movement correlation during trial, windows=' num2str(windowSize)]);

	        % obj.modelSaveImgToFile([],'all_spikeMovCorr_','current',strcat(thisFileID));
	        saveFile = char(strrep(strcat(picsSavePath,'all_spikeMovCorr_.png'),'/',''));
	        saveas(gcf,saveFile);
	    % =======
		% plot the cumulative movement for all subjects
		[figHandle figNo] = openFigure(figNo, '');
			[legendHandle] = groupColorLegend(subjectSetTypeList,typeColorsList);
			phandle = plot(cumsum(thisVel),'Color',subjColor);box off;
			hold on;
			xlabel('trial time (frames)');ylabel('velocity (cm/sec)');
			title('cumulative movement');

			% obj.modelSaveImgToFile([],'all_cumMovement_','current',strcat(thisFileID));
			saveFile = char(strrep(strcat(picsSavePath,'all_cumMovement_.png'),'/',''));
			saveas(gcf,saveFile);

	        % ostruct = addValuesToBigData(ostruct,1:length(thisVel),cumsum(thisVel),{'cumulative movement'},thisSubjType);
	    % =======
		% look at the distribution of simultaneous firing events
		[figHandle figNo] = openFigure(figNo, '');
			[legendHandle] = groupColorLegend(subjectSetTypeList,typeColorsList);
	        spreadPeakSignal = sum(spreadSignal(outputData.signalPeaks,'timeSeq',[-2:2]),1);
			maxH = max(spreadPeakSignal);
			histH = hist(spreadPeakSignal,[0:maxH]);
			plot([0:maxH], histH, 'Color', subjColor);box off;
			set(gca,'YScale','log');
			title('distribution simultaneous firing events');
			xlabel('simultaneous spikes');ylabel('count');
			hold on;

			saveFile = char(strrep(strcat(picsSavePath,'all_firingEventDist.png'),'/',''));
			saveas(gcf,saveFile);

	        obj = addValuesToBigData(obj,0:maxH,histH,{'simultaneousfiringEventsDist'},thisSubjType);
	    % =======
	    % look at the distribution of firing events
	    [figHandle figNo] = openFigure(figNo, '');
	        [legendHandle] = groupColorLegend(subjectSetTypeList,typeColorsList);
	        plot(firingRateBins, firingRateBinCounts, 'Color', subjColor);box off;
	        title('distribution of firing rates');
	        xlabel('firing rate');ylabel('count');
	        hold on;

	        saveFile = char(strrep(strcat(options.picsSavePath,'all_firingRateDist.png'),'/',''));
	        saveas(gcf,saveFile);

	        obj = addValuesToBigData(obj,firingRateBins,firingRateBinCounts,{'firingEventsDist'},thisSubjType);
	    % =======
		% look at the distribution of Gfunctions
		[figHandle figNo] = openFigure(figNo, '');
			for i=1:length(subjectSetTypeList)
			    plot(1,1,'Color',typeColorsList(i,:));
			    hold on
			end
			hleg1 = legend(subjectSetTypeList);

			plot(gfunction(:,nGroups), 'Color', subjColor);box off;
			xlabel('distance (px)'); ylabel('G(d)');
			title('G-function for highest scoring MI group');
			hold on;

			saveFile = char(strrep(strcat(picsSavePath,'all_Gfunction.png'),'/',''));
			saveas(gcf,saveFile);

	        obj = addValuesToBigData(obj,1:length(gfunction(:,nGroups)),gfunction(:,nGroups),{'gfunDist'},thisSubjType);
	    % =======
	    [figHandle figNo] = openFigure(figNo, '');
	        subplot(plots.sheight,plots.swidth,plots.plotCount);
	        	% scatter(outputData.avgPeaksPerPt, thisVel,[],~(thisVel<1),'Marker','.','SizeData',3);
	            % scatter(outputData.avgPeaksPerPt, thisVel,'Marker','.','SizeData',3,'MarkerFaceColor','k','MarkerEdgeColor','k');
	            plot(outputData.avgPeaksPerPt, thisVel,'.','MarkerSize',2,'MarkerFaceColor',subjColor,'MarkerEdgeColor',subjColor)
	        	title(strcat(subjectStr,'|',thisSubjType,'|',assay));
	        	if plots.plotCount==1
	        		xlabel('peaks/frame')
	        		ylabel('velocity')
	        	end
	        	set(gca,'xlim',[0 10],'ylim',[0 13]);
	        	fitVals = polyfit(outputData.avgPeaksPerPt, thisVel,1);
	        	refHandle = refline(fitVals(1),fitVals(2));
	        	set(gca,'Color','none'); box off;drawnow;
	            refHandle2 = refline(0,STIM_CUTOFF);
	            set(refHandle2,'Color','r')

	        saveFile = char(strrep(strcat(picsSavePath,'all_stim_vs_firing_fig',num2str(plots.figCount),'.png'),'/',''));
	        saveas(gcf,saveFile);
	    % =======
	    % increment file counter
	    % ostruct.counter = ostruct.counter+1;

	    % nameArray = {'velocity'};
	    % i = 1;
	    % plot velocity vs. firing rate
		% figure(655+plots.figCount)
		% 	subplot(5,ceil(nFiles/5),fileNum);
		% 		smoothhist2D([outputData.avgPeaksPerPt; thisVel]',7,[100,100],0,'image');
		% 		if fileNum==1
		% 			xlabel('firing rate (peaks/frame)')
		% 			ylabel([nameArray{i} ' (unit/frame)'])
		% 		end
		% struct2table(obj.bigData)
		if mod(plots.plotCount,plots.sheight*plots.swidth)==0
		   plots.figCount = plots.figCount+1;
		   plots.plotCount = 1;
		else
		   plots.plotCount = plots.plotCount+1;
		end
	end

	function [obj] = addValuesToBigData(obj,frame,value,varType,subjectType)
	    % small function to add values to big data
	    numPtsToAdd = length(frame(:));
	    obj.detailStats.frame(end+1:end+numPtsToAdd,1) = frame(:);
	    obj.detailStats.value(end+1:end+numPtsToAdd,1) = value(:);
	    obj.detailStats.varType(end+1:end+numPtsToAdd,1) = varType;
	    obj.detailStats.subjectType(end+1:end+numPtsToAdd,1) = {subjectType};
	    obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {obj.subjectStr{obj.fileNum}};
	end
	function [obj] = addValuesToDetailStats(obj,thisFileNumIdx,maxFiles,varX,varY,varType)
		if thisFileNumIdx==1
			obj.detailStats = [];
		    obj.detailStats.varX = [];
		    obj.detailStats.varY = [];
		    obj.detailStats.varType = {};
		    obj.detailStats.assay = {};
		    obj.detailStats.subject = {};
		end
	    % small function to add values to big data
	    numPtsToAdd = length(varX(:));
	    obj.detailStats.varX(end+1:end+numPtsToAdd,1) = varX(:);
	    obj.detailStats.varY(end+1:end+numPtsToAdd,1) = varY(:);
	    obj.detailStats.varType(end+1:end+numPtsToAdd,1) = varType;
	    obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {obj.assay{obj.fileNum}};
	    obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {obj.subjectStr{obj.fileNum}};
	    if thisFileNumIdx==maxFiles
	    	savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_continuousStim_bigData.tab'];
	    	display(['saving data to: ' savePath])
	    	obj.detailStats
	    	writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
	    	% obj.detailStats = [];
	    end
	end
	function viewLocationFiringRates()
		signal = 1;
		exitLoop = 0;
		nSignals = size(IcaTraces,1);
		directionOfNextChoice = 1;
		while exitLoop==0
		  plot(outputData.downsampledXM,outputData.downsampledYM,'r');hold on;box off;
		  title(['signal: ' num2str(signal) '/' num2str(nSignals)]);
		  yAtPeaks = outputData.downsampledXM(outputData.signalPeakIdx{signal});
		  xAtPeaks = outputData.downsampledYM(outputData.signalPeakIdx{signal});
		  plot(yAtPeaks,xAtPeaks,'k.','MarkerSize',14);hold off;drawnow
		  [x,y,reply]=ginput(1);
		  if isequal(reply, 28)
		        % go back, left
		        directionOfNextChoice=-1;
		    elseif isequal(reply, 29)
		        % go forward, right
		        directionOfNextChoice=1;
		  elseif isequal(reply, 102)
		      % user clicked 'f' for finished, exit loop
		      exitLoop=1;
		      % i=nFilters+1;
		  elseif isequal(reply, 103)
		      % if user clicks 'g' for goto, ask for which IC they want to see
		      icChange = inputdlg('enter IC #'); icChange = str2num(icChange{1});
		      if icChange>nFilters|icChange<1
		          % do nothing, invalid command
		      else
		          i = icChange;
		          directionOfNextChoice = 0;
		      end
		  else
		      directionOfNextChoice = 1;
		  end
		  signal = signal+directionOfNextChoice;
		  if signal<=0
		      i = nSignals;
		  elseif signal>nSignals;
		      i = 1;
		  end
		end
	end
end
function [inputMovies] = montageMovies(inputMovies)
	nMovies = length(inputMovies);
	[xPlot yPlot] = getSubplotDimensions(nMovies);
	% movieLengths = cellfun(@(x){size(x,3)},inputMovies);
	% maxMovieLength = max(movieLengths{:});
	inputMovieNo = 1;
	for xNo = 1:xPlot
		for yNo = 1:yPlot
			if inputMovieNo>length(inputMovies)
				[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},NaN(size(inputMovies{1})),'pxToCrop',[],'makeTimeEqualUsingNans',1);
			elseif yNo==1
				[behaviorMovie{xNo}] = inputMovies{inputMovieNo};
			else
				[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},inputMovies{inputMovieNo},'pxToCrop',[],'makeTimeEqualUsingNans',1);
			end
			size(behaviorMovie{xNo})
			inputMovieNo = inputMovieNo+1;
		end
	end
	size(behaviorMovie{1})
	behaviorMovie{1} = permute(behaviorMovie{1},[2 1 3]);
	size(behaviorMovie{1})
	display(repmat('-',1,7))
	for concatNo = 2:length(behaviorMovie)
		[behaviorMovie{1}] = createSideBySide(behaviorMovie{1},permute(behaviorMovie{concatNo},[2 1 3]),'pxToCrop',[],'makeTimeEqualUsingNans',1);
		behaviorMovie{concatNo} = {};
		size(behaviorMovie{1});
	end
	inputMovies = behaviorMovie{1};
	% behaviorMovie = cat(behaviorMovie{:},3)
end