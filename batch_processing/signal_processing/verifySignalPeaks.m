function [output] = verifySignalPeaks(varargin)
	% uses information from signal source (e.g. the movie) to determine whether a peak as actually occurred
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
		% do something
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end