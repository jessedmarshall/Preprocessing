function obj = viewObjmapSignificantAllStims(obj)
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
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			%
			[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
			nIDs = length(obj.stimulusNameArray);
			nSignals = size(IcaTraces,1);
			if isempty(IcaFilters);continue;end;
			%
			idArray = obj.stimulusIdArray;
			%
			subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
			%
			figNoAll = obj.figNoAll;
			figNo = obj.figNo;
			figNames = obj.figNames;
			%
			sigModSignalsAll = obj.sigModSignalsAll{obj.fileNum};
			% =====================

			% =====================
			% look to see which cells are responsive to multiple stimuli
			figNames{figNoAll} = 'miMap_all_';
		 	[figNo{figNoAll}, obj.figNoAll] = openFigure(obj.figNoAll, '');
				sigModSignalsAllSum = sum(sigModSignalsAll,2);
				[groupedImagesSigMod] = groupImagesByColor(IcaFilters,sigModSignalsAllSum);
				groupedImagesSigModMap = createObjMap(groupedImagesSigMod);
				groupedImagesSigModMap(1,1) = length(obj.stimulusIdArray);
				imagesc(groupedImagesSigModMap); axis square;
				% colormap(ostruct.colormap);
				colorMatrix = [1 1 1;hsv(length(idArray))];
				colormap(colorMatrix);
				% cb = colorbar('location','southoutside');
				cb = colorbar;
				ylabel(cb, '# MI stimuli');
				title([subjAssayIDStr ' | overlap of mutually informative cells, all stimuli'])


			obj.modelSaveImgToFile([],'sigObjmapStimPairwise_','current',[]);
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
end