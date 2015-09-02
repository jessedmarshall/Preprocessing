function [filters, traces] = convertToSpikeE(filterFilePath, tracesFilePath, convertType)
	% biafra ahanonu
	% updated: 2013.10.22 [21:21:17]
	% converts between batch format and SpikeE format

	filesToLoad={};
	filesToLoad{1} = filterFilePath;
	filesToLoad{2} = tracesFilePath;
	for i=1:length(filesToLoad)
	    display(['loading: ' filesToLoad{i}]);
	    load(filesToLoad{i})
	end

	[filePath,name,ext] = fileparts(filterFilePath);

	if(convertType=='toSpikeE')
		[filters, traces] = toSpikeE(IcaFilters, IcaTraces, filePath);
	elseif (convertType=='fromSpikeE')
		[filters, traces] = fromSpikeE(SpikeImageData,SpikeTraceData);
	end

function [SpikeImageData, SpikeTraceData] = toSpikeE(filters, traces, filePath)

	nFilters = length(filters{1,1}.Image);
	nTraces = size(traces,1);

	firstFilter = filters{1,1}.Image{1,1};
	imageStruct.Path = filePath;
	imageStruct.Filename = '';
	imageStruct.Image = zeros(size(firstFilter,1),size(firstFilter,2));
	imageStruct.DataSize = size(firstFilter);
	imageStruct.Xposition = 1;
	imageStruct.Yposition = 1;
	imageStruct.Zposition = 1;
	imageStruct.Label.CLabel = 'Fluorescence (au)';
	imageStruct.Label.XLabel = '\mum';
	imageStruct.Label.YLabel = '\mum';
	imageStruct.Label.ZLabel = '\mum';
	imageStruct.Label.ListText = '';
	imageStruct.ID = [];

	for i=1:nFilters
		SpikeImageData(1,i)=imageStruct;
		SpikeImageData(1,i).Image = thresholdICs(filters{1,1}.Image{1,i});
		SpikeImageData(1,i).Label.ListText = ['IC ' num2str(i) ' max'];
	end

	firstTrace = traces(1,:);
	traceStruct.Path = filePath;
	traceStruct.Filename = '';
	traceStruct.Trace = zeros(size(firstTrace,1),size(firstTrace,2));
	traceStruct.DataSize = size(firstTrace);
	traceStruct.XVector = zeros(size(firstTrace,1),size(firstTrace,2));
	traceStruct.Label.XLabel = 'Time (s)';
	traceStruct.Label.YLabel = 'Fluorescence (au)';
	traceStruct.Label.ListText = '';
	traceStruct.ID = [];

	for i=1:nTraces
		SpikeTraceData(1,i)=traceStruct;
		SpikeTraceData(1,i).Trace = traces(i,:);
		SpikeTraceData(1,i).Label.ListText = ['IC ' num2str(i)];
	end


function [filters, traces] = fromSpikeE(SpikeImageData,SpikeTraceData)
	nTraces = length(SpikeTraceData);
	nTime = length(SpikeTraceData(1,1).Trace);
	traces = zeros(nTraces,nTime);
	for i=1:nTraces
	    traces(i,:) = SpikeTraceData(1,i).Trace;
	end

	nFilters = length(SpikeImageData);
	filters = {};
	for i=1:nTraces
	    filters{1,1}.Image{1,i} = SpikeImageData(1,i).Image;
	end