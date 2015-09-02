function obj = viewObjmapStimTrig(obj)
	% plots an object map aligned to a stimulus
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

	for thisFileNumIdx = 1:nFilesToAnalyze
		thisFileNum = fileIdxArray(thisFileNumIdx);
		obj.fileNum = thisFileNum;
		display(repmat('=',1,21))
		display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
		% =====================
		% for backwards compatibility, will be removed in the future.
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		nIDs = length(obj.stimulusNameArray);
		nSignals = size(IcaTraces,1);
		%
		nameArray = obj.stimulusNameArray;
		idArray = obj.stimulusIdArray;
		%
		options.dfofAnalysis = obj.dfofAnalysis;
		timeSeq = obj.timeSequence;
		subject = obj.subjectNum{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		%
		framesPerSecond = obj.FRAMES_PER_SECOND;
		subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
		%
		figNoAll = obj.figNoAll;
		figNo = obj.figNo;
		figNames = obj.figNames;
		% magic numbers!
		% amount of time to make object maps before/after a stimulus
		prepostTime = 10;
		% =====================
		idNumCounter = 1;
		nIDs = length(idNumIdxArray);
		for idNumIdx = 1:length(idNumIdxArray)
			try
				idNum = idNumIdxArray(idNumIdx);
				obj.stimNum = idNum;
				display(repmat('=',1,7))
				display([num2str(idNum) '/' num2str(nIDs) ': analyzing ' nameArray{idNum}])
				% ============================
				% stimVector = obj.stimulusVectorArray{obj.fileNum,idNum};
				stimVector = obj.modelGetStim(idArray(idNum));
				if isempty(stimVector); continue; end;
				% ============================
				figNames{figNoAll} = 'stimTriggeredAvg_cellmaps_';
				[figNo{figNoAll}, ~] = openFigure(figNoAll, '');
				% [figNo{2}, ~] = openFigure(2, '');
			    if idNumCounter==1
					suptitle([subjAssayIDStr ' | stimulus triggered cell maps',10,10])
				end
				[xPlot yPlot] = getSubplotDimensions(nIDs+1);
			    subplot(xPlot,yPlot,idNumIdx)
			    	alignedSignalCells = alignSignal(signalPeaks, stimVector,[-prepostTime:prepostTime],'overallAlign',0);
			    	alignedSignalCellsSum = sum(alignedSignalCells,1)/sum(stimVector);
			        % add in fake filter for normalizing across trials
			        IcaFiltersTmp = IcaFilters;
			        % IcaFiltersTmp(end+1,:,:) = 0;
			        % IcaFiltersTmp(end,1,1) = 1;
			        % alignedSignalCellsSum(end+1) = 20;
			        % =====================
			        [groupedImagesRates] = groupImagesByColor(IcaFiltersTmp,alignedSignalCellsSum);
			        groupedImageCellmapRates = createObjMap(groupedImagesRates);
			        imagesc(groupedImageCellmapRates);
			        axis square; box off; axis off;
			        colormap(obj.colormap);
			        cb = colorbar('location','southoutside');
			        if options.dfofAnalysis==1
			        	xlabel(cb, '\DeltaF/F/stimulus');
			        else
			        	xlabel(cb, 'spikes/stimulus');
			        end
			        title([nameArray{idNum}]);
			        set(gcf, 'PaperUnits', 'centimeters');
			        set(gcf, 'PaperPosition', [0 0 25 9]); %x_width=10cm y_width=15cm
		    		obj.modelSaveImgToFile([],'stimTrigAvgObj_','current',[]);
			    % ============================
			    alignTypeStr = 'meanTrialIdx:[nSignals nAlignmemts]';
			    alignTypeStr = 'count:[nSignals nAlignmemts]';
	        	alignedSignalPerTrial{1} = alignSignal(signalPeaks, stimVector,0:prepostTime,'returnFormat',alignTypeStr);
	        	alignedSignalPerTrial{2} = alignSignal(signalPeaks, stimVector,-prepostTime:0,'returnFormat',alignTypeStr);
	        	alignStrArray = {'post' 'pre'};
	        	% alignStrArray = {'post'};
	        	nAlignTypes = length(alignStrArray);
        		for alignNo = 1:nAlignTypes
        			[figNo{figNoAll}, ~] = openFigure(figNoAll+alignNo, '');
        				clf
						plotNumberOfStimuli();
						% plotRelativeTimeStimuli();
	        	end
			    idNumCounter = idNumCounter + 1;
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
	function plotNumberOfStimuli()
		postIdx = sum(alignedSignalPerTrial{alignNo},2);
    	[groupedImagesRates] = groupImagesByColor(IcaFilters,postIdx+0.1);
    	groupedImageCellmapRates = createObjMap(groupedImagesRates);
        imagesc(groupedImageCellmapRates);
        box off; axis off;
        colormap(obj.colormap);
        h = colorbar('location','westoutside');
        ylabel(h, 'number of stimuli responses','fontsize',20)
   		h = suptitle([subjAssayIDStr ' | ' nameArray{idNum} ' | ' alignStrArray{alignNo} ' | per trial obj map']);
   		set(h,'fontsize',20)
		obj.modelSaveImgToFile([],'stimTrigAvgObjIdx_','current',[obj.fileIDArray{obj.fileNum} '_' obj.stimulusSaveNameArray{idNum} '_' alignStrArray{alignNo}]);
	end
	function plotRelativeTimeStimuli()
		alignMax = nanmax(alignedSignalPerTrial{alignNo}(:));
    	alignMin = nanmin(alignedSignalPerTrial{alignNo}(:));
    	postIdx = nanmean(alignedSignalPerTrial{alignNo},2);
    	postIdx(isnan(postIdx)) = alignMin-1;
    	minIdx = abs(min(postIdx)-1);
    	postIdx = postIdx + minIdx;
    	[groupedImagesRates] = groupImagesByColor(IcaFilters,postIdx+0.1);
    	groupedImageCellmapRates = createObjMap(groupedImagesRates);
    	groupedImageCellmapRates = groupedImageCellmapRates - minIdx;
    	groupedImageCellmapRates(1,1) = prepostTime;
    	groupedImageCellmapRates(1,2) = -prepostTime;
    	% groupedImageCellmapRates = groupedImageCellmapRates + abs(alignMin-1);
    	groupedImageCellmapRates(groupedImageCellmapRates==(alignMin-2)) = NaN;
        imagesc(groupedImageCellmapRates);
        box off; axis off;
        % colormap(customColormap({[1 1 1], [0 0 0], [1 1 0], [0 1 0], [0 0 1], [1 0 0]}));
        colormap(customColormap({[1 1 1], [0 0 0], [0 0 1], [0 1 0], [1 0 0], [1 0 0]}));
        h = colorbar('location','westoutside');
        set(gca, 'CLim', [-prepostTime-2, prepostTime])
        % set(h, 'YTick', [alignMin-1::alignMax],'fontsize',20)
        % set(h, 'YTick', round(linspace(alignMin-1,alignMax,5)))
        set(h, 'YTick', round(linspace(-prepostTime-2,prepostTime,5)))
        ylabel(h, 'frames relative to stimulus','fontsize',20)
        % set(h,'YTickLabel',{num2str(alignMin-1) ,num2str(alignMax)})
        % pause
   		h = suptitle([subjAssayIDStr ' | ' nameArray{idNum} ' | ' alignStrArray{alignNo} ' | per trial obj map']);
   		set(h,'fontsize',20)
		obj.modelSaveImgToFile([],'stimTrigAvgObjIdx_','current',[obj.fileIDArray{obj.fileNum} '_' obj.stimulusSaveNameArray{idNum} '_' alignStrArray{alignNo}]);
	end
	function plotExtraStuff()
		    % figNames{figNoAll} = 'stimTriggeredAvg_cellmaps_';
		    % [figNo{figNoAll}, ~] = openFigure(figNoAll+2, '');
	  %   	%
	     %    % alignedSignalPerTrial{1} = alignSignal(signalPeaks, stimVector,0:prepostTime,'returnFormat','count:[nSignals nAlignmemts]');
	     %    % alignedSignalPerTrial{2} = alignSignal(signalPeaks, stimVector,-prepostTime:0,'returnFormat','count:[nSignals nAlignmemts]');
	     %    nTrials = size(alignedSignalPerTrial{1},2);
	     %    nTrials = 1;
	    	% [xPlot yPlot] = getSubplotDimensions(nTrials+1);
	    	% nAlignTypes = length(alignedSignalPerTrial);
	    	% alignStrArray = {'post' 'pre'};
	    	% for alignNo = 1:nAlignTypes
	    	% 	xNo = 1;
	    	% 	yNo = 1;
	    	% 	clf
	    	% 	alignMax = nanmax(alignedSignalPerTrial{alignNo}(:));
	     %    	alignMin = nanmin(alignedSignalPerTrial{alignNo}(:));
		    %     for trialNo = 1:nTrials
		    %     	subplot(xPlot,yPlot,trialNo+1)
		    %     	postIdx = alignedSignalPerTrial{alignNo}(:,trialNo);
		    %     	postIdx(isnan(postIdx)) = alignMin-1;
		    %     	minIdx = abs(min(postIdx)-1);
		    %     	postIdx = postIdx + minIdx;
		    %     	[groupedImagesRates] = groupImagesByColor(IcaFilters,postIdx+0.1);
		    %     	groupedImageCellmapRates = createObjMap(groupedImagesRates);
		    %     	groupedImageCellmapRates = groupedImageCellmapRates - minIdx;
		    %     	groupedImageCellmapRates(1,1) = prepostTime;
		    %     	groupedImageCellmapRates(1,2) = -prepostTime;
		    %     	% groupedImageCellmapRates = groupedImageCellmapRates + abs(alignMin-1);
		    %     	groupedImageCellmapRates(groupedImageCellmapRates==(alignMin-2)) = NaN;
			   %      imagesc(groupedImageCellmapRates);
			   %      % colorbar;
			   %      xDiff = 1/(xPlot);
			   %      xDiff2 = 1/(xPlot+1);
			   %      yDiff = 1/(yPlot);
			   %      % [xDiff*xNo-xDiff 1-yDiff*yNo xDiff-0.01 yDiff-0.01]
			   %      % set(gca,'Position',[xDiff*xNo-xDiff 1-yDiff*yNo xDiff2 yDiff])
			   %      % axis square;
			   %      box off; axis off;
			   %      % colormap(obj.colormap);
		    %     	colormap(customColormap({[1 1 1], [0 0 0], [0 1 0], [0 0 1], [1 0 0]}));
		    %     	set(gca, 'CLim', [-prepostTime-2, prepostTime])
			   %      if trialNo==1
			   %      	subplot(xPlot,yPlot,1)
			   %      	imagesc([alignMin-2:alignMax]); box off; axis off;
			   %      	h = colorbar('location','westoutside');
			   %      	set(h, 'YTick', round(linspace(alignMin-1,alignMax,5)))
			   %      	% ylabel(h, 'frames relative to stimulus','fontsize',20)
			   %      	% cb = colorbar('location','southoutside');
			   %      end
			   %      if xNo==xPlot
			   %      	xNo = 1;
			   %      	yNo = yNo + 1;
			   %      else
			   %      	xNo = xNo + 1;
			   %      end
			   %      drawnow;
		    %     end
		    %     suptitle([subjAssayIDStr ' | ' nameArray{idNum} ' | ' alignStrArray{alignNo} ' | per trial obj map']);
	     %    	obj.modelSaveImgToFile([],'stimTrigAvgObjPerTrial_','current',[obj.fileIDArray{obj.fileNum} '_' obj.stimulusSaveNameArray{idNum} '_' alignStrArray{alignNo}]);
	     %    	% clf
	     %    end
	 end
end