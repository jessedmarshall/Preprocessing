function [xPlot yPlot] = getSubplotDimensions(nPlots,varargin)
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

	try
		nPlotsRoot = sqrt(nPlots);
		integ = fix(nPlotsRoot);
		fract = abs(nPlotsRoot - integ);
		yPlot = ceil(nPlotsRoot);
		xPlot = floor(nPlotsRoot)+round(fract);
		% if (fract < 0.5)
		%     xPlot = floor(nPlotsRoot);
		% else
		%     xPlot = ceil(nPlotsRoot);
		% end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end