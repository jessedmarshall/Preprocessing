function obj = viewContinuousSignalVideo(obj)
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

		% compareTrackingToMovie = 0;
		% if compareTrackingToMovie==1
		nameArray = obj.continuousStimulusNameArray;
		saveNameArray = obj.continuousStimulusSaveNameArray;
		idArray = obj.continuousStimulusIdArray;
		% obtain stimulus information
		class(idArray(find(ismember(nameArray,options.var1))))
		iioptions.array = 'continuousStimulusArray';
		iioptions.nameArray = 'continuousStimulusNameArray';
		iioptions.idArray = 'continuousStimulusIdArray';
		iioptions.stimFramesOnly = 1;
		XM = obj.modelGetStim(idArray(find(ismember(nameArray,'XM'))),'options',iioptions);
		YM = obj.modelGetStim(idArray(find(ismember(nameArray,'YM'))),'options',iioptions);
		if isempty(YM); continue; end;
		% movement.Angle = obj.modelGetStim(idArray(find(ismember(nameArray,options.var3))),'options',iioptions);
		xdiff = [0; diff(XM)];
		ydiff = [0; diff(YM)];
		thisVel = sqrt(xdiff.^2 + ydiff.^2);
		% [IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		% if isempty(IcaTraces); continue; end;
		% outputData = compareSignalToMovement(IcaTraces,movement,'makePlots',0);
		% thisVel = outputData.downsampledVelocity*obj.FRAMES_PER_SECOND;
		thisVel = thisVel*obj.FRAMES_PER_SECOND;
		thisVel = interp1(1:length(thisVel),thisVel,linspace(1,length(thisVel),length(thisVel)*4));
		velocity = (thisVel'>options.STIM_CUTOFF);

		options.videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
		vidList = getFileList(obj.videoDir,options.videoTrialRegExp);

		% plot
		if ~isempty(idNumIdxArray)
			[xPlot yPlot] = getSubplotDimensions(length(idNumIdxArray)+1);
			behaviorMovie = loadMovieList(vidList,'convertToDouble',0,'frameList',50:51,'treatMoviesAsContinuous',1);
			figure(thisFileNumIdx)
			subplot(xPlot,yPlot,1)
			imagesc(squeeze(behaviorMovie(:,:,1)))
			title('whole trial')
			colormap gray
			hold on;
			viewColorLinePlot(XM,YM);
			downsampleFactor = 4;
			for idNumIdx = 1:length(idNumIdxArray)
				subplot(xPlot,yPlot,1+idNumIdx)
				imagesc(squeeze(behaviorMovie(:,:,1)))
				hold on;
				idNum = idNumIdxArray(idNumIdx);
				obj.stimNum = idNum;
				title(obj.stimulusNameArray{obj.stimNum})
				stimVector = obj.modelGetStim(obj.stimulusIdArray(idNum),'stimFramesOnly',1);
				if isempty(stimVector); continue; end;
				% stimVectorIdx = find(stimVector);
				stimVectorIdx = stimVector;
				behaviorMovie2 = loadMovieList(vidList,'convertToDouble',0,'frameList',bsxfun(@plus,stimVectorIdx(1),0:2)*downsampleFactor,'treatMoviesAsContinuous',1);
				imagesc(squeeze(behaviorMovie2(:,:,1)));
				% stimVectorSpread = spreadSignal(stimVector,'timeSeq',[-10:10]);
				for stimIdx = 1:length(stimVectorIdx)
					try
						plot(XM(stimVectorIdx(stimIdx)*downsampleFactor),YM(stimVectorIdx(stimIdx)*downsampleFactor),'.g','markersize', 15)
						hold on
						stimIdxSpread = bsxfun(@plus,stimVectorIdx(stimIdx),-10:10);
						viewColorLinePlot(XM(stimIdxSpread*downsampleFactor),YM(stimIdxSpread*downsampleFactor),'nPoints',20,'colors',customColormap({[1 1 1],[1 1 1],[1 0 0],[1 1 1],[1 1 1]},'nPoints',20));
					catch

					end
				end
			end
			suptitle(strrep(obj.folderBaseSaveStr{obj.fileNum},'_','|'))
			obj.modelSaveImgToFile([],'trackingVideoOverlay_','current',[]);
			% continue;
		end

		%
		% vidList(:)
		adjIdx = 14000;
		downsampleFactor = 4;
		frameListIdx = (1+adjIdx):(adjIdx+obj.nFrames{fileNum});
		frameListIdx = 14000:obj.nFrames{fileNum};
		frameListIdx2 = 14000*downsampleFactor:obj.nFrames{fileNum}*downsampleFactor;
		% frameListIdx = (1+adjIdx):(adjIdx+500);
		behaviorMovie = loadMovieList(vidList,'convertToDouble',0,'frameList',frameListIdx*downsampleFactor,'treatMoviesAsContinuous',1);
		% [behaviorMovie] = createTrackingOverlayVideo(behaviorMovie,XM,YM,'downsampleFactor',4);
		[behaviorMovie] = createTrackingOverlayVideo(behaviorMovie,XM(frameListIdx2),YM(frameListIdx2),'downsampleFactor',4);

		% behaviorMovie = downsampleMovie(behaviorMovie,'downsampleFactor',downsampleFactor,'downsampleDimension','time');
		movieList = getFileList(obj.inputFolders{obj.fileNum}, obj.fileFilterRegexp);
		% size(unique(ceil(frameListIdx/4)))
		size(behaviorMovie)
		[inputMovie] = loadMovieList(movieList{1},'convertToDouble',0,'frameList',frameListIdx);
		[behaviorMovie] = createSideBySide(behaviorMovie,inputMovie,'pxToCrop',[]);

		% signalBasedSuffix = 'openfield_tracking_lzw.tif';
		% savePathName = [obj.videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} '_' signalBasedSuffix]
		% saveastiff(behaviorMovie, savePathName, options);
		savePathName = [obj.videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} '_openfield_track.h5'];
		[output] = writeHDF5Data(behaviorMovie,savePathName);
		% playMovie(behaviorMovie);

		% playMovie(behaviorMovie,'primaryTrackingPoint',[XM(frameListIdx) YM(frameListIdx) velocity(frameListIdx)*-90 10*thisVel(frameListIdx)'],'primaryTrackingPointColor','k','recordMovie',savePathName);
		% continue

	end
end
function [downsampledVector1] = downsampleVector(vector1,vector2)
	% dowmsamples vector1 to have the same length as vector 2
	nPtsVector2 = length(vector2);
	downsampledVector1 = interp1(1:length(vector1),vector1,linspace(1,length(vector1),nPtsVector2));
end