function [inputSignals inputImages signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj,varargin)
	% grabs input signals and images from current folder
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		% obj.fileNum - this should be set to the folder
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% which table to read in
	options.returnType = 'filtered';
	options.emSaveSorted = '_emAnalysisSorted.mat';
	% SignalsImages, Images, Signals
	% options.getSpecificData = 'SignalsImages';
	%
	options.regexPairs = {...
		% {'_ICfilters_sorted.mat','_ICtraces_sorted.mat'},...
		% {'holding.mat','holding.mat'},...
		{obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr},...
		{obj.rawEMStructSaveStr},...
	};
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	pause(0.001)

	switch options.returnType
		case 'filtered_traces'
			options.regexPairs = {{obj.rawICtracesSaveStr}};
			options.returnType = 'filtered';
		case 'filtered_images'
			options.regexPairs = {{obj.rawICfiltersSaveStr}};
			options.returnType = 'filtered';
		case 'raw_traces'
			options.regexPairs = {{obj.rawICtracesSaveStr}};
			options.returnType = 'raw';
		case 'raw_images'
			options.regexPairs = {{obj.rawICfiltersSaveStr}};
			options.returnType = 'raw';
		case 'raw_CellMax'
			options.regexPairs = {{obj.rawEMStructSaveStr}};
			options.returnType = 'raw';
		otherwise
			switch obj.signalExtractionMethod
				case 'PCAICA'
					options.regexPairs = {{obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr}};
				case 'EM'
					options.regexPairs = {{obj.rawEMStructSaveStr}};
				otherwise
						% body
			end
	end

	regexPairs = options.regexPairs;

	% get valid signals, priority is region excluded, manual sorting, automatic sorting, and all valid otherwise.
	if ~isempty(obj.validRegionMod)&length(obj.validRegionMod)>=obj.fileNum&~isempty(obj.validRegionMod{obj.fileNum})
		valid = obj.validRegionMod{obj.fileNum};
	elseif ~isempty(obj.validManual)&length(obj.validManual)>=obj.fileNum&~isempty(obj.validManual{obj.fileNum})
		valid = obj.validManual{obj.fileNum};
	elseif ~isempty(obj.validAuto)&length(obj.validAuto)>=obj.fileNum&~isempty(obj.validAuto{obj.fileNum})
		valid = obj.validAuto{obj.fileNum};
	else
		valid = ones([1 size(obj.rawSignals{obj.fileNum},1)]);
	end
	if sum(valid)==0
		valid(1:end) = 1;
	end
	if isempty(obj.rawSignals{obj.fileNum})
		inputSignals = [];
		inputImages = [];
		signalPeaks = [];
		signalPeaksArray = [];
		if strmatch('#',obj.dataPath{obj.fileNum})
			return;
		else
			% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.dataPath{fileNum}]);
		end

		% get list of files to load
		filesToLoad = [];
		fileToLoadNo = 1;
		nRegExps = length(regexPairs);
		while isempty(filesToLoad)
			filesToLoad = getFileList(obj.dataPath{obj.fileNum},regexPairs{fileToLoadNo});
			fileToLoadNo = fileToLoadNo+1;
			if fileToLoadNo>nRegExps
				break;
			end
		end
	    if isempty(filesToLoad)
	    % if(~exist(filesToLoad{1}, 'file'))
	    	display('no files');
	    	inputSignals = [];
	    	inputImages = [];
	    	signalPeaks = [];
	    	signalPeaksArray = [];
	        return;
	    end
		% rawFiles = 0;
		% % get secondary list of files to load
		% % |strcmp(options.returnType,'raw')
		% if isempty(filesToLoad)
		%     filesToLoad = getFileList(obj.dataPath{obj.fileNum},regexPairs{2});
		%     rawFiles = 1;
		% end
		% load files in order
		for i=1:length(filesToLoad)
		    display(['loading: ' filesToLoad{i}]);
		    try
		    	load(filesToLoad{i});
		    catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
		    	pause(3)
		    	display(['trying, loading again: ' filesToLoad{i}]);
		    	load(filesToLoad{i});
			end

		end
		if exist('emAnalysisOutput','var')
			inputSignals = emAnalysisOutput.dsCellTraces;
			inputImages = permute(emAnalysisOutput.cellImages,[3 1 2]);
			% if isempty(obj.signalPeaks{obj.fileNum})
			% 	signalPeaks = [];
			% 	signalPeaksArray = [];
			% else
			% 	signalPeaks = obj.signalPeaks{obj.fileNum};
			% 	signalPeaksArray = {obj.signalPeaksArray{obj.fileNum}};
			% end
		end
		if exist('IcaTraces','var')
			inputSignals = IcaTraces;
		end
		if exist('ROItraces','var')
			inputSignals = ROItraces;
		end
		if exist('IcaFilters','var')
			inputImages = IcaFilters;
		end
		if exist('inputSignals','var')
			if isempty(obj.signalPeaks{obj.fileNum})
				signalPeaks = [];
				signalPeaksArray = [];
			else
				signalPeaks = obj.signalPeaks{obj.fileNum};
				signalPeaksArray = {obj.signalPeaksArray{obj.fileNum}};
			end
			switch options.returnType
				case 'raw'

				case 'filtered'
					inputSignals = inputSignals(valid,:);
					signalPeaks = obj.signalPeaks{obj.fileNum}(valid,:);
					signalPeaksArray = {obj.signalPeaksArray{obj.fileNum}{valid}};
				case 'filteredAndRegistered'
					inputSignals = inputSignals(valid,:);
					% inputImages = IcaFilters(valid,:,:);
					signalPeaks = obj.signalPeaks{obj.fileNum}(valid,:);
					signalPeaksArray = {obj.signalPeaksArray{obj.fileNum}{valid}};
				otherwise
					% body
			end
			obj.nFrames{obj.fileNum} = size(inputSignals,2);
			obj.nSignals{obj.fileNum} = size(inputSignals,1);
		end

		if exist('inputImages','var')
			switch options.returnType
				case 'raw'

				case 'filtered'
					inputImages = inputImages(valid,:,:);
				case 'filteredAndRegistered'
					inputImages = inputImages(valid,:,:);
					% register images based on cross session alignment
					globalRegCoords = obj.globalRegistrationCoords.(obj.subjectStr{obj.fileNum});
					if ~isempty(globalRegCoords)
						display('registering images')
						% get the global coordinate number based
						globalRegCoords = globalRegCoords{strcmp(obj.assay{obj.fileNum},obj.globalIDFolders.(obj.subjectStr{obj.fileNum}))};
						if ~isempty(globalRegCoords)
							inputImages = permute(inputImages,[2 3 1]);
							for iterationNo = 1:length(globalRegCoords)
								fn=fieldnames(globalRegCoords{iterationNo});
								for i=1:length(fn)
									localCoords = globalRegCoords{iterationNo}.(fn{i});
									[inputImages localCoords] = turboregMovie(inputImages,'precomputedRegistrationCooords',localCoords);
								end
							end
							inputImages = permute(inputImages,[3 1 2]);
						end
					end
				otherwise
					% body
			end
		end
	else
		inputSignals = obj.rawSignals{obj.fileNum}(valid,:);
		inputImages = obj.rawImages{obj.fileNum}(valid,:,:);
		signalPeaks = obj.signalPeaks{obj.fileNum}(valid,:);
		signalPeaksArray = {obj.signalPeaksArray{obj.fileNum}{valid}};

		obj.nFrames{obj.fileNum} = size(inputSignals,2);
		obj.nSignals{obj.fileNum} = size(inputSignals,1);
	end