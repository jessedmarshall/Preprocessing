function [inputTrackingVideo] = createTrackingOverlayVideo(inputTrackingVideo,inputX,inputY,varargin)
	% example function with outline for necessary components
	% biafra ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	options.extraVideo = '';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		nameArray = obj.continuousStimulusNameArray;
		saveNameArray = obj.continuousStimulusSaveNameArray;
		idArray = obj.continuousStimulusIdArray;
		% obtain stimulus information
		class(idArray(find(ismember(nameArray,options.var1))))
		iioptions.array = 'continuousStimulusArray';
		iioptions.nameArray = 'continuousStimulusNameArray';
		iioptions.idArray = 'continuousStimulusIdArray';
		iioptions.stimFramesOnly = 1;
		movement.XM = obj.modelGetStim(idArray(find(ismember(nameArray,'XM_cm'))),'options',iioptions);
		movement.YM = obj.modelGetStim(idArray(find(ismember(nameArray,'YM_cm'))),'options',iioptions);
		movement.Angle = obj.modelGetStim(idArray(find(ismember(nameArray,options.var3))),'options',iioptions);
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		if isempty(IcaTraces); continue; end;
		outputData = compareSignalToMovement(IcaTraces,movement,'makePlots',0);
		thisVel = outputData.downsampledVelocity*obj.FRAMES_PER_SECOND;
		thisVel = interp1(1:length(thisVel),thisVel,linspace(1,length(thisVel),length(thisVel)*4));
		velocity = (thisVel'>options.STIM_CUTOFF);

		XM = obj.modelGetStim(idArray(find(ismember(nameArray,'XM'))),'options',iioptions);
		YM = obj.modelGetStim(idArray(find(ismember(nameArray,'YM'))),'options',iioptions);
		% xdiff = [0; diff(XM_cm)];
		% ydiff = [0; diff(YM_cm)];
		% velocity = sqrt(xdiff.^2 + ydiff.^2);
		% velocity = smooth(velocity,20,'moving');
		% % 20*velocity(1:500)'
		% velocity = (velocity*20>5)*-90;
		% velocity(1:500)'

		adjIdx = 50;
		downsampleFactor = 4;
		frameListIdx = (1+adjIdx):(adjIdx+1500);
		options.videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
		vidList = getFileList(obj.videoDir,options.videoTrialRegExp);
		% vidList(:)
		behaviorMovie = loadMovieList(vidList,'convertToDouble',0,'frameList',frameListIdx*downsampleFactor,'treatMoviesAsContinuous',1);
		% obj.videoDir
		% signalBasedSuffix = 'openfield_tracking.avi';
		% savePathName = [obj.videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} signalBasedSuffix]

		nframes = size(behaviorMovie,3)
		magnitudeVector = round(thisVel*10);
		midCutoff = 10*1;
		highCutoff = 20*1;
		reverseStr = '';
		behaviorMovieX = size(behaviorMovie,1);
		behaviorMovieY = size(behaviorMovie,2);
		for frameNoIdx=1:nframes
			% frameNo = frameListIdx(frameNoIdx);
			frameNo = frameNoIdx;
			frameNoTrue = downsampleFactor*frameListIdx(frameNoIdx);
			try
				if isnan(XM(frameNoTrue))|isnan(YM(frameNoTrue))
					continue
				end
				thisXM = ceil(XM(frameNoTrue));
				thisYM = ceil(YM(frameNoTrue));
				thisMagnitudeVector = magnitudeVector(frameNoTrue);
				% [thisXM thisYM thisMagnitudeVector]
				subValue = Inf;
				behaviorMovie(thisYM,thisXM,frameNo) = subValue;
				% add cross-hairs
				behaviorMovie(thisYM-3,(thisXM-2:thisXM+2),frameNo) = subValue;
				behaviorMovie(thisYM+3,(thisXM-2:thisXM+2),frameNo) = subValue;
				behaviorMovie((thisYM-2:thisYM+2),thisXM-3,frameNo) = subValue;
				behaviorMovie((thisYM-2:thisYM+2),thisXM+3,frameNo) = subValue;
				% add cutoff values
				widthLines = 3;
				behaviorMovie(thisYM-midCutoff,(thisXM-widthLines:thisXM+widthLines),frameNo) = subValue;
				behaviorMovie(thisYM-highCutoff,(thisXM-widthLines:thisXM+widthLines),frameNo) = subValue;
				behaviorMovie((thisYM-widthLines:thisYM+widthLines),thisXM-midCutoff,frameNo) = subValue;
				behaviorMovie((thisYM-widthLines:thisYM+widthLines),thisXM-highCutoff,frameNo) = subValue;
				% add vector for moving/nonmoving and velocity
				if velocity(frameNoTrue)==1
					if (thisYM-thisMagnitudeVector)<1
						thisYM = 1:thisYM;
					else
						thisYM = (thisYM-thisMagnitudeVector):thisYM;
					end
					behaviorMovie(thisYM,(thisXM-1:thisXM+1),frameNo) = subValue;
				else
					if (thisXM-thisMagnitudeVector)<1
						thisXM = 1:thisXM;
					else
						thisXM = (thisXM-thisMagnitudeVector):thisXM;
					end
					behaviorMovie((thisYM-1:thisYM+1),thisXM,frameNo) = subValue;
				end
				reverseStr = cmdWaitbar(frameNoIdx,nframes,reverseStr,'inputStr','adding tracking to behavior video','waitbarOn',1,'displayEvery',5);
			catch
				[thisXM thisYM thisMagnitudeVector]
			end
		end
		signalBasedSuffix = 'openfield_tracking_lzw.tif';
		savePathName = [obj.videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} '_' signalBasedSuffix]

		% behaviorMovie = downsampleMovie(behaviorMovie,'downsampleFactor',downsampleFactor,'downsampleDimension','time');

		movieList = getFileList(obj.inputFolders{obj.fileNum}, obj.fileFilterRegexp);
		% size(unique(ceil(frameListIdx/4)))
		size(behaviorMovie)
		[inputMovie] = loadMovieList(movieList{1},'convertToDouble',0,'frameList',frameListIdx);

		[behaviorMovie] = createSideBySide(behaviorMovie,inputMovie,'pxToCrop',[]);

		saveastiff(behaviorMovie, savePathName, options);
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end
function [downsampledVector1] = downsampleVector(vector1,vector2)
	% dowmsamples vector1 to have the same length as vector 2
	nPtsVector2 = length(vector2);
	downsampledVector1 = interp1(1:length(vector1),vector1,linspace(1,length(vector1),nPtsVector2));
end