function obj = viewObjmapSignificant(obj)
	% displays a cell map for the current
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
		% ============================
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		nIDs = length(obj.stimulusNameArray);
		nSignals = size(IcaTraces,1);
		if isempty(IcaFilters);continue;end;
		%
		nameArray = obj.stimulusNameArray;
		%
		subject = obj.subjectNum{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
		%
		figNoAll = obj.figNoAll;
		figNo = obj.figNo;
		figNames = obj.figNames;
		% ============================
		idNumCounter = 1;
		for idNum = 1:nIDs
			try
				% ============================
				sigModSignals = obj.sigModSignals{obj.fileNum,idNum};
				% ============================
				[groupedImagesMI] = groupImagesByColor(IcaFilters,sigModSignals);
				groupedImagesMI = createObjMap(groupedImagesMI);

				figNames{figNoAll} = 'MIcellmap_';
			 	[figNo{figNoAll}, ~] = openFigure(figNoAll, '');

		        if idNumCounter==1
					suptitle([subjAssayIDStr ' | cell maps of mutually informative cells',10,10])
				end
		        % cell maps of MI scores
				[xPlot yPlot] = getSubplotDimensions(nIDs+1);
		        subplot(xPlot,yPlot,idNum)
		            imagesc(groupedImagesMI);
		            axis square; box off; axis off;
		            colormap(obj.colormap);
		            title([nameArray{idNum}]);
		            drawnow
		        idNumCounter = idNumCounter + 1;
		    catch err
		    	display(repmat('@',1,7))
		    	disp(getReport(err,'extended','hyperlinks','on'));
		    	display(repmat('@',1,7))
		    end
	    end
	    obj.modelSaveImgToFile([],'sigObjmap_','current',[]);
	    % close(figNoAll);

	    % obj.figNoAll = obj.figNoAll + 1;
	    obj.figNo = figNo;
	    obj.figNames = figNames;
	end
end