function obj = modelModifyRegionAnalysis(obj)
% remove PCAs in a particular region or exclude from preprocessing, etc.

	if obj.guiEnabled==1
		scnsize = get(0,'ScreenSize');
		[fileIdxArray, ok] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
	else
		if isempty(obj.foldersToAnalyze)
			fileIdxArray = 1:length(obj.fileIDNameArray);
		else
			fileIdxArray = obj.foldersToAnalyze;
		end
	end
	nFolders = length(fileIdxArray);

	framesPerSecond = obj.FRAMES_PER_SECOND;
	for thisFileNumIdx = 1:length(fileIdxArray)
		try
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			display(repmat('=',1,21))
			display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.fileIDNameArray{obj.fileNum}]);

			[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
			% IcaFilters = thresholdImages(IcaFilters,'binary',0)/3;
			% [IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);

			% display cellmap and ask user to select a region
			[~, ~] = openFigure(obj.figNoAll, '');
				clf
				colormap gray
				subX = 2; subY = 2;
				subplot(subX,subY,2);
					numPeakEvents = sum(signalPeaks,2);
					numPeakEvents = numPeakEvents/size(signalPeaks,2)*framesPerSecond;
					[groupedImagesRates] = groupImagesByColor(IcaFilters,numPeakEvents);
					thisCellmap = createObjMap(groupedImagesRates);
					imagesc(thisCellmap);
					title('firing rate cell map')
					% colormap(obj.colormap);
				subplot(subX,subY,3);
					movieList = getFileList(obj.inputFolders{obj.fileNum}, 'concat');
					if ~isempty(movieList)
						movieFrame = loadMovieList(movieList{1},'convertToDouble',0,'frameList',1:2);
						movieFrame = squeeze(movieFrame(:,:,1));
						% movieFrameMean = mean(movieFrame(:));
						% imagesc(imadjust(movieFrame+cast(thisCellmap*10000,class(movieFrame))));
						E = normalizeVector(double(movieFrame),'normRange','zeroToOne')/2;
						% Comb = E;
						I = cast(normalizeVector(thisCellmap,'normRange','zeroToOne')*mean(movieFrame(:)),class(movieFrame));
						I = normalizeVector(double(I),'normRange','zeroToOne')/3;
						Comb(:,:,1) = E; % red
						Comb(:,:,2) = E+I; % green
						Comb(:,:,3) = E; % blue
						imagesc(Comb)
						% IcaFiltersThresholded = thresholdImages(IcaFilters,'binary',0)/3;
						% zeroMap = zeros(size(movieFrame));
						% oneMap = ones(size(movieFrame));
						% warning off
						% colorOverlay = imshow(cat(3, zeroMap, oneMap, zeroMap));
						% warning on
						% thisCellmap = createObjMap(IcaFiltersThresholded);
						% set(colorOverlay, 'AlphaData', thisCellmap);
					end
					title('movie frame + cell map')
				subplot(subX,subY,1);
					% if isempty(obj.validManual{obj.fileNum})
					% 	[groupedImagesRates] = groupImagesByColor(IcaFilters,obj.validAuto{obj.fileNum});
					% else
					% 	[groupedImagesRates] = groupImagesByColor(IcaFilters,obj.validManual{obj.fileNum});
					% end
					% thisCellmap = createObjMap(groupedImagesRates);
					% imagesc(thisCellmap+0.5);
					imagesc(obj.rawImagesFiltered{obj.fileNum}+0.1);
					title('draw selection on this image')
					% colormap(obj.colormap)
					suptitle(strrep(obj.folderBaseSaveStr{obj.fileNum},'_',' | '))
					[obj.analysisROIArray{obj.fileNum} xpoly ypoly] = roipoly;
					obj.validRegionModPoly{obj.fileNum} = [xpoly ypoly];
					imagesc(obj.rawImagesFiltered{obj.fileNum}.*obj.analysisROIArray{obj.fileNum})

			inputImages = obj.analysisROIArray{obj.fileNum};
			IcaFilters = thresholdImages(IcaFilters,'waitbarOn',1,'binary',1);
			signalInROI = squeeze(nansum(nansum(bsxfun(@times,inputImages,permute(IcaFilters,[2 3 1])),1),2));

			% signalInROI = applyImagesToMovie(inputImages,permute(IcaFilters,[2 3 1]), 'alreadyThreshold',1);
			signalsToKeep = signalInROI~=0;

			if isempty(obj.validManual{obj.fileNum})
				obj.validRegionMod{obj.fileNum} = obj.validAuto{obj.fileNum}(:)&signalsToKeep(:);
			else
				obj.validRegionMod{obj.fileNum} = obj.validManual{obj.fileNum}(:)&signalsToKeep(:);
				% if ~isempty(obj.validManual{obj.fileNum})
				% 	obj.validRegionMod{obj.fileNum} = obj.validAuto{obj.fileNum}(:)&signalsToKeep(:);
				% end
			end

			[~, ~] = openFigure(obj.figNoAll, '');
				subplot(subX,subY,4);
				[filterImageGroups] = createObjMap(groupImagesByColor(IcaFilters,obj.validRegionMod{obj.fileNum}+1));
				% size(filterImageGroups)
				imagesc(filterImageGroups)
				title('new cell map')
				% colormap(obj.colormap)

			uiwait(msgbox('press OK to move onto next folder','Success','modal'));

		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
end