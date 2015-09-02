function obj = viewSpatioTemporalMetric(obj)
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

	for thisFileNumIdx = 1:nFilesToAnalyze
		thisFileNum = fileIdxArray(thisFileNumIdx);
		obj.fileNum = thisFileNum;
		display(repmat('=',1,21))
		display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
		% =====================
		% for backwards compatibility, will be removed in the future.
		nameArray = obj.stimulusNameArray;
		nIDs = length(obj.stimulusNameArray);
		%
		options.picsSavePath = obj.picsSavePath;
		subject = obj.subjectNum{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		%
		framesPerSecond = obj.FRAMES_PER_SECOND;
		subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
		%
		figNoAll = obj.figNoAll;
		figNo = obj.figNo;
		figNames = obj.figNames;
		% =====================
		idNumCounter = 1;
		for idNum = 1:nIDs
			try
				% ============================
				gfunction = obj.distanceMetric{obj.fileNum,idNum};
				gfunctionShuffledMean = obj.distanceMetricShuffleMean{obj.fileNum,idNum};
				gfunctionShuffledStd = obj.distanceMetricShuffleStd{obj.fileNum,idNum};
				% ============================

				figNames{figNoAll} = 'Gfunction_MI_cellDistances_';
			 	[figNo{figNoAll}, ~] = openFigure(figNoAll, '');
			        if idNumCounter==1
						suptitle([subjAssayIDStr ' | G-function distributions (i.e. spatial clustering)',10,10])
					end
					[xPlot yPlot] = getSubplotDimensions(nIDs+1);
			        subplot(xPlot,yPlot,idNum)
			    		viewLineFilledError(gfunctionShuffledMean,gfunctionShuffledStd);
				    	hold on;
				    	plot(gfunction);box off; xlabel('distance (px)'); ylabel('G(d)');
				    	title(strcat(nameArray{idNum},' '));
				    	if idNumCounter==1
				    		h_legend = legend({'shuffled std','shuffled mean','not significant','significant'},'Location','Best');
				    		set(h_legend,'FontSize',10);
				    	end
				    	hold off;
			    	% pause
			    idNumCounter = idNumCounter + 1;
		    catch err
		    	display(repmat('@',1,7))
		    	disp(getReport(err,'extended','hyperlinks','on'));
		    	display(repmat('@',1,7))
		    end
		end
		obj.modelSaveImgToFile([],'spatioTemporalMetric_','current',[]);
		% close(figNoAll);

		% obj.figNoAll = obj.figNoAll + 1;
		obj.figNo = figNo;
		obj.figNames = figNames;
	end
end