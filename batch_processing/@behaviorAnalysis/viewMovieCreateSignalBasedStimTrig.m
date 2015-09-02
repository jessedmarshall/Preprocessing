function obj = viewMovieCreateSignalBasedStimTrig(obj)
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

	options.preOffset = 10;
	options.postOffset = 10;
	options.montageSuffix = '_montage.h5';
	options.signalBasedSuffix = '_signalBased.h5';
	options.movieMontage = 0;
	% is the secondary video at a higher framerate?
	options.downsampleFactor = 4;
	%
	options.convertToDouble = 0;

	%
	fileFilterRegexp = obj.fileFilterRegexp;
	scnsize = get(0,'ScreenSize');
	% select format of video files
	videoTrialRegExpList = {'yyyy_mm_dd_pNNN_mNNN_assayNN','yymmdd-mNNN-assayNN','subject_assay'};
	[videoTrialRegExpIdx, ok] = listdlg('ListString',videoTrialRegExpList,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','video string type (N = number)');
	%
	additionalOptionsArray = {'signal-based movie','signal-based movie type ("peak" or "raw")','montage','object cut movie','number of stimuli to use (blank=All)','frames pre stimulus','frames post stimulus'};
	% [additionapOptionsIdx, ok] = listdlg('ListString',additionalOptionsArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
	userDefaults = {'1','peak','0','0','','10','10'};
	additionapOptionsIdx = inputdlg(additionalOptionsArray,'1=yes, 0=no',1,userDefaults,'on');
	additionapOptionsIdx
	additionapOptionsVars = {'','','createObjCutMovie','objCutMovieType'}
	createSignalBasedMovieOption = str2num(additionapOptionsIdx{1});
	signalBasedSignalType = additionapOptionsIdx{2};
	options.movieMontage = str2num(additionapOptionsIdx{3});
	createObjCutMovie = str2num(additionapOptionsIdx{4});
	numStimuliToUse = str2num(additionapOptionsIdx{5});
	options.preOffset = str2num(additionapOptionsIdx{6});
	options.postOffset = str2num(additionapOptionsIdx{7});

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
		thisFileNum = fileIdxArray(thisFileNumIdx);
		obj.fileNum = thisFileNum;
		display(repmat('=',1,21))
		% display([num2str(thisFileNum) '/' num2str(length(fileIdxArray)) ': ' obj.fileIDNameArray{obj.fileNum}]);
		display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
		% =====================
		% for backwards compatibility, will be removed in the future.
		nameArray = obj.stimulusNameArray;
		saveNameArray = obj.stimulusSaveNameArray;
		idArray = obj.stimulusIdArray;
		% assayTable = obj.discreteStimulusTable;
		%
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		nIDs = length(obj.stimulusNameArray);
		nSignals = size(IcaTraces,1);
		if isempty(IcaFilters)&(createSignalBasedMovieOption==1|createObjCutMovie==1)
			display('no images!');
			continue;
		end;
		%
		usTimeAfterCS = 10;
		options.dfofAnalysis = obj.dfofAnalysis;
		options.stimTriggerOnset = obj.stimTriggerOnset;
		options.picsSavePath = obj.picsSavePath;
		thisFileID = obj.fileIDArray{obj.fileNum};
		timeSeq = obj.timeSequence;
		subject = obj.subjectNum{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		framesPerSecond = obj.FRAMES_PER_SECOND;
		% =====================
		nIDs = length(obj.stimulusNameArray);
		colorArray = hsv(nIDs);
		idNumCounter = 1;
		% =====================
		for idNumIdx = 1:length(idNumIdxArray)
			idNum = idNumIdxArray(idNumIdx);
			obj.stimNum = idNum;
			try
				% =====================
				display(repmat('=',1,7))
				display([num2str(idNum) '/' num2str(nIDs) ': analyzing ' nameArray{idNum}])
				% ===============================================================
				if options.dfofAnalysis==1
					signalPeaksTwo = IcaTraces;
				else
					signalPeaksTwo = signalPeaks;
				end
				% ===============================================================
				% obtain stimulus information
				stimVector = obj.modelGetStim(idArray(idNum));
				if isempty(stimVector); display('no stimuli!');continue; end;
				% ===============================================================
				% how much to offset the movie from the stimuli
				if createSignalBasedMovieOption==1|createObjCutMovie==1
					nPoints = size(IcaTraces,2);
				else
					movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
					movieDims = loadMovieList(movieList,'convertToDouble',0,'frameList',[],'inputDatasetName',obj.inputDatasetName,'treatMoviesAsContinuous',1,'getMovieDims',1);
					nPoints = sum(movieDims.z);
					% thisFrameList = 1:sum(movieDims.z);
				end

				preOffset = options.preOffset;
				postOffset = options.postOffset;
				framesToAlign = find(stimVector);
				if ~isempty(numStimuliToUse)&length(framesToAlign)>numStimuliToUse
					framesToAlign = framesToAlign(1:numStimuliToUse);
				end
				nAlignPts = length(framesToAlign);
				timeVector = [-preOffset:postOffset]';
				framesToAlign = unique(framesToAlign);
				if isempty(framesToAlign)
					display(repmat('@',1,7))
					display(['no stimuli'])
					display(repmat('@',1,7))
					continue;
				end
				framesToAlign(find((framesToAlign<preOffset))) = [];
				framesToAlign(find((framesToAlign>(nPoints-postOffset)))) = [];
				peakIdxs = bsxfun(@plus,timeVector,framesToAlign(:)');
				peakIdxs(find((peakIdxs<1))) = [];
				peakIdxs(find((peakIdxs>nPoints))) = [];
				if ~isempty(peakIdxs(:))

					movieList = getFileList(obj.inputFolders{obj.fileNum}, fileFilterRegexp);
					[inputMovie] = loadMovieList(movieList{1},'convertToDouble',options.convertToDouble,'frameList',peakIdxs(:));
					timeVectorFake = zeros(size(timeVector));
					timeVectorFake(round(end/2)-2:round(end/2)+2) = 1;
					peakIdxsFake = bsxfun(@times,timeVectorFake,framesToAlign(:)');
					% peakIdxsFake(peakIdxsFake==0) = [];
					% find(peakIdxsFake)
					% frameAddImage = peakIdxs(:).*peakIdxsFake(:)
					% inputMovie(1:25,1:25,find(peakIdxsFake)) = 1;

					% create signal based movie or object cut movie
					if createSignalBasedMovieOption==1
						[signalMovie{idNumIdx}] = createSignalBasedMovie(IcaTraces(:,peakIdxs),IcaFilters,'signalType',signalBasedSignalType);
						[signalMovie{idNumIdx}] = createSideBySide(signalMovie{idNumIdx},inputMovie,'pxToCrop',[]);
					else
						signalMovie{idNumIdx} = inputMovie;
					end
					if createObjCutMovie==1
						if ~isempty(obj.sigModSignals)&~isempty(obj.sigModSignals{obj.fileNum,idNum})
							sigModSignals = obj.sigModSignals{obj.fileNum,idNum};
							IcaFiltersTmp = IcaFilters(sigModSignals,:,:);
							if size(IcaFiltersTmp,1)>25
								IcaFiltersTmp = IcaFiltersTmp(1:25,:,:);
							end
						else
							[signalSnr a] = computeSignalSnr(IcaTraces);
							[signalSnr sortedIdx] = sort(signalSnr,'descend');
							IcaFiltersTmp = IcaFilters(sortedIdx(1:25),:,:);
						end
						[signalMovie{idNumIdx}] = getObjCutMovie(inputMovie,IcaFiltersTmp);
						% make object cut traces to other stimuli responsive cells

						% clear inputMovie;
					end

					if ~isempty(obj.videoDir)
						% videoTrialRegExp = options.videoTrialRegExp;
						local_getVideoRegexp()
						options.videoTrialRegExp = videoTrialRegExp;
						vidList = getFileList(obj.videoDir,options.videoTrialRegExp);
						if ~isempty(vidList)
							% get the movie
							behaviorMovie = loadMovieList(vidList,'convertToDouble',options.convertToDouble,'frameList',peakIdxs(:)*options.downsampleFactor,'treatMoviesAsContinuous',1);
							% behaviorMovie = createMovieMontage(behaviorMovie,nAlignPts,timeVector,postOffset,preOffset,options.montageSuffix,savePathName,0);
							behaviorMovie = behaviorMovie+0.25;
							[signalMovie{idNumIdx}] = createSideBySide(behaviorMovie,signalMovie{idNumIdx},'pxToCrop',[]);
							signalMovie{idNumIdx}((end-20):end,(end-20):end,find(peakIdxsFake)) = 1;

							if options.movieMontage==1
								savePathName = [obj.videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} '_' obj.stimulusSaveNameArray{idNum}]
								createMovieMontage(signalMovie{idNumIdx},nAlignPts,timeVector,postOffset,preOffset,options.montageSuffix,savePathName,1);
							end
						else
							display(['no vid file: ' obj.videoDir ' | ' options.videoTrialRegExp])
						end
					else
						display('no video directory...')
					end
					if ~isempty(obj.videoSaveDir)
						savePathName = [obj.videoSaveDir filesep obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum}  '_' obj.fileIDArray{obj.fileNum} '_' obj.stimulusSaveNameArray{idNum} options.signalBasedSuffix]
						options.comp = 'no';
						[savePathName '.tif']
						% signalMovie{idNumIdx} = permute(signalMovie{idNumIdx},[2 1 3]);
						saveastiff(signalMovie{idNumIdx}, [savePathName '.tif'], options);
						% [output] = writeHDF5Data(signalMovie{idNumIdx},savePathName);
						signalMovie{idNumIdx} = [];
					end

					clear inputMovie;
				end
				% ===============================================================
				idNumCounter = idNumCounter+1;
			catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
			end
		end
	end
	function local_getVideoRegexp()
		switch videoTrialRegExpIdx
			case 1
				videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
			case 2
				% videoTrialRegExp = [obj.date{obj.fileNum} '_' obj.protocol{obj.fileNum} '_' obj.fileIDArray{obj.fileNum}];
				dateTmp = strsplit(obj.date{obj.fileNum},'_');
				videoTrialRegExp = strcat(dateTmp{1}(end-1:end),dateTmp{2},dateTmp{3},'-',obj.subjectStr{obj.fileNum},'-',obj.assay{obj.fileNum});
			case 3
				videoTrialRegExp = [obj.subjectStr{obj.fileNum} '_' obj.assay{obj.fileNum}]
			otherwise
				videoTrialRegExp = fileFilterRegexp
		end
	end
end
function [k] = createMovieMontage(inputMovie,nAlignPts,timeVector,postOffset,preOffset,montageSuffix,savePathName,saveFile)
	% example function with outline for necessary components
	% biafra ahanonu
	% fxn started: 2014.08.13 - broke off from controllerAnalysis script from ~2014.03
	% inputs
		% inputMovie - path to movie file, in cell array, e.g. {'path.h5'}
		% inputAlignPts - vector containing the frames to align to
		% savePathName - path to save output movie, exclude the extension.
	% outputs
		%

	display('creating montage...');
	% =======================
	% SAVE AN ARRAY of the movie cut to the alignment pt
	% this is super hacky at the moment, but it WORKs, so don't whine. Basically trying to make a square matrix of the primary movie cut to the stimulus. Convert to cell array, add a fake movie that blips at stimulus, line up all movies horizontally then cut into rows determined by the number of stimuli...
	[m n t] = size(inputMovie);
	nStims = nAlignPts;
	stimLength = length(timeVector(:));
	k = mat2cell(inputMovie,m,n,stimLength*ones([1 nStims]));
	tmpMovie = NaN([m n stimLength]);
	tmpMovie(:,:,preOffset+1) = 1e5;
	% tmpMovie(:,:,ceil(stimLength/2)) = 1;
	k{end+1} = tmpMovie;
	%playMovie([k{:}])
	[xPlot yPlot] = getSubplotDimensions(nStims+1)
	squareNeed = xPlot*yPlot;
	length(k);
	dimDiff = squareNeed-length(k);
	for ii=1:dimDiff
		k{end+1} = NaN([m n stimLength]);
	end
	size(k);
	k = [k{:}];
	[m2 n2 t2] = size(k);
	nRows = yPlot+1;
	splitIdx = diff(ceil(linspace(1,n2,nRows)));
	splitIdx(end) = splitIdx(end)+1;
	k = mat2cell(k,m2,splitIdx,t2);
	k = vertcat(k{:});
	if saveFile==1
		saveDir = [savePathName montageSuffix];
		[pathstr,name,ext] = fileparts(saveDir);
		saveDir = [pathstr filesep 'montage' filesep name ext];
		writeHDF5Data(k,saveDir);
	end
	% clear k;
	% ======================
end