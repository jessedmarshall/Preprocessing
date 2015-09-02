function [registeredMovie] = turboregMovie(inputMovie, varargin)
	% biafra ahanonu
	% started 2013.11.09 [11:04:18]
	% turboregs a movie, implements the parfor turboreg
	% based code created by Jerome Lecoq in 2011 and parallel code update by biafra ahanonu
	% changelog
		% 2013.11.09 - completed implementation, appears to work for basic case of a normal MxNxP movie. Need to test on full movie that has a lot of movement to verify and check that it is similar to imageJ. Fixed various naming issues and parfor can now show the percentage
		% 2013.11.10 - refactored so that it can now mroe elegantly handle larger movies during parallelization by chunking
	%========================
	% using a compiled version of the ANSI C code developed by Philippe Thevenaz.
	%
	% It uses a MEX file as a gateway between the C code and MATLAB code.
	% All C codes files are available in subfolder 'C'. The interface file is
	% 'turboreg.c'. The main file from Turboreg is 'regFlt3d.c'. Original code
	% has been modified to move new image calculation from C to Matlab to provide
	% additional flexibility.
	%========================
	% SETTINGS
	%
	%
	% zapMean
	%      If 'zapMean' is set to 'FALSE', the input data is left untouched. If zapMean is set
	%      to 'TRUE', the test data is modified by removing its average value, and the reference
	%      data is also modified by removing its average value prior to optimization.
	%
	% minGain
	%      An iterative algorithm needs a convergence criterion. If 'minGain' is set to '0.0',
	%      new tries will be performed as long as numerical accuracy permits. If 'minGain'
	%      is set between '0.0' and '1.0', the computations will stop earlier, possibly to the
	%      price of some loss of accuracy. If 'minGain' is set to '1.0', the algorithm pretends
	%      to have reached convergence as early as just after the very first successful attempt.
	%
	% epsilon
	%      The specification of machine-accuracy is normally machine-dependent. The proposed
	%      value has shown good results on a variety of systems; it is the C-constant FLT_EPSILON.
	%
	% levels
	%      This variable specifies how deep the multi-resolution pyramid is. By convention, the
	%      finest level is numbered '1', which means that a pyramid of depth '1' is strictly
	%      equivalent to no pyramid at all. For best registration results, the rule of thumb is
	%      to select a number of levels such that the coarsest representation of the data is a
	%      cube between 30 and 60 pixels on each side. Default value ensure that values
	%
	% lastLevel
	%      It is possible to short-cut the optimization before reaching the finest stages, which
	%      are the most time-consuming. The variable 'lastLevel' specifies which is the finest
	%      level on which optimization is to be performed. If 'lastLevel' is set to the same value
	%      as 'levels', the registration will take place on the coarsest stage only. If
	%      'lastLevel' is set to '1', the optimization will take advantage of the whole multi-
	%      resolution pyramid.
	%========================
	% NOTES
	%
	% If you get error on the availability of turboreg, please consider
	% creating the mex file for your system using the following command in the C folder :
	% mex turboreg.c regFlt3d.c svdcmp.c reg3.c reg2.c reg1.c reg0.c quant.c pyrGetSz.c pyrFilt.c getPut.c convolve.c BsplnWgt.c BsplnTrf.c phil.c
	%================================================
	%%
	% check that input is not empty
	display('starting turboreg...');
	if isempty(inputMovie)
		return;
	end
	%========================
	% get options
	% turboreg options
	options.RegisType=1;
	options.SmoothX=2;
	options.SmoothY=2;
	options.minGain=0.4;
	options.Levels=1;
	options.Lastlevels=2;
	options.Epsilon=1.192092896E-07;
	options.zapMean=0;
	options.Interp='bicubic';
	% normal options
	options.RefFrame = 1;
	options.maxFrame = size(inputMovie,3);
	options.parallel = 1;
	options.blackEdge = 0;
	options.cropCoords = [];
	% get options
	options = getOptions(options,varargin);
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%%
	%========================
	% add turboreg options to turboRegOptions structure
	turboRegOptions.RegisType=options.RegisType;
	turboRegOptions.SmoothX=options.SmoothX;
	turboRegOptions.SmoothY=options.SmoothY;
	turboRegOptions.minGain=options.minGain;
	turboRegOptions.Levels=options.Levels;
	turboRegOptions.Lastlevels=options.Lastlevels;
	turboRegOptions.Epsilon=options.Epsilon;
	turboRegOptions.zapMean=options.zapMean;
	turboRegOptions.Interp=options.Interp;
	if (turboRegOptions.RegisType==1 || turboRegOptions.RegisType==2)
		TransformationType='affine';
	else
		TransformationType='projective';
	end
	%%
	%========================
	% if input crop coordinates are given, save a copy of the uncropped movie and crop the current movie
	if ~isempty(options.cropCoords)
		display('cropping stack...');
		options.cropCoords
		cc = options.cropCoords;
		inputMovieOld = inputMovie;
		inputMovie = inputMovie(cc(2):cc(4), cc(1):cc(3), :);
		size(inputMovie)
	end
	whos
	%========================
	%========================
	%%
	% biafra ahanonu
	% started: 2013.03.29
	% parallelizing turboreg v1
	startTime = tic;

	% turboreg movie
	[movieData ResultsOut averagePictureEdge] = turboregMovieParallel(inputMovie,turboRegOptions,options);

	% if cropped movie for turboreg, restore the old input movie for registration
	if ~isempty(options.cropCoords)
		display('restoring uncropped movie...');
		clear movieData;
		[movieData] = convertMatrixToCell(inputMovieOld);
		clear inputMovieOld;
	end

	% these don't change (???) so pre-define before loop to reduce overhead and make parfor happy
	InterpListSelection = turboRegOptions.Interp;
	toc(startTime)
	% register movie
	[movieData] = registerMovie(movieData,ResultsOut,InterpListSelection,TransformationType);

	%Close the workers
	if  matlabpool('size')
		% matlabpool close
	end
	toc(startTime)
	display('converting cell array back to matrix')
	%Convert cell array back to 3D matrix
	registeredMovie = cat(3,movieData{:});
	clear movieData;
	% tempCell = cell2mat(movieData);
	% clear movieData;
	% [r,c]=size(tempCell);
	% registeredMovie = permute(reshape(tempCell',[c,r/MaxFrame,MaxFrame]),[2,1,3]);
	% clear tempCell;
	% size(registeredMovie)
	%Free up memory
	% clear movieData tempCell movieDataTempMatrix;
	toc(startTime)

	if options.blackEdge==1
		% We project along z and make a nice binary image with 0 on the sides
		AveragePictureEdge=~AveragePictureEdge;

		StatsRegion = regionprops(AveragePictureEdge,'Extrema');
		TopIndice=[1 2 3 8];
		LeftIndice=[1 6 7 8];
		RightIndice=[2 3 4 5];
		BottomIndice=[4 5 6 7];

		xmin=ceil(max(StatsRegion.Extrema(LeftIndice,1)));
		ymin=ceil(max(StatsRegion.Extrema(TopIndice,2)));
		xmax=floor(min(StatsRegion.Extrema(RightIndice,1)));
		ymax=floor(min(StatsRegion.Extrema(BottomIndice,2)));

		RectCrop=[xmin ymin xmax-xmin ymax-ymin];
		dividerWaitbar=10^(floor(log10(SpikeMovieData(CurrentMovie).DataSize(3)))-1);

		% To get the final size, we just apply on the first figure
		TestMovie=imcrop(SpikeMovieData(CurrentMovie).Movie(:,:,1),RectCrop);
		FinalNumRows=size(TestMovie,1);
		FinalNumCols=size(TestMovie,2);
	end

function [movieData] = convertMatrixToCell(inputMovie)
	%Get dimension information about 3D movie matrix
	[inputMovieX inputMovieY inputMovieZ] = size(inputMovie);
	reshapeValue = size(inputMovie);
	%Convert array to cell array, allows slicing (not contiguous memory block)
	movieData = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));

function [movieData ResultsOut averagePictureEdge] = turboregMovieParallel(inputMovie,turboRegOptions,options)

	% get reference picture and other pre-allocation
	postProcessPic = single(squeeze(inputMovie(:,:,options.RefFrame)));
	% figure(22233);colormap gray; imagesc(postProcessPic);
	mask=single(ones(size(postProcessPic)));
	imgRegMask=single(double(mask));
	% we add an offset to be able to give NaN to black borders
	averagePictureEdge=zeros(size(imgRegMask));
	refPic = single(squeeze(inputMovie(:,:,options.RefFrame)));

	MatrixMotCorrDispl=zeros(3,options.maxFrame);

	% convert to cell
	[movieData] = convertMatrixToCell(inputMovie);
	clear inputMovie;

	% check maximum number of cores available
	maxCores = feature('numCores')*2-1;
	if maxCores>6
		maxCores = 6;
	end
	% open works = max core #, probably should do maxCores-1 for stability...
	% check whether matlabpool is already open
	if matlabpool('size') | ~options.parallel
	else
		matlabpool('open',maxCores);
	end

	% Get data class, can be removed...
	movieClass = class(movieData);
	% you need this FileExchange function for progress in a parfor loop
	% parfor_progress(options.maxFrame);
	display('turboreg-ing...');

	% parallel for loop, since each turboreg operation is independent, can send each frame to separate workspaces
	% subset the data so the workers have less data being transfered at once
	subsetSize = 1000;
	numSubsets = ceil(length(movieData)/subsetSize)+1;
	subsetList = round(linspace(1,length(movieData),numSubsets));
	startTurboRegTime = tic;
	for thisSet=1:(length(subsetList)-1)
		display([num2str(subsetList(thisSet)) ' ' num2str(subsetList(thisSet+1)) ' ' num2str(subsetList(thisSet+1)/subsetList(end))])
		movieSubset = subsetList(thisSet):subsetList(thisSet+1);
		movieDataTemp(movieSubset) = movieData(movieSubset);
		parfor i=1:options.maxFrame
			% get current frames
			thisFrameToAlign=10+single(movieData{i});
			thisFrame = movieData{i};
			%Run turboreg on image
			% [ImageOut,ResultsOut]=turboreg(refPic,ToAlign,mask,imgRegMask,turboRegOptions);
			[~,ResultsOut{i}]=turboreg(refPic,thisFrameToAlign,mask,imgRegMask,turboRegOptions);
			% We project along z and make a nice binary image with 0 on the sides
			averagePictureEdge=averagePictureEdge | thisFrame==0;
			% if mod(options.maxFrame,20)==0
			% 	percent = parfor_progress;
			% 	display(num2str(percent));
			% end
		end
		movieData(movieSubset)=movieDataTemp(movieSubset);
		clear movieDataTemp;
		toc(startTurboRegTime);
		% parfor_progress(0);
	end
function [movieData] = registerMovie(movieData,ResultsOut,InterpListSelection,TransformationType)
	display('registering frames...');
	% need to register subsets of the movie so parfor won't crash due to serialization errors
	% TODO: make this subset based on the size of the movie, e.g. only send 1GB chunks to workers
	subsetSize = 1000;
	numSubsets = ceil(length(movieData)/subsetSize)+1;
	subsetList = round(linspace(1,length(movieData),numSubsets));
	for thisSet=1:(length(subsetList)-1)
		display([num2str(subsetList(thisSet)) ' ' num2str(subsetList(thisSet+1)) ' ' num2str(subsetList(thisSet+1)/subsetList(end))])
		movieSubset = subsetList(thisSet):subsetList(thisSet+1);
		movieDataTemp(movieSubset) = movieData(movieSubset);
		% loop over and register each frame
		% parfor_progress(length(movieSubset));
		parfor i=movieSubset
			% thisFrame = movieDataTemp{i};
			% get rotation and translation profile for image
			MatrixMotCorrDispl(:,i)=[ResultsOut{i}.Translation(1) ResultsOut{i}.Translation(2) ResultsOut{i}.Rotation];
			% get the skew/translation matrix from turboreg
			SkewingMat=ResultsOut{i}.Skew;
			translateMat=[0 0 0;0 0 0;ResultsOut{i}.Translation(2) ResultsOut{i}.Translation(1) 0];
			xform=translateMat+SkewingMat;
			% get the transformation
			tform=maketform(TransformationType,double(xform));
			% transform movie given results of turboreg
			%
			% movieDataTemp{i} = imwarp(movieDataTemp{i},tform,char(InterpListSelection),'FillValues',0);
			movieDataTemp{i}=imtransform(movieDataTemp{i},tform,char(InterpListSelection),...
				'UData',[1 size(movieDataTemp{i},2)]-ResultsOut{i}.Origin(2)-1,...
				'VData',[1 size(movieDataTemp{i},1)]-ResultsOut{i}.Origin(1)-1,...
				'XData',[1 size(movieDataTemp{i},2)]-ResultsOut{i}.Origin(2)-1,...
				'YData',[1 size(movieDataTemp{i},1)]-ResultsOut{i}.Origin(1)-1,...
				'FillValues',0);
			% if mod(movieSubset(2),20)==0
			% 	percent = parfor_progress;
			% 	display(num2str(percent));
			% end
		end
		movieData(movieSubset)=movieDataTemp(movieSubset);
		clear movieDataTemp;
		% parfor_progress(0);
	end