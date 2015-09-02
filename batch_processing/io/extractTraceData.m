function trialTraceData = extractTraceData(SpikeTraceData,varargin)
	% extracts trace information from spikeE data
	% biafra ahanonu
	% started: 2013.08.05
	% inputs
		%
	% outputs
		%
	% changelog
		%
	% TODO
		%

	%========================
	options.exampleOption = 'doSomething';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	trialLen = size(SpikeTraceData(1,1).Trace,1);
	numCells = size(SpikeTraceData,2);
	trialTraceData = zeros(numCells,trialLen);
	for i=1:numCells
	    trialTraceData(i,:)=SpikeTraceData(1,i).Trace;
	end