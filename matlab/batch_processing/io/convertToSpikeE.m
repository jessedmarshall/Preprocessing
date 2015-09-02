function [filters, traces] = convertToSpikeE(filterFilePath, tracesFilePath, convertType,varargin)
	% converts between batch (these scripts) format and SpikeE format
	% biafra ahanonu
	% updated: 2013.10.22 [21:21:17]
	% inputs
		% filterFilePath
		% tracesFilePath
		% convertType - 'toSpikeE' or 'fromSpikeE' strong
	% outputs
		%

	% changelog
		% 2014.02.14 [16:37:38] fixed bug in XVector creation, should be a monotonic vector instead of zeros. Updated code to be compatible with current format of batch data.
	% TODO
		%

	%========================
	options.exampleOption = '';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	filesToLoad={filterFilePath,tracesFilePath};
	for i=1:length(filesToLoad)
	    display(['loading: ' filesToLoad{i}]);
	    load(filesToLoad{i})
	end

	[filePath,name,ext] = fileparts(filterFilePath);

	switch convertType
		case 'toSpikeE'
			display('converting to SpikeE format...')
					[filters, traces] = toSpikeE(IcaFilters, IcaTraces, filePath);
		case 'fromSpikeE'
			display('converting from SpikeE format...')
			[filters, traces] = fromSpikeE(SpikeImageData,SpikeTraceData);
		otherwise
			% body
	end

function [SpikeImageData, SpikeTraceData] = toSpikeE(filters, traces, filePath)
	% convert matrix format to spikeE

	nFilters = size(filters,1);
	nTraces = size(traces,1);

	firstFilter = squeeze(filters(1,:,:));
	imageStruct.Path = filePath;
	imageStruct.Filename = '';
	imageStruct.Image = zeros(size(firstFilter,1),size(firstFilter,2));
	imageStruct.DataSize = size(firstFilter);
	imageStruct.Xposition = 1;
	imageStruct.Yposition = 1;
	imageStruct.Zposition = 1;
	imageStruct.Label.CLabel = 'fluorescence (au)';
	imageStruct.Label.XLabel = '\mum';
	imageStruct.Label.YLabel = '\mum';
	imageStruct.Label.ZLabel = '\mum';
	imageStruct.Label.ListText = '';
	imageStruct.ID = [];

	for i=1:nFilters
		SpikeImageData(1,i)=imageStruct;
		SpikeImageData(1,i).Image = thresholdImages(filters(i,:,:));
		SpikeImageData(1,i).Label.ListText = ['IC ' num2str(i) ' max'];
	end

	firstTrace = traces(1,:);
	traceStruct.Path = filePath;
	traceStruct.Filename = '';
	traceStruct.Trace = zeros(size(firstTrace,1),size(firstTrace,2));
	traceStruct.DataSize = size(firstTrace);
	traceStruct.XVector = 1:length(firstTrace);%zeros(size(firstTrace,1),size(firstTrace,2));
	traceStruct.Label.XLabel = 'time (s)';
	traceStruct.Label.YLabel = 'fluorescence (au)';
	traceStruct.Label.ListText = '';
	traceStruct.ID = [];

	for i=1:nTraces
		SpikeTraceData(1,i)=traceStruct;
		SpikeTraceData(1,i).Trace = traces(i,:);
		SpikeTraceData(1,i).Label.ListText = ['IC ' num2str(i)];
	end


function [filters, traces] = fromSpikeE(SpikeImageData,SpikeTraceData)
	% convert spikeE data to normal matrix format

	nTraces = length(SpikeTraceData);
	nTime = length(SpikeTraceData(1,1).Trace);
	traces = zeros(nTraces,nTime);
	for i=1:nTraces
	    traces(i,:) = SpikeTraceData(1,i).Trace;
	end

	nFilters = length(SpikeImageData);
	[x y z] = size(SpikeImageData(1,i).Image);
	filters = zeros([nFilters x y]);
	for i=1:nFilters
	    filters(i,:,:) = SpikeImageData(1,i).Image;
	end

	rmList = sum(~isnan(traces),2)~=0;
	traces = traces(rmList,:);
	filters = filters(rmList,:,:);
	rmList = sum(traces,2)~=0;
	traces = traces(rmList,:);
	filters = filters(rmList,:,:);