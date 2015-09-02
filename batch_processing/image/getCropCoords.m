function [coords] = getCropCoords(thisFrame,varargin)
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
		figure(1110);imagesc(thisFrame);colormap gray;
		p = ginput(2);
		% Get the x and y corner coordinates as integers
		coords(1) = min(floor(p(1)), floor(p(2))); %xmin
		coords(2) = min(floor(p(3)), floor(p(4))); %ymin
		coords(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
		coords(4) = max(ceil(p(3)), ceil(p(4)));   %ymax
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end