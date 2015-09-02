function obj = viewCreateObjmaps(obj)
	% creates obj maps and plots of high-SNR example signals
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

	movieSettings = inputdlg({...
			'directory to save pictures: '
		},...
		'view movie settings',1,...
		{...
			obj.picsSavePath
		}...
	);
	obj.picsSavePath = movieSettings{1};

	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
			% =====================
			% for backwards compatibility, will be removed in the future.
			nIDs = length(obj.stimulusNameArray);
			%
			nameArray = obj.stimulusNameArray;
			idArray = obj.stimulusIdArray;
			%
			% [inputSignals inputImages signalPeaks signalPeakIdx] = modelGetSignalsImages(obj,'returnType','raw');
			[inputSignals inputImages signalPeaks signalPeakIdx] = modelGetSignalsImages(obj);
			nIDs = length(obj.stimulusNameArray);
			nSignals = size(inputSignals,1);
			nFrames = size(inputSignals,2);
			%
			options.dfofAnalysis = obj.dfofAnalysis;
			timeSeq = obj.timeSequence;
			% subject = obj.subjectNum{obj.fileNum};
			subject = obj.subjectStr{obj.fileNum};
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
			prepostTime = 20;
			%
			picsSavePath = [obj.picsSavePath filesep 'cellmaps' filesep];
			fileFilterRegexp = obj.fileFilterRegexp;
			% =====================


	    	% thisFileID = obj.fileIDNameArray{obj.fileNum};
	    	thisFileID = obj.fileIDArray{obj.fileNum};

	    	normalFigs = 1;
	    	if normalFigs==1
			    [figHandle figNo] = openFigure(969, '');
				    s1 = subplot(1,2,1);
					    % coloredObjs = groupImagesByColor(thresholdImages(inputImages),[]);
					    % thisCellmap = createObjMap(coloredObjs);
					    % firing rate grouped images
					    numPeakEvents = sum(signalPeaks,2);
					    numPeakEvents = numPeakEvents/size(signalPeaks,2)*framesPerSecond;
					    size(inputImages)
					    size(numPeakEvents)
					    [groupedImagesRates] = groupImagesByColor(inputImages,numPeakEvents);
					    thisCellmap = createObjMap(groupedImagesRates);

					    % if fileNum==1
					    %     fig1 = figure(32);
					    %     % colormap gray;
					    % end
						% thisCellmap = createObjMap([thisDirSaveStr options.rawICfiltersSaveStr]);
						% subplot(round(nFiles/4),4,fileNum);
						plotBinaryCellMapFigure();
						title([subject ' | ' assay ' | firing rate map | ' num2str(size(signalPeaks,1)) ' cells'],'fontsize',20)

					[signalSnr a] = computeSignalSnr(inputSignals,'testpeaks',signalPeaks,'testpeaksArray',signalPeakIdx);
				[figHandle figNo] = openFigure(972, '');
					subplot(2,2,1);
						plotBinaryCellMapFigure();
				[figHandle figNo] = openFigure(969, '');
					s2 = subplot(1,2,2);
						[signalSnr sortedIdx] = sort(signalSnr,'descend');
						sortedinputSignals = inputSignals(sortedIdx,:);
						signalPeakIdx = {signalPeakIdx{sortedIdx}};
						cutLength = 600;
						if cutLength*2>size(inputSignals,2);cutLength=floor(size(inputSignals,2)/2.2);end
						cutLength
						nSignalsShow = 20;
						if nSignalsShow>length(signalPeakIdx);nSignalsShow=length(signalPeakIdx);end
						sortedinputSignalsCut = zeros([nSignalsShow cutLength*2+1]);
						shiftVector = round(linspace(round(cutLength/10),round(cutLength*0.9),nSignalsShow));
						shiftVector = shiftVector(randperm(length(shiftVector)));
						for i=1:nSignalsShow
							spikeIdx = signalPeakIdx{i};
							spikeIdxValues = sortedinputSignals(i,spikeIdx);
							[k tmpIdx] = max(spikeIdxValues);
							spikeIdx = spikeIdx(tmpIdx);
							spikeIdx = spikeIdx-(round(cutLength/2)-shiftVector(i));
							% spikeIdx
							% cutLength
							nPoints = size(inputSignals,2);
							if (spikeIdx-cutLength)<0
								beginDiff = abs(spikeIdx-cutLength);
								cutIdx = bsxfun(@plus,spikeIdx,-(cutLength-beginDiff-1):(cutLength+beginDiff+1));
								cutIdx = 1:(cutLength*2+1);
							elseif (spikeIdx+cutLength)>nPoints
								endDiff = abs(-spikeIdx);
								cutIdx = bsxfun(@plus,spikeIdx,-(cutLength+endDiff+1):(cutLength-endDiff-1));
								cutIdx = (nPoints-(cutLength*2)):nPoints;
							else
								cutIdx = bsxfun(@plus,spikeIdx,-cutLength:cutLength);
							end
							if ~isempty(cutIdx)
								sortedinputSignalsCut(i,:) = sortedinputSignals(i,cutIdx(:)');
							end
						end
						sortedinputSignalsCut = flip(sortedinputSignalsCut,1);
						size(sortedinputSignalsCut)
						plotTracesFigure();

					d=0.02; %distance between images
					set(s1,'position',[d 0.1 0.5-2*d 0.8])
			     	set(s2,'position',[0.5+d 0.1 0.5-2*d 0.8])
				    saveFile = char(strrep(strcat(picsSavePath,'cellmap_',thisFileID,''),'/',''));
				    set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
				    % figure(figHandle)
				    obj.modelSaveImgToFile([],'cellmapObj_','current',[]);
				    % print('-dpng','-r200',saveFile)
				    % print('-dmeta','-r200',saveFile)
				    % saveas(gcf,saveFile);
					drawnow;

					[figHandle figNo] = openFigure(972, '');
						subplot(2,2,2);
							plotTracesFigure();

				[figHandle figNo] = openFigure(970, '');
					% timeVector = (1:size(sortedinputSignalsCut,2))/framesPerSecond;
					plotSignalsGraph(sortedinputSignalsCut,'LineWidth',2.5);
					nTicks = 10;
					set(gca,'XTick',round(linspace(1,size(sortedinputSignalsCut,2),nTicks)))
					labelVector = round(linspace(1,size(sortedinputSignalsCut,2)/framesPerSecond,nTicks));
					set(gca,'XTickLabel',labelVector);
					xlabel('seconds','fontsize',20);ylabel('\Delta F/F','fontsize',20);
					box off;
					% axis off;
					% title('example traces');
					title([subject ' | ' assay ' | example traces'],'fontsize',20)
				    saveFile = char(strrep(strcat(picsSavePath,'traces_',thisFileID,''),'/',''));
				    saveFile
				    set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
				    % figure(figHandle)
				    obj.modelSaveImgToFile([],'cellmapTraces_','current',[]);
				    % print('-dpng','-r200',saveFile)
				    % print('-dmeta','-r200',saveFile)
				    % saveas(gcf,saveFile);
					drawnow;
			end
			% movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
			movieList = getFileList(obj.inputFolders{obj.fileNum}, 'concat');
			if ~isempty(movieList)
				[figHandle figNo] = openFigure(971, '');
					movieFrame = loadMovieList(movieList{1},'convertToDouble',0,'frameList',1:2);
					movieFrame = squeeze(movieFrame(:,:,1));
					% imagesc(imadjust(movieFrame));
					% imagesc(movieFrame);
					% imshow(movieFrame);
					% axis off; colormap gray;
					% title([subject ' | ' assay ' | blue>green>red percentile rank']);
					% hold on;
					% imcontrast
					% continue
					% inputImagesThresholded = thresholdImages(inputImages,'binary',0)/3;
					% inputImagesThresholded = inputImages;
					% icaQ = quantile(numPeakEvents,[0.3 0.6]);
					% colorObjMaps{1} = createObjMap(inputImagesThresholded(numPeakEvents<icaQ(1),:,:));
					% colorObjMaps{2} = createObjMap(inputImagesThresholded(numPeakEvents>icaQ(1)&numPeakEvents<icaQ(2),:,:));
					% colorObjMaps{3} = createObjMap(inputImagesThresholded(numPeakEvents>icaQ(2),:,:));

					[inputSignals inputImages signalPeaks signalPeakIdx] = modelGetSignalsImages(obj,'returnType','raw');

					validAuto = obj.validAuto{obj.fileNum};
					display('==============')
					if isempty(obj.validRegionMod)
						validRegionMod = ones(size(validAuto));
					else
						validRegionMod = obj.validRegionMod{obj.fileNum};
					end
					validRegionMod = validRegionMod(logical(validAuto));
					inputImagesThresholded = thresholdImages(inputImages(validAuto,:,:),'binary',0)/3;
					% inputImagesThresholded = inputImagesThresholded(validAuto);
					size(inputImagesThresholded)
					colorObjMaps{1} = createObjMap(inputImagesThresholded(validRegionMod==0,:,:));
					colorObjMaps{2} = createObjMap(inputImagesThresholded(validRegionMod==1,:,:));
					size(colorObjMaps{1})
					E = normalizeVector(double(movieFrame),'normRange','zeroToOne')/2;
					if isempty(colorObjMaps{1})
						Comb(:,:,1) = E;
					else
						Comb(:,:,1) = E+normalizeVector(double(colorObjMaps{1}),'normRange','zeroToOne')/4; % red
					end
					Comb(:,:,2) = E+normalizeVector(double(colorObjMaps{2}),'normRange','zeroToOne')/4; % green
					Comb(:,:,3) = E; % blue
					% Comb(:,:,3) = E+normalizeVector(double(colorObjMaps{1}),'normRange','zeroToOne')/4; % blue
					imagesc(Comb)
					% clear Comb
					axis off; colormap gray;
					title([subject ' | ' assay ' | blue-green-red percentile rank | cells=' num2str(nSignals)]);

					[nanmax(movieFrame(:)) nanmin(movieFrame(:))]
					[nanmax(colorObjMaps{1}(:)) nanmin(colorObjMaps{1}(:))]

					% zeroMap = zeros(size(movieFrame));
					% oneMap = ones(size(movieFrame));
					% green = cat(3, zeroMap, oneMap, zeroMap);
					% blue = cat(3, zeroMap, zeroMap, oneMap);
					% red = cat(3, oneMap, zeroMap, zeroMap);
					% warning off
					% blueOverlay = imshow(blue);
					% greenOverlay = imshow(green);
					% redOverlay = imshow(red);
					% warning on
					% set(redOverlay, 'AlphaData', colorObjMaps{1});
					% set(greenOverlay, 'AlphaData', colorObjMaps{2});
					% set(blueOverlay, 'AlphaData', colorObjMaps{3});
					set(gca, 'LooseInset', get(gca,'TightInset'))
					hold off;
					saveFile = char(strrep(strcat(picsSavePath,'cellmap_overlay_',thisFileID,''),'/',''));
					saveFile
					set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
					% figure(figHandle)
					obj.modelSaveImgToFile([],'cellmapObjOverlay_','current',[]);
					% print('-dpng','-r200',saveFile)
					% print('-dmeta','-r200',saveFile)
					% saveas(gcf,saveFile);
					% pause

				[figHandle figNo] = openFigure(972, '');
					subplot(2,2,3);
						imagesc(movieFrame)
						title('raw movie')

				[figHandle figNo] = openFigure(972, '');
					subplot(2,2,4);
						imagesc(Comb)
						clear Comb
						axis off; colormap gray;
						title('detected cells in green')
						% title([subject ' | ' assay ' | blue-green-red percentile rank | cells=' num2str(nSignals)]);
						% num2str(size(signalPeaks,1))
				suptitle([subject ' | ' assay ' | firing rate map | ' num2str(sum(validAuto)) ' cells'])
				set(figHandle,'PaperUnits','inches','PaperPosition',[0 0 16 9])
				obj.modelSaveImgToFile([],'objMapAll_','current',[]);

				% inputImagesThresholded = thresholdImages(inputImages,'binary',0);
				% saveFile = char(strcat(thisDirSaveStr,'cellmap_thresholded.h5'));
				% thisObjMap = createObjMap(inputImagesThresholded);
				% movieSaved = writeHDF5Data(thisObjMap,saveFile)
				% inputImagesThresholded = thresholdImages(inputImages,'binary',1);
				% saveFile = char(strcat(thisDirSaveStr,'cellmap_thresholded_binary.h5'));
				% thisObjMap = createObjMap(inputImagesThresholded);
				% movieSaved = writeHDF5Data(thisObjMap,saveFile)
			end
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	function plotBinaryCellMapFigure()
		imagesc(thisCellmap);
		colormap(obj.colormap);
		s2Pos = get(gca,'position');
		cb = colorbar('location','southoutside'); ylabel(cb, 'Hz');
		set(gca,'position',s2Pos);
	    % colormap hot; colorbar;
		% title(regexp(thisDir,'m\d+', 'match'));
		box off; axis tight; axis off;
		set(gca, 'LooseInset', get(gca,'TightInset'))

	end
	function plotTracesFigure()
		plotSignalsGraph(sortedinputSignalsCut,'LineWidth',2.5);
		nTicks = 10;
		set(gca,'XTick',round(linspace(1,size(sortedinputSignalsCut,2),nTicks)))
		labelVector = round(linspace(1,size(sortedinputSignalsCut,2),nTicks)/framesPerSecond);
		set(gca,'XTickLabel',labelVector);
		xlabel('seconds','fontsize',20);ylabel('\Delta F/F','fontsize',20);
		box off;
		title('example traces','fontsize',20);
	end
end