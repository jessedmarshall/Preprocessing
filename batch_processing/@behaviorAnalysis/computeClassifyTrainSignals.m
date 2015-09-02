function obj = computeClassifyTrainSignals(obj)
	% compute peaks for all signals if not already input
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

	% display('NOT FULLY CONVERTED TO CLASS METHOD YET...')
	% return

	scnsize = get(0,'ScreenSize');
	classifyOrTrain = {'training','classify','classify to valid'};
	[fileIdxArray, ok] = listdlg('ListString',classifyOrTrain,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','train or classify?');
	classifyOrTrain = classifyOrTrain{fileIdxArray}

	display(repmat('#',1,21))
	display('computing signal peaks...')
	nFiles = length(obj.rawSignals);
	subjectList = unique(obj.subjectStr);
	for thisSubjectStr=subjectList
		display(repmat('=',1,21))
		thisSubjectStr = thisSubjectStr{1}
		switch classifyOrTrain
			case 'training'
				% get folders with correct subject and that have already been manually classified
				validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
				validManualIdx = find(arrayfun(@(x) ~isempty(x{1}),obj.validManual));
				trainingFoldersIdx = intersect(validFoldersIdx,validManualIdx);

				%
				ioption.classifierType = 'all';
				ioption.trainingOrClassify = 'training';
				ioption.inputTargets = {obj.validManual{trainingFoldersIdx}};
				trainingRawImages = {};
				trainingRawSignals = {};
				obj.folderBaseSaveStr{trainingFoldersIdx}
				for idx = 1:length(trainingFoldersIdx)
					obj.fileNum = trainingFoldersIdx(idx);
					[rawSignals rawImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
					trainingRawImages{idx} = rawImages;
					trainingRawSignals{idx} = rawSignals;
				end
				% classify signals
				[outputStruct] = classifySignals(trainingRawImages,trainingRawSignals,'options',ioption);
				obj.classifierStructs.(thisSubjectStr) = outputStruct;
			case 'classify'
				validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
				for idx = 1:length(validFoldersIdx)
					try
						obj.fileNum = validFoldersIdx(idx);
						display(repmat('*',1,7))
						obj.folderBaseSaveStr{obj.fileNum}
						[rawSignals rawImages signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','raw');
						if isempty(rawSignals)
							continue
						end
						% get subject classifier structure
						classifierStruct = obj.classifierStructs.(thisSubjectStr);
						%
						ioption.classifierType = 'all';
						ioption.trainingOrClassify = 'classify';
						% ioption.inputTargets = {ostruct.validArray{ostruct.counter}};
						ioption.inputStruct = classifierStruct;
						[obj.classifierFolderStructs{obj.fileNum}] = classifySignals({rawImages},{rawSignals},'options',ioption);

						plotValid()
					catch err
						display(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						display(repmat('@',1,7))
					end
				end
			case 'classify to valid'
				validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
				for idx = 1:length(validFoldersIdx)
					obj.fileNum = validFoldersIdx(idx);
					display(repmat('*',1,7))
					obj.folderBaseSaveStr{obj.fileNum}
					thisStruct = obj.classifierFolderStructs{obj.fileNum};
					obj.validAuto{obj.fileNum} = thisStruct.classifications>0.5;
				end
			otherwise
				% body
		end
	end
	function plotValid()
		valid = obj.classifierFolderStructs{obj.fileNum}.classifications;
		% originalValid = valid;
		validNorm = normalizeVector(valid,'normRange','oneToOne');
		validDiff = [0 diff(valid')];
		%
		[figHandle figNo] = openFigure(10000, '');
		clf
		plot(valid);hold on;
		plot(validDiff,'g');
		%
		% validQuantiles = quantile(valid,[0.4 0.3]);
		% validHigh = validQuantiles(1);
		% validLow = validQuantiles(2);
		validHigh = 0.7;
		validLow = 0.5;
		%
		valid(valid>=validHigh) = 1;
		valid(valid<=validLow) = 0;
		valid(isnan(valid)) = 0;
		% questionable classification
		valid(validDiff<-0.3) = 2;
		valid(valid<validHigh&valid>validLow) = 2;
		%
		plot(valid,'r');
		plot(validNorm,'k');box off;
		legend({'scores','diff(scores)','classification','normalized scores'})
	end
end
	% if strcmp('classify',options.trainingOrClassify)
	% 	ioption.classifierType = options.classifierType;
	% 	ioption.trainingOrClassify = options.trainingOrClassify;
	% 	ioption.inputTargets = {ostruct.validArray{ostruct.counter}};
	% 	ioption.inputStruct = classifierStruct
	% 	[ostruct.classifier] = classifySignals({ostruct.inputImages{ostruct.counter}},{ostruct.inputSignals{ostruct.counter}},'options',ioption);
	% 	% ostruct.data.confusionPct
	% 	% ostruct.classifier.confusionPct
	% 	if ~any(strcmp('summaryStats',fieldnames(ostruct)))
	% 		ostruct.summaryStats.subject{1,1} = nan;
	% 		ostruct.summaryStats.assay{1,1} = nan;
	% 		ostruct.summaryStats.assayType{1,1} = nan;
	% 		ostruct.summaryStats.assayNum{1,1} = nan;
	% 		ostruct.summaryStats.confusionPctFN{1,1} = nan;
	% 		ostruct.summaryStats.confusionPctFP{1,1} = nan;
	% 		ostruct.summaryStats.confusionPctTP{1,1} = nan;
	% 		ostruct.summaryStats.confusionPctTN{1,1} = nan;
	% 	end
	% 	ostruct.summaryStats.subject{end+1,1} = ostruct.subject{fileNum};
	% 	ostruct.summaryStats.assay{end+1,1} = ostruct.assay{fileNum};
	% 	ostruct.summaryStats.assayType{end+1,1} = ostruct.info.assayType{fileNum};
	% 	ostruct.summaryStats.assayNum{end+1,1} = ostruct.info.assayNum{fileNum};
	% 	ostruct.summaryStats.confusionPctFN{end+1,1} = ostruct.classifier.confusionPct(1);
	% 	ostruct.summaryStats.confusionPctFP{end+1,1} = ostruct.classifier.confusionPct(2);
	% 	ostruct.summaryStats.confusionPctTP{end+1,1} = ostruct.classifier.confusionPct(3);
	% 	ostruct.summaryStats.confusionPctTN{end+1,1} = ostruct.classifier.confusionPct(4);
	% end