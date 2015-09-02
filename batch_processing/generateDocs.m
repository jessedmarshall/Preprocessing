function generateDocs(varargin)
	% generates html documentation of all the functions
	% biafra ahanonu
	% 2014.01.28 [21:12:03]
	% inputs
		%
	% outputs
		%
	% changelog
		%
	% TODO
		%

	loadBatchFxns
	docsPath = './docs';
	try
		rmdir(docsPath,'s');
	catch
	end
	% listOfPaths = addpath(genpath(pwd));
	listOfPaths = {'./','./behavior',	'./classification',	'./filtering',	'./hdf5',	'./image',	'./io',	'./neighbor',	'./pca_ica',	'./pre_process',	'./signal_processing',	'./video',	'./view'};
	%
	m2html('mfiles',listOfPaths, 'htmldir',docsPath, 'recursive','off', 'global','on', 'template','frame', 'index','menu', 'graph','on','save','on');
	%
	mdot('docs/m2html.mat','docs/m2html.dot');
	%
	!dot -Tpng docs/m2html.dot -o docs/m2html.png