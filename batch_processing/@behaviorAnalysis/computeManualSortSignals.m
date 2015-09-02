function obj = computeManualSortSignals(obj)
	% compute peaks for all signals if not already input
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2014.10.09 - finished re-implementing for behaviorAnalysis class
	% TODO
		% ADD PERSONS NAME TO THE FILE

	% =======
	options.emSaveRaw = '_emAnalysis.mat';
	options.emSaveSorted = '_emAnalysisSorted.mat';
	options.cleanedICfiltersSaveStr = '_ICfilters_sorted.mat';
	options.cleanedICtracesSaveStr = '_ICtraces_sorted.mat';
	options.cleanedICdecisionsSaveStr = '_ICdecisions.mat';
	% =======

	display(repmat('#',1,21))
	display('computing signal peaks...')
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			% fileNum = obj.fileNum;
			display(repmat('#',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
			% =======
			% path to current folder
			currentFolderPath = obj.inputFolders{obj.fileNum};
			% process movie regular expression
			fileFilterRegexp = obj.fileFilterRegexp;
			% get list of movies
			movieList = getFileList(currentFolderPath, fileFilterRegexp);
			% subject information
			subject = obj.subjectNum{obj.fileNum};
			assay = obj.assay{obj.fileNum};
			subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
			folderBaseSaveStr = obj.folderBaseSaveStr{obj.fileNum};
			%
			currentFolderSaveStr = [currentFolderPath filesep obj.folderBaseSaveStr{obj.fileNum}];
			% =======

			if ~exist('usrIdxChoiceSettings','var')|strcmp(usrIdxChoiceSettings,'per folder settings')
				usrIdxChoiceStr = {'viewing','sorting'};
				[sel, ok] = listdlg('ListString',usrIdxChoiceStr);
				usrIdxChoiceSortType = usrIdxChoiceStr{sel};

				usrIdxChoiceStr = {'PCA/ICA','EM'};
				[sel, ok] = listdlg('ListString',usrIdxChoiceStr);
				usrIdxChoiceList = {2,1};
				usrIdxChoiceSignalType = usrIdxChoiceStr{sel};

			    usrIdxChoiceStr = {'load movie','do not load movie'};
			    [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
			    usrIdxChoiceMovie = usrIdxChoiceStr{sel};

			    usrIdxChoiceStr = {'do not classify','classify'};
			    [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
			    usrIdxChoiceClassification = usrIdxChoiceStr{sel};
			end

			if ~exist('usrIdxChoiceSettings','var')
				usrIdxChoiceStr = {'settings across all folders','per folder settings'};
				[sel, ok] = listdlg('ListString',usrIdxChoiceStr);
				usrIdxChoiceSettings = usrIdxChoiceStr{sel};
			end
		    % =======
			switch usrIdxChoiceSignalType
				case 'PCA/ICA'
					[rawSignals rawImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
				case 'EM'
					[rawSignals, rawImages, ~, ~] = modelGetSignalsImages(obj,'returnType','raw_CellMax');
				otherwise
					% body
			end
			% =======
		    % load movie?
		    if strcmp(usrIdxChoiceMovie,'load movie')
		        % load movies
		        [ioptions.inputMovie o m n] = loadMovieList(movieList);
		    else

		    end

			% check if the folder has temporary decisions to load (e.g. if a crash occured)
			tmpDecisionList = getFileList(currentFolderPath, 'tmpDecision');
			previousDecisionList = getFileList(currentFolderPath, options.cleanedICdecisionsSaveStr);
			if ~isempty(tmpDecisionList)&isempty(previousDecisionList)
				display(['loading temp decisions: ' tmpDecisionList{1}])
				load(tmpDecisionList{1});
			elseif ~isempty(previousDecisionList)
				display(['loading previous decisions: ' previousDecisionList{1}])
				load(previousDecisionList{1});
			else
				% valid = [];
				display('starting with automatically sorted...')
				valid = obj.validAuto{obj.fileNum};
			end

		    ioptions.inputStr = subjAssayIDStr;
		    ioptions.valid = valid;
		    ioptions.sessionID = [folderBaseSaveStr '_' num2str(java.lang.System.currentTimeMillis)];
		    % ioptions.classifierFilepath = options.classifierFilepath;
		    % ioptions.classifierType = options.classifierType;
			[rawImages rawSignals valid] = signalSorter(rawImages, rawSignals, '', [],'options',ioptions);
			% rawImages = rawImages(valid,:,:);
			% rawSignals = rawSignals(valid,:);

			% add manual sorting to object
			obj.validManual{obj.fileNum} = valid;
			% commandwindow;

			% save sorted ICs
			if strcmp(usrIdxChoiceSortType,'sorting')
				switch usrIdxChoiceSignalType
					case 'PCA/ICA'
						IcaFilters = rawImages;
						IcaTraces = rawSignals;
						saveID = {options.cleanedICfiltersSaveStr,options.cleanedICtracesSaveStr,options.cleanedICdecisionsSaveStr}
						saveVariable = {'IcaFilters','IcaTraces','valid'}
						for i=1:length(saveID)
							savestring = [currentFolderSaveStr saveID{i}];
							display(['saving: ' savestring])
							save(savestring,saveVariable{i});
						end
					case 'EM'
						validCellMax = valid;
						saveID = {options.emSaveSorted}
						saveVariable = {'validCellMax'}
						for i=1:length(saveID)
							savestring = [currentFolderSaveStr saveID{i}];
							display(['saving: ' savestring])
							save(savestring,saveVariable{i});
						end
					otherwise
						% body
				end
			end

			clear rawImages rawSignals valid
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
end
    % ostruct.inputImages{ostruct.counter} = IcaFilters;
    % ostruct.inputSignals{ostruct.counter} = IcaTraces;
    % ostruct.validArray{ostruct.counter} = valid;

    % if exist(options.classifierFilepath, 'file')&strcmp(usrIdxChoiceClassification,'classify')&0
    %     display(['loading: ' options.classifierFilepath]);
    %     load(options.classifierFilepath)
    %     options.trainingOrClassify = 'classify';
    %     ioption.classifierType = options.classifierType;
    %     ioption.trainingOrClassify = options.trainingOrClassify;
    %     ioption.inputTargets = {ostruct.validArray{ostruct.counter}};
    %     ioption.inputStruct = classifierStruct;
    %     [ostruct.classifier] = classifySignals({ostruct.inputImages{ostruct.counter}},{ostruct.inputSignals{ostruct.counter}},'options',ioption);
    %     valid = ostruct.classifier.classifications;
    %     % originalValid = valid;
    %     validNorm = normalizeVector(valid,'normRange','oneToOne');
    %     validDiff = [0 diff(valid')];
    %     %
    %     figure(100020);close(100020);figure(100020);
    %     plot(valid);hold on;
    %     plot(validDiff,'g');
    %     %
    %     % validQuantiles = quantile(valid,[0.4 0.3]);
    %     % validHigh = validQuantiles(1);
    %     % validLow = validQuantiles(2);
    %     validHigh = 0.7;
    %     validLow = 0.5;
    %     %
    %     valid(valid>=validHigh) = 1;
    %     valid(valid<=validLow) = 0;
    %     valid(isnan(valid)) = 0;
    %     % questionable classification
    %     valid(validDiff<-0.3) = 2;
    %     valid(valid<validHigh&valid>validLow) = 2;
    %     %
    %     plot(valid,'r');
    %     plot(validNorm,'k');box off;
    %     legend({'scores','diff(scores)','classification','normalized scores'})
    %     % valid
    % else
    %     display(['no classifier at: ' options.classifierFilepath])
    % end

