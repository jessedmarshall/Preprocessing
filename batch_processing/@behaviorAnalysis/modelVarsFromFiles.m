function obj = modelVarsFromFiles(obj)
	% get signals and images from input folders
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		% ADD SUPPORT FOR EM ANALYSIS

	display(repmat('#',1,21))
	display('loading files...')

	signalExtractionMethod = obj.signalExtractionMethod;
	usrIdxChoiceStr = {'PCAICA','EM'};
	[sel, ok] = listdlg('ListString',usrIdxChoiceStr);
	usrIdxChoiceList = {2,1};
	signalExtractionMethod = usrIdxChoiceStr{sel};

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:nFilesToAnalyze
		try
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			display(repmat('=',1,21))
			% display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
	% nFolders = length(obj.dataPath);
	% for fileNum = 1:nFolders
	% 	display(repmat('-',1,7))
	% 	try
			obj.rawSignals{fileNum} = [];
			obj.rawImages{fileNum} = [];
			obj.signalPeaks{fileNum} = [];
			obj.signalPeaksArray{fileNum} = [];
			obj.nSignals{fileNum} = [];
			obj.nFrames{fileNum} = [];
			obj.objLocations{fileNum} = [];
			obj.validManual{fileNum} = [];
			obj.validAuto{fileNum} = [];
			if strmatch('#',obj.dataPath{fileNum})
				% display([num2str(fileNum) '/' num2str(nFolders) ' | skipping: ' obj.dataPath{fileNum}]);
				display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) ') | skipping: ' obj.fileIDNameArray{obj.fileNum}]);
				obj.rawSignals{fileNum} = [];
				obj.rawImages{fileNum} = [];
				continue;
			else
				% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.dataPath{fileNum}]);
				display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(fileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);
			end

			switch signalExtractionMethod
				case 'PCAICA'
					regexPairs = {...
						% {'_ICfilters_sorted.mat','_ICtraces_sorted.mat'},...
						{'holding.mat','holding.mat'},...
						{obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr},...
						{obj.rawEMStructSaveStr},...
					};
					% get list of files to load
					filesToLoad = getFileList(obj.dataPath{fileNum},regexPairs{1});
					rawFiles = 0;
					% get secondary list of files to load
					if isempty(filesToLoad)
					    filesToLoad = getFileList(obj.dataPath{fileNum},regexPairs{2});
					    rawFiles = 1;
					    if isempty(filesToLoad)
					    % if(~exist(filesToLoad{1}, 'file'))
					    	display('no files!');
					        continue
					    end
					end
					% load files in order
					for i=1:length(filesToLoad)
					    display(['loading: ' filesToLoad{i}]);
					    load(filesToLoad{i});
					end
					signalImages = IcaFilters;
					signalTraces = IcaTraces;
				case 'EM'
					regexPairs = {...
						{obj.rawEMStructSaveStr}...
					};
					% get list of files to load
					filesToLoad = getFileList(obj.dataPath{fileNum},regexPairs{1});
					if isempty(filesToLoad)
				    	display('no files!');
				        continue
					end
					% load files in order
					for i=1:length(filesToLoad)
					    display(['loading: ' filesToLoad{i}]);
					    load(filesToLoad{i});
					end
					signalImages = permute(emAnalysisOutput.cellImages,[3 1 2]);
					signalTraces = emAnalysisOutput.dsCellTraces;
					rawFiles = 1;
				otherwise
					% body
			end
			% if manually sorted signals, add
			if exist('valid','var')
				obj.validManual{fileNum} = valid;
			end

			% rawFiles
			if rawFiles==1
				if ~exist('signalTraces','var')
					[~, ~, validAuto, imageSizes] = filterImages(signalImages, []);
				else
					[~, ~, validAuto, imageSizes] = filterImages(signalImages, signalTraces);
				end
				% [filterImageGroups] = groupImagesByColor(signalImages,validAuto+1);
				% obj.rawImagesFiltered{fileNum} = createObjMap(filterImageGroups);
				size(validAuto)
				% validAuto
				obj.validAuto{fileNum} = validAuto;
				clear validAuto
				% [figHandle figNo] = openFigure(2014+round(rand(1)*100), '');
				%     imagesc(filterImageGroups);
				%     colormap(customColormap([]));
				%     box off; axis off;
				%     % colorbar
			end

			% compute peaks
			if exist('signalTraces','var')
				[obj.signalPeaks{fileNum}, obj.signalPeaksArray{fileNum}] = computeSignalPeaks(signalTraces, 'makePlots', 0,'makeSummaryPlots',0);
				obj.nSignals{fileNum} = size(signalTraces,1);
				obj.nFrames{fileNum} = size(signalTraces,2);
			end
			% get the x/y coordinates
			if isempty(signalImages);continue;end;
			[xCoords yCoords] = findCentroid(signalImages);
			obj.objLocations{fileNum} = [xCoords(:) yCoords(:)];

			% add files
			if obj.loadVarsToRam == 1
			    if exist('signalTraces','var')
			    	obj.rawSignals{fileNum} = signalTraces;
			    end
			    if exist('signalImages','var')
			    	obj.rawImages{fileNum} = signalImages;
		    	end
		    end
		    clear signalTraces signalImages
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end