function [legendHandle] = groupColorLegend(typeArray,colorMatrix,varargin)
	% correctly plots multi-colored legend entries
	% biafra ahanonu
	% 2014.01.23 [10:41:07]
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
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		for i=1:length(typeArray)
		    plot(0,0,'Color',colorMatrix(i,:),'Marker','.','LineStyle','none');
		    hold on
		end
		legendHandle = legend(typeArray);
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end