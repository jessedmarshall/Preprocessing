function [output] = viewLineFilledError(inputMean,inputStd,varargin)
	% makes
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
	options.xValues = [];
	%
	options.lineColor = repmat(0.85,[1 3]);
	% number of std dev. to plot
	options.sigmaNum = 1.96;
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
		if isempty(options.xValues)
			x = 1:length(inputMean);
		else
			x = options.xValues;
		end
    	y = inputMean;
    	dy = options.sigmaNum*inputStd;
    	colorMatrix = hsv(10);
    	colorMatrix = repmat(options.lineColor,[2 1]);
    	randColor = randsample(10,1,false);
    	randColor = 1;
    	fill([x(:);flipud(x(:))],[y(:)-dy(:);flipud(y(:)+dy(:))],colorMatrix(randColor,:),'linestyle','none');
    	line(x,y,'Color',colorMatrix(randColor,:)/1.5);
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end