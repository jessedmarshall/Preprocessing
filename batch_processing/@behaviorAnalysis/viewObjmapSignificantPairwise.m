function obj = viewObjmapSignificantPairwise(obj)
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
	for thisFileNumIdx = 1:length(fileIdxArray)
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
			signalPeaksTwo = signalPeaks;
			%
			nameArray = obj.stimulusNameArray;
			saveNameArray = obj.stimulusSaveNameArray;
			idArray = obj.stimulusIdArray;
			nIDs = length(obj.stimulusNameArray);
			%
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
			%
			sigModSignalsAll = obj.sigModSignalsAll{obj.fileNum};
			% stimVectorAll = {obj.stimulusVectorArray{obj.fileNum,:}};
			%
			colorMatrix = obj.colormap;
			% colorMatrix = [1 1 1;hsv(length(idArray))];
			% colorMatrix = [1 1 1;hsv(3)];
			colorMatrix = [1 1 1;1 0 0; 0 0 1;0 0 0];
			colorMatrix = customColormap({[1 1 1],[1 0 0],[0 0 1],[0 0 0]});
			% colorMatrix
			% =====================
			% compare each stimuli to other stimuli MI maps
			figNames{figNoAll} = 'miMap_allPairwise_';
		 	% [figNo{figNoAll}, obj.figNoAll] = openFigure(obj.figNoAll, '');
		 	[figNo{figNoAll}, ~] = openFigure(obj.figNoAll, '');
		 	clf

		 	[p,q] = meshgrid(idNumIdxArray, idNumIdxArray);
		 	idPairs = [p(:) q(:)];
		 	idPairs = unique(sort(idPairs,2),'rows');
		 	idPairs((idPairs(:,1)==idPairs(:,2)),:) = [];
			nIDs = length(idArray);
			% colorArray = hsv(nIDs);
			nPairs = size(idPairs,1);
			% ===
			nColors = size(colorMatrix,1);
			colorIdx1 = round(quantile(1:nColors,0.33));
			colorIdx2 = round(quantile(1:nColors,0.66));
			colorIdx3 = round(quantile(1:nColors,1));
			nameColor3 = ['{\color[rgb]{',num2str(colorMatrix(colorIdx3,:)),'}overlap}'];
			% ===
			ycounter = 1;
			xcounter = 1;
			nPairsTrue = 0;
			for idPairNum = 1:nPairs
				idNum1 = idPairs(idPairNum,1);
				idNum2 = idPairs(idPairNum,2);
				if size(sigModSignalsAll,2)<idNum1|size(sigModSignalsAll,2)<idNum2
					continue;
				end
				nPairsTrue = nPairsTrue + 1;
			end
			[xPlot yPlot] = getSubplotDimensions(nPairsTrue);
			subplotCounter = 1;
			for idPairNum = 1:nPairs
				idNum1 = idPairs(idPairNum,1);
				idNum2 = idPairs(idPairNum,2);
				if size(sigModSignalsAll,2)<idNum1|size(sigModSignalsAll,2)<idNum2
					continue;
				else
					sigModSignalsAllPair = sigModSignalsAll(:,[idNum1 idNum2]);
				end
				% for display purposes, change one so can see the two populations and overlap
				sigModSignalsAllPairMod = [sigModSignalsAllPair(:,1) 2*sigModSignalsAllPair(:,2)];
				sigModSignalsAllPairMod = sum(sigModSignalsAllPairMod,2);
				[groupedImagesSigMod] = groupImagesByColor(IcaFilters,sigModSignalsAllPairMod+0.1);
				groupedImagesSigModMap = createObjMap(groupedImagesSigMod);
				% make sure color scheme stays correct
				% groupedImagesSigModMap(groupedImagesSigModMap==0) = NaN;
				% groupedImagesSigModMap = groupedImagesSigModMap+0.1;
				groupedImagesSigModMap(1,1:4) = 0:3;
				groupedImagesSigModMap(1,1) = 0;
				%
				subplot(xPlot,yPlot,subplotCounter)
					imagesc(groupedImagesSigModMap); axis square;
					% colorbar
					colormap(colorMatrix);
					% color based on which is which
					nameColor1 = ['{\color[rgb]{',num2str(colorMatrix(colorIdx1,:)),'}',strrep(nameArray{idNum1},'__',' '),'}'];
					nameColor2 = ['{\color[rgb]{',num2str(colorMatrix(colorIdx2,:)),'}',strrep(nameArray{idNum2},'__',' '),'}'];
					% title([,'=1',10,nameArray{idNum2},'=2'])
					% title([nameColor1,10,nameColor2]);
					xlabel(nameColor1)
					ylabel(nameColor2)
					% if ycounter==1
					% 	% ylabel('signals')
					% 	ylabel(nameColor1)
					% else
					% 	% y=ylim;
					% 	% ylim([0 y(1)]);
					% end
					% if xcounter==1
					% 	title(nameColor2)
					% end
					box off;
					% axis off;
					set(gca,'visible','off');
					set(findall(gca, 'type', 'text'), 'visible', 'on');
					axis('tight')
					drawnow;
				if ycounter==nIDs
					ycounter = 1;
					xcounter = xcounter + 1;
				else
					ycounter = ycounter+1;
				end
				subplotCounter = subplotCounter + 1;
		    end
			% subplot(xPlot,yPlot,nPairs)
			% 	imagesc([0:3]);
			% 	cb = colorbar('location','southoutside');
			% xlabel(cb, 'MI stimuli number');
			suptitle([subjAssayIDStr ' | stimulus modulated cells, ' nameColor3])

			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 length(idNumIdxArray)*5 length(idNumIdxArray)*5])
			obj.modelSaveImgToFile([],'sigObjmapAllStimPairwise_','current',[]);
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
end