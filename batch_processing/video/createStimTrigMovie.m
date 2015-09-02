function [output] = createStimTrigMovie(inputMovie,inputAlignPts,savePathName,varargin)
	% example function with outline for necessary components
	% biafra ahanonu
	% fxn started: 2014.08.13 - broke off from controllerAnalysis script from ~2014.03
	% inputs
		% inputMovie - path to movie file, in cell array, e.g. {'path.h5'}
		% inputAlignPts - vector containing the frames to align to
		% savePathName - path to save output movie, exclude the extension.
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% how much to offset the movie from the stimuli
	options.preOffset = 20;
	options.postOffset = 40;
	% make a montage of just input movie to the stimulus
	options.movieMontage = 1;
	options.montageSuffix = '_montage.h5';
	% obtain behavior video?
	options.videoDir = [];
	% regular expression used to find matching video
	options.videoTrialRegExp = [];
	% is the secondary video at a higher framerate?
	options.downsampleFactor = 4;
	%
	options.stimTriggerOffset = 0;
	% convert movies to double
	options.convertToDouble = 0;
	% naming scheme for side-by-side
	options.sideBySideSuffix = '_sideBySide.h5';
	% 1 = output movie, 0 = output whether saving was successful
	options.outputMovie = 0;
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
		% some constants
		output = 0;
		preOffset = options.preOffset;
		postOffset = options.postOffset;
		framesToAlign = inputAlignPts;
		movieList = inputMovie;
		timeVector = [-preOffset:postOffset]';

		% if no stimuli found, return
		framesToAlign = unique(framesToAlign);
		if isempty(framesToAlign)
			display(repmat('@',1,7))
			display(['no stimuli'])
			display(repmat('@',1,7))
			return;
		end
		movieDims = loadMovieList(movieList{1},'getMovieDims',1);
		nPoints = movieDims.z(1)
		% nPoints = max(framesToAlign);
		%remove points outside valid range
		framesToAlign(find((framesToAlign<preOffset))) = [];
		framesToAlign(find((framesToAlign>(nPoints-postOffset)))) = [];

		%
		framesToAlignVector = zeros([1 length(framesToAlign)]);
		framesToAlignVector(framesToAlign) = 1;
		% remove points outside valid range
		framesToAlignVector(find((framesToAlignVector<preOffset))) = [];
		framesToAlignVector(find((framesToAlignVector>(nPoints-postOffset)))) = [];

		if options.stimTriggerOffset==1
			peakIdxs = bsxfun(@plus,timeVector,framesToAlignVector(:)');
			nAlignPts = length(framesToAlignVector(:));
		else
			peakIdxs = bsxfun(@plus,timeVector,framesToAlign(:)');
			nAlignPts = length(framesToAlign(:));
		end
		% framesToAlign

		% remove frame alignment outside range
		peakIdxs(find((peakIdxs<1))) = [];
		peakIdxs(find((peakIdxs>nPoints))) = [];

		if ~isempty(peakIdxs(:))
			% load movie
			primaryMovie = loadMovieList(movieList{1},'convertToDouble',options.convertToDouble,'frameList',peakIdxs(:));
			% primaryMovie = loadMovieList(,'convertToDouble',options.convertToDouble,'frameList',peakIdxs(:));

			% primaryMovie = createMovieMontage(primaryMovie,nAlignPts,timeVector,postOffset,preOffset,options.montageSuffix,savePathName,1);

			% try to load behavioral movie
			if ~isempty(options.videoDir)
				vidList = getFileList(options.videoDir,options.videoTrialRegExp);
				if ~isempty(vidList)
					% get the movie
					behaviorMovie = loadMovieList(vidList{1},'convertToDouble',options.convertToDouble,'frameList',peakIdxs(:)*options.downsampleFactor);
					% behaviorMovie = createMovieMontage(behaviorMovie,nAlignPts,timeVector,postOffset,preOffset,options.montageSuffix,savePathName,0);

					[outputMovie] = createSideBySide(behaviorMovie,primaryMovie,'pxToCrop',[]);
					if options.movieMontage==1
						createMovieMontage(outputMovie,nAlignPts,timeVector,postOffset,preOffset,options.montageSuffix,savePathName,1);
					end
				else
					display(['no vid file: ' options.videoDir ' | ' options.videoTrialRegExp])
					outputMovie = primaryMovie;
					clear primaryMovie;
				end
			else
				display('no video directory...')
				outputMovie = primaryMovie;
				clear primaryMovie;
			end
			% save movie
			[output] = writeHDF5Data(outputMovie,[savePathName options.sideBySideSuffix]);
		else
			display('no stimuli!')
		end
		if options.outputMovie==1
			output = outputMovie;
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end

function [k] = createMovieMontage(inputMovie,nAlignPts,timeVector,postOffset,preOffset,montageSuffix,savePathName,saveFile)
	% example function with outline for necessary components
	% biafra ahanonu
	% fxn started: 2014.08.13 - broke off from controllerAnalysis script from ~2014.03
	% inputs
		% inputMovie - path to movie file, in cell array, e.g. {'path.h5'}
		% inputAlignPts - vector containing the frames to align to
		% savePathName - path to save output movie, exclude the extension.
	% outputs
		%

	display('creating montage...');
	% =======================
	% SAVE AN ARRAY of the movie cut to the alignment pt
	% this is super hacky at the moment, but it WORKs, so don't whine. Basically trying to make a square matrix of the primary movie cut to the stimulus. Convert to cell array, add a fake movie that blips at stimulus, line up all movies horizontally then cut into rows determined by the number of stimuli...
	[m n t] = size(inputMovie);
	nStims = nAlignPts;
	stimLength = length(timeVector(:));
	k = mat2cell(inputMovie,m,n,stimLength*ones([1 nStims]));
	tmpMovie = NaN([m n stimLength]);
	tmpMovie(:,:,preOffset+1) = 1e5;
	% tmpMovie(:,:,ceil(stimLength/2)) = 1;
	k{end+1} = tmpMovie;
	%playMovie([k{:}])
	[xPlot yPlot] = getSubplotDimensions(nStims+1)
	squareNeed = xPlot*yPlot;
	length(k);
	dimDiff = squareNeed-length(k);
	for ii=1:dimDiff
		k{end+1} = NaN([m n stimLength]);
	end
	size(k);
	k = [k{:}];
	[m2 n2 t2] = size(k);
	nRows = yPlot+1;
	splitIdx = diff(ceil(linspace(1,n2,nRows)));
	splitIdx(end) = splitIdx(end)+1;
	k = mat2cell(k,m2,splitIdx,t2);
	k = vertcat(k{:});
	if saveFile==1
		saveDir = [savePathName montageSuffix];
		[pathstr,name,ext] = fileparts(saveDir);
		saveDir = [pathstr filesep 'montage' filesep name ext];
		writeHDF5Data(k,saveDir);
	end
	% clear k;
	% ======================
end