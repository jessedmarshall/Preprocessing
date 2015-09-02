function obj = computeSignalPeaksFxn(obj)
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
	display(repmat('#',1,21))
	display('computing signal peaks...')
	nFiles = length(obj.rawSignals);

	for i=1:nFiles
		obj.fileNum = i;
		if isempty(obj.rawSignals{i})
			display([num2str(i) '/' num2str(nFiles) ' skipping: ' obj.dataPath{i}]);
			continue
		else
			display([num2str(i) '/' num2str(nFiles) ': ' obj.dataPath{i}]);
		end
		[rawSignal rawImages a b] = modelGetSignalsImages(obj);
		[obj.signalPeaks{i}, obj.signalPeaksArray{i}] = computeSignalPeaks(rawSignal, 'makePlots', 0,'makeSummaryPlots',0);
		obj.nSignals{i} = size(rawSignal,1);
		if isempty(obj.rawImages);continue;end;
		[xCoords yCoords] = findCentroid(rawImages);
		obj.objLocations{i} = [xCoords(:) yCoords(:)];
	end