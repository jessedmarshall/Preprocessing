function [outputColormap] = customColormap(colorList,varargin)
	% creates a custom colormap
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
	options.nPoints = 50;
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
		if isempty(colorList)
			colorList = {[1 1 1], [0 0 1],[1 0 0]};
		end
		nColors = length(colorList);
		redMap = [];
		greenMap = [];
		blueMap = [];
		for i=1:(nColors-1)
			redMap = [redMap linspace(colorList{i}(1),colorList{i+1}(1),options.nPoints)];
			greenMap = [greenMap linspace(colorList{i}(2),colorList{i+1}(2),options.nPoints)];
			blueMap = [blueMap linspace(colorList{i}(3),colorList{i+1}(3),options.nPoints)];
		end
		outputColormap = [redMap', greenMap', blueMap'];
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end