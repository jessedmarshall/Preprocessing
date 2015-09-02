function [inputMovie ResultsOutOriginal] = turboregMovie(inputMovie, varargin)
	% turboregs a movie, both turboreg and registering images have been parallelized. can also turboreg to one set of images and apply the registration to another set.
	% biafra ahanonu
	% started 2013.11.09 [11:04:18]
	% modified from code created by Jerome Lecoq in 2011 and parallel code update by biafra ahanonu

	% changelog
		% 2013.03.29 - parallelizing turboreg v1
		% 2013.11.09 - completed implementation, appears to work for basic case of a normal MxNxP movie. Need to test on full movie that has a lot of movement to verify and check that it is similar to imageJ. Fixed various naming issues and parfor can now show the percentage
		% 2013.11.10 - refactored so that it can now mroe elegantly handle larger movies during parallelization by chunking
		% 2013.11.30 - late update, but had also changed actual turbo-reg calling to be chunked
		% 2014.01.07 [01:29:02] - now modify 'local' matlabpool config to suit correct number of cores
		% 2014.01.18 [22:36:54] - now (correctly) surrounds the edges with black pixels to avoid screen flickering. NEEDS TO BE IMPROVED.
		% 2014.01.19 [15:50:23] - slight refactoring to improve memory usage.
		% 2014.01.20 [13:19:13] - added mean subtraction and imcomplement to allow for better turboreg
		% 2014.01.28 [17:36:42] - added feature to register a different movie than was turboreged, mainly used for obj aligning after registering global maps.
		% 2014.08.28 [15:01:04] - nested functions for turboreg and register

	% ========================
	% using a compiled version of the ANSI C code developed by Philippe Thevenaz.
	%
	% It uses a MEX file as a gateway between the C code and MATLAB code.
	% All C codes files are available in subfolder 'C'. The interface file is
	% 'turboreg.c'. The main file from Turboreg is 'regFlt3d.c'. Original code
	% has been modified to move new image calculation from C to Matlab to provide
	% additional flexibility.
	% ========================
	% SETTINGS
		% zapMean - If 'zapMean' is set to 'FALSE', the input data is left untouched. If zapMean is set to 'TRUE', the test data is modified by removing its average value, and the reference data is also modified by removing its average value prior to optimization.
		% minGain - An iterative algorithm needs a convergence criterion. If 'minGain' is set to '0.0', new tries will be performed as long as numerical accuracy permits. If 'minGain' is set between '0.0' and '1.0', the computations will stop earlier, possibly to the price of some loss of accuracy. If 'minGain' is set to '1.0', the algorithm pretends to have reached convergence as early as just after the very first successful attempt.
		% epsilon - The specification of machine-accuracy is normally machine-dependent. The proposed value has shown good results on a variety of systems; it is the C-constant FLT_EPSILON.
		% levels - This variable specifies how deep the multi-resolution pyramid is. By convention, the finest level is numbered '1', which means that a pyramid of depth '1' is strictly equivalent to no pyramid at all. For best registration results, the rule of thumb is to select a number of levels such that the coarsest representation of the data is a cube between 30 and 60 pixels on each side. Default value ensure that values
		% lastLevel - It is possible to short-cut the optimization before reaching the finest stages, which are the most time-consuming. The variable 'lastLevel' specifies which is the finest level on which optimization is to be performed. If 'lastLevel' is set to the same value as 'levels', the registration will take place on the coarsest stage only. If 'lastLevel' is set to '1', the optimization will take advantage of the whole multi-resolution pyramid.
	% ========================
	% NOTES
		% If you get error on the availability of turboreg, please consider creating the mex file for your system using the following command in the C folder : mex turboreg.c regFlt3d.c svdcmp.c reg3.c reg2.c reg1.c reg0.c quant.c pyrGetSz.c pyrFilt.c getPut.c convolve.c BsplnWgt.c BsplnTrf.c phil.c
		% if getting blank frames with transfturboreg, install Visual C++ Redistributable Packages for Visual Studio 2013 (http://www.microsoft.com/en-us/download/details.aspx?id=40784)
	% ================================================

	% check that input is not empty
	display('starting turboreg...');
	if isempty(inputMovie)
		return;
	end

	% ========================
	% get options
	% character string, path to save turboreg coordinates
	options.saveTurboregCoords = [];
	% already have registration coordinates
	options.precomputedRegistrationCooords = [];
	% turboreg options
	options.RegisType=3;
	options.SmoothX=80;%10
	options.SmoothY=80;%10
	options.minGain=0.4;
	options.Levels=6;
	options.Lastlevels=1;
	options.Epsilon=1.192092896E-07;
	options.zapMean=0;
	% options.Interp='bicubic';
	options.Interp='bilinear';
	%
	% normal options
	options.refFrame = 1;
	% whether to use 'imtransform' (Matlab) or 'transfturboreg' (C)
	options.registrationFxn = 'transfturboreg';
	% 1 = take turboreg rotation, 0 = no rotation
	options.turboregRotation = 1;
	% normal options
	options.refFrameMatrix = [];
	% max number of frames in the input matrix
	options.maxFrame = [];
	% use parallel registration (using matlab pool)
	options.parallel = 1;
	% close the matlab pool after running?
	options.closeMatlabPool = 1;
	% add a black edge around movie
	options.blackEdge = 0;
	% coordinates to crop, [] = entire FOV, 'manual' = usr input, [top-left-row top-left-col bottom-right-row bottom-right-col]
	options.cropCoords = [];
	% whether to remove the edges
	options.removeEdges = 0;
	% amount of pixels around the border to crop in primary movie
	options.pxToCrop = 4;
	% alternative movie to register
	options.altMovieRegister = [];
	% which coordinates to register alternative movie to, number 2 since normally first cell is the reference turboreg coordinates
	options.altMovieRegisterNum = 2;
	% should a complement (inversion) of each frame be made?
	options.complementMatrix = 1;
	% subtract the mean from each frame?
	options.meanSubtract = 0;
	% highpass or divideByLowpass
	options.normalizeType = 'divideByLowpass';
	% name in HDF5 file where data is stored
	options.inputDatasetName = '/1';
	% bandpass after turboreg but before registering
	options.bandpassBeforeRegister = 0;
	% normalize movie (highpass, etc.) before registering
	options.normalizeBeforeRegister = [];
	% imageJ normalization options
	options.imagejFFTLarge = 10000;
	options.imagejFFTSmall = 80;
	% whether to save the lowpass version before registering, empty if no, string with file path if yes
	options.saveNormalizeBeforeRegister = [];
	% for options.bandpassBeforeRegister
	options.freqLow = 7;
	options.freqHigh = 500;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% % unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================
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
	% ========================
	% register movie and return without using the rest of the function
	if ~isempty(options.precomputedRegistrationCooords)
		ResultsOut = options.precomputedRegistrationCooords;
		ResultsOutOriginal = ResultsOut;
		for resultNo=1:size(inputMovie,3);
			ResultsOutTemp{resultNo} = ResultsOut{options.altMovieRegisterNum};
		end
		ResultsOut = ResultsOutTemp;
		convertInputMovieToCell();
		size(inputMovie)
		class(inputMovie)
		size(inputMovie{1})
		class(inputMovie{1})
		InterpListSelection = turboRegOptions.Interp;
		registerMovie();
		inputMovie = cat(3,inputMovie{:});
		return;
	end
	% ========================
	if ~isempty(options.refFrameMatrix)
		inputMovie(:,:,end+1) = options.refFrameMatrix;
		options.refFrame = size(inputMovie,3);
		% refPic = single(squeeze(inputMovie(:,:,options.refFrame)));
	else
	end
	% ========================
	inputMovieClass = class(inputMovie);
	if strcmp(inputMovieClass,'char')
	    inputMovie = loadMovieList(inputMovie,'inputDatasetName',options.inputDatasetName);
	    % [pathstr,name,ext] = fileparts(inputFilePath);
	    % options.newFilename = [pathstr '\concat_' name '.h5'];
	end
	options.maxFrame = size(inputMovie,3);
	% ========================
	% if input crop coordinates are given, save a copy of the uncropped movie and crop the current movie
	inputMovieCropped = [];
	cropAndNormalizeInputMovie();
	% ========================
	% check maximum number of cores available
	maxCores = feature('numCores')*2-2;
	if maxCores>6
		maxCores = 6;
	end
	% check that local matlabpool configuration is correct
	myCluster = parcluster('local');
	if myCluster.NumWorkers<maxCores
		myCluster.NumWorkers = maxCores; % 'Modified' property now TRUE
		saveProfile(myCluster);   % 'local' profile now updated
	end
	% open works = max core #, probably should do maxCores-1 for stability...
	% check whether matlabpool is already open
	if matlabpool('size') | ~options.parallel
	else
		matlabpool('open',maxCores-1);
	end
	% ========================
	startTime = tic;
	ResultsOut = {};
	ResultsOutOriginal = {};
	averagePictureEdge = [];
	% [ResultsOut averagePictureEdge] = turboregMovieParallel(inputMovieCropped,turboRegOptions,options);
	turboregMovieParallel();

	if ~isempty(options.saveTurboregCoords)
		options.saveTurboregCoords
		ResultsOut
	end
	ResultsOutOriginal = ResultsOut;

	clear inputMovieCropped;
	% ========================
	if ~isempty(options.normalizeBeforeRegister)
		switch options.normalizeBeforeRegister
			case 'imagejFFT'
				imagefFftOnInputMovie('inputMovie');
			case 'divideByLowpass'
				display('dividing movie by lowpass...')
				inputMovie = normalizeMovie(single(inputMovie),'normalizationType','imfilter','blurRadius',20,'waitbarOn',1);
				% [inputMovie] = normalizeMovie(single(inputMovie),...
					% 'normalizationType','lowpassFFTDivisive',...
					% 'freqLow',options.freqLow,'freqHigh',options.freqHigh,...
					% 'bandpassType','lowpass','showImages',0,'bandpassMask','gaussian');
			case 'bandpass'
				display('bandpass filtering...')
				inputMovie = single(inputMovie);
				[inputMovie] = normalizeMovie(single(inputMovie),'normalizationType','fft','freqLow',options.freqLow,'freqHigh',options.freqHigh,'bandpassType','bandpass','showImages',0,'bandpassMask','gaussian');
			otherwise
				% do nothing
		end
	end
	% ========================
	% if cropped movie for turboreg, restore the old input movie for registration
	if ~isempty(options.altMovieRegister)
		display(['preparing to register input #' options.altMovieRegisterNum ', converting secondary input movie...'])
		% ===
		% if we are using the turboreg coordinates for frame #options.altMovieRegisterNum to register all frames from options.altMovieRegister, want to give registerMovie an identical sized array to altMovieRegister like it normally expects
		% this was made for having refCellmap and testCellmap, aligning the testCellmap to the refCellmap then registering all the cell images for testCellmap to refCellmap
		for resultNo=1:size(options.altMovieRegister,3);
			ResultsOutTemp{resultNo} = ResultsOut{options.altMovieRegisterNum};
		end
		ResultsOut = ResultsOutTemp;
		% ===
		%Convert array to cell array, allows slicing (not contiguous memory block)
		% add input movie to
		inputMovie = options.altMovieRegister;
		convertInputMovieToCell();
	elseif ~isempty(options.cropCoords)
		display('restoring uncropped movie and converting to cell...');
		clear registeredMovie;
		%Convert array to cell array, allows slicing (not contiguous memory block)
		convertInputMovieToCell();
		% ===
	else
		display('converting movie to cell...');
		%Convert array to cell array, allows slicing (not contiguous memory block)
		convertInputMovieToCell();
		% ===
	end
	% ========================
	% these don't change (???) so pre-define before loop to reduce overhead and make parfor happy
	InterpListSelection = turboRegOptions.Interp;
	toc(startTime)
	% register movie
	% [inputMovie] = registerMovie(inputMovie,ResultsOut,InterpListSelection,TransformationType,options);
	registerMovie();
	% clear movieData;

	% ========================
	%Close the workers
	if matlabpool('size')&options.closeMatlabPool
		matlabpool close
	end
	toc(startTime)

	% ========================
	display('converting cell array back to matrix')
	%Convert cell array back to 3D matrix
	inputMovie = cat(3,inputMovie{:});
	inputMovie = single(inputMovie);

	% ========================
	if options.removeEdges==1
		removeInputMovieEdges();
	end

	toc(startTime)
	if options.blackEdge==1
		addBlackEdgeToMovie();
	end

	if ~isempty(options.refFrameMatrix)
		display('removing ref picture');
		% inputMovie = inputMovie(:,:,1:end-1);
		inputMovie(:,:,end) = [];
		% refPic = single(squeeze(inputMovie(:,:,options.refFrame)));
	else
		%
	end

	function convertInputMovieToCell()
		%Get dimension information about 3D movie matrix
		[inputMovieX inputMovieY inputMovieZ] = size(inputMovie);
		reshapeValue = size(inputMovie);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		inputMovie = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
	end

	function convertinputMovieCroppedToCell()
		%Get dimension information about 3D movie matrix
		[inputMovieX inputMovieY inputMovieZ] = size(inputMovieCropped);
		reshapeValue = size(inputMovieCropped);
		%Convert array to cell array, allows slicing (not contiguous memory block)
		inputMovieCropped = squeeze(mat2cell(inputMovieCropped,inputMovieX,inputMovieY,ones(1,inputMovieZ)));
	end

	% function [ResultsOut averagePictureEdge] = turboregMovieParallel(inputMovie,turboRegOptions,options)
	function turboregMovieParallel()
		% get reference picture and other pre-allocation
		postProcessPic = single(squeeze(inputMovieCropped(:,:,options.refFrame)));
		mask=single(ones(size(postProcessPic)));
		imgRegMask=single(double(mask));
		% we add an offset to be able to give NaN to black borders
		averagePictureEdge=zeros(size(imgRegMask));
		refPic = single(squeeze(inputMovieCropped(:,:,options.refFrame)));

		MatrixMotCorrDispl=zeros(3,options.maxFrame);

		% ===
		%Convert array to cell array, allows slicing (not contiguous memory block)
		convertinputMovieCroppedToCell();
		% ===

		% Get data class, can be removed...
		movieClass = class(inputMovieCropped);
		% you need this FileExchange function for progress in a parfor loop
		% parfor_progress(options.maxFrame);
		display('turboreg-ing...');

		% parallel for loop, since each turboreg operation is independent, can send each frame to separate workspaces
		startTurboRegTime = tic;
		%
		parfor frameNo=1:options.maxFrame
			% get current frames
			thisFrame = inputMovieCropped{frameNo};
			thisFrameToAlign=single(thisFrame);
			[ImageOut,ResultsOut{frameNo}]=turboreg(refPic,thisFrameToAlign,mask,imgRegMask,turboRegOptions);
			% create a mask
			averagePictureEdge = averagePictureEdge | ImageOut==0;
		end
		toc(startTurboRegTime);
		drawnow;
		save('ResultsOutFile','ResultsOut');
	end

	% function registerMovie(movieData,ResultsOut,InterpListSelection,TransformationType,options)
	function registerMovie()
		display('registering frames...');
		% need to register subsets of the movie so parfor won't crash due to serialization errors
		% TODO: make this subset based on the size of the movie, e.g. only send 1GB chunks to workers
		subsetSize = 1000;
		numSubsets = ceil(length(inputMovie)/subsetSize)+1;
		subsetList = round(linspace(1,length(inputMovie),numSubsets));
		subsetList
		% ResultsOut{1}.Rotation
		nSubsets = (length(subsetList)-1);
		for thisSet=1:nSubsets
			subsetStartIdx = subsetList(thisSet);
			subsetEndIdx = subsetList(thisSet+1);
			if thisSet==nSubsets
				movieSubset = subsetStartIdx:subsetEndIdx;
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			else
				movieSubset = subsetStartIdx:(subsetEndIdx-1);
				display([num2str(subsetStartIdx) '-' num2str(subsetEndIdx-1) ' ' num2str(thisSet) '/' num2str(nSubsets)])
			end
			movieDataTemp(movieSubset) = inputMovie(movieSubset);
			% loop over and register each frame
			% parfor_progress(length(movieSubset));
			parfor i=movieSubset
				% thisFrame = movieDataTemp{i};
				% get rotation and translation profile for image
				if options.turboregRotation==1
					MatrixMotCorrDispl(:,i)=[ResultsOut{i}.Translation(1) ResultsOut{i}.Translation(2) ResultsOut{i}.Rotation];
				else
					MatrixMotCorrDispl(:,i)=[ResultsOut{i}.Translation(1) ResultsOut{i}.Translation(2) 0];
				end
				% get the skew/translation matrix from turboreg
				SkewingMat=ResultsOut{i}.Skew;
				translateMat=[0 0 0;0 0 0;ResultsOut{i}.Translation(2) ResultsOut{i}.Translation(1) 0];
				xform=translateMat+SkewingMat;
				% get the transformation
				tform=maketform(TransformationType,double(xform));
				% transform movie given results of turboreg
				switch options.registrationFxn
					case 'imtransform'
						% movieDataTemp{i} = imwarp(movieDataTemp{i},tform,char(InterpListSelection),'FillValues',0);
						% InterpListSelection = 'nearest';
						movieDataTemp{i} = single(imtransform(movieDataTemp{i},tform,char(InterpListSelection),...
							'UData',[1 size(movieDataTemp{i},2)]-ResultsOut{i}.Origin(2)-1,...
							'VData',[1 size(movieDataTemp{i},1)]-ResultsOut{i}.Origin(1)-1,...
							'XData',[1 size(movieDataTemp{i},2)]-ResultsOut{i}.Origin(2)-1,...
							'YData',[1 size(movieDataTemp{i},1)]-ResultsOut{i}.Origin(1)-1,...
							'fill',NaN));
					case 'transfturboreg'
						frameClass = class(movieDataTemp{i});
						movieDataTemp{i} = ...
						cast(...
							transfturboreg(...
								single(movieDataTemp{i}),...
								ones(size(movieDataTemp{i}),'single'),...
								ResultsOut{i}),...
							frameClass);
					otherwise
						% do nothing
				end
				% if mod(movieSubset(2),20)==0
				% 	percent = parfor_progress;
				% 	display(num2str(percent));
				% end
			end
			inputMovie(movieSubset)=movieDataTemp(movieSubset);
			clear movieDataTemp;
			% parfor_progress(0);
		end
	end
	function removeInputMovieEdges()
		if size(inputMovie,2)>=size(inputMovie,1)
			coords(1) = options.pxToCrop; %xmin
			coords(2) = options.pxToCrop; %ymin
			coords(3) = size(inputMovie,1)-options.pxToCrop;   %xmax
			coords(4) = size(inputMovie,2)-options.pxToCrop;   %ymax
		else
			coords(1) = options.pxToCrop; %xmin
			coords(2) = options.pxToCrop; %ymin
			coords(4) = size(inputMovie,1)-options.pxToCrop;   %xmax
			coords(3) = size(inputMovie,2)-options.pxToCrop;   %ymax
		end

		rowLen = size(inputMovie,1);
		colLen = size(inputMovie,2);
		% a,b are left/right column values
		a = coords(1);
		b = coords(3);
		% c,d are top/bottom row values
		c = coords(2);
		d = coords(4);
		% set those parts of the movie to NaNs
		inputMovie(1:rowLen,1:a,:) = NaN;
		inputMovie(1:rowLen,b:colLen,:) = NaN;
		inputMovie(1:c,1:colLen,:) = NaN;
		inputMovie(d:rowLen,1:colLen,:) = NaN;

		% put black around the edges
		dimsT = size(inputMovie);
		minMovie=min(inputMovie,[],3);
		% 	maxMovie=max(inputMovie,[],3);
		% 	varMovie=var(inputMovie,[],3);
		meanM = mean(minMovie(:));
		stdM = std(minMovie(:));
		minFrame = minMovie<(meanM-2.5*stdM);
		removeFrameIdx = find(minFrame);
		% 	maxFrameIdx = find(maxMovie>2);
		% croppedtMovie = zeros(dimsT);
		for i=1:dimsT(3)
		    thisFrame = inputMovie(:,:,i);
		    thisFrame(removeFrameIdx) = 0;
		    inputMovie(:,:,i) = thisFrame;
		end
	end
	function addBlackEdgeToMovie()
		% We project along z and make a nice binary image with 0 on the sides
		averagePictureEdge=~averagePictureEdge;

		StatsRegion = regionprops(averagePictureEdge,'Extrema');
		% [x y]
		% [top-left
		% top-right
		% right-top
		% right-bottom
		% bottom-right
		% bottom-left
		% left-bottom
		% left-top]
		TopIndice=[1 2 3 8];
		LeftIndice=[1 6 7 8];
		RightIndice=[2 3 4 5];
		BottomIndice=[4 5 6 7];

		extremaMatrix = StatsRegion.Extrema;
		xmin=ceil(max(extremaMatrix(LeftIndice,1)));
		ymin=ceil(max(extremaMatrix(TopIndice,2)));
		xmax=floor(min(extremaMatrix(RightIndice,1)));
		ymax=floor(min(extremaMatrix(BottomIndice,2)));

		rectCrop=[xmin ymin xmax-xmin ymax-ymin];

		[figHandle figNo] = openFigure(100, '');
		imagesc(imcrop(inputMovie(:,:,1),rectCrop));
		% To get the final size, we just apply on the first figure
		% for i=1:dimsT(3)
		% 	thisFrame = inputMovie(:,:,i);
		% 	inputMovie(:,:,i)=imcrop(thisFrame,rectCrop);
		% end
	end
	function imagefFftOnInputMovie(inputMovieName)
		display('dividing movie by lowpass via imageJ...')
		% inputMovie = normalizeMovie(single(inputMovie),'normalizationType','imagejFFT','waitbarOn',1);
		% opens imagej
		% MUST ADD \Fiji.app\scripts
		% open imagej instance
		% Miji(false);
		startTime = tic;
		% pass matrix to imagej
		mijiAlreadyOpen = 0;
		try
			switch inputMovieName
				case 'inputMovie'
					MIJ.createImage('result', inputMovie, true);
				case 'inputMovieCropped'
					MIJ.createImage('result', inputMovieCropped, true);
				otherwise
					% body
			end
			mijiAlreadyOpen = 1;
		catch
			Miji;
			switch inputMovieName
				case 'inputMovie'
					MIJ.createImage('result', inputMovie, true);
				case 'inputMovieCropped'
					MIJ.createImage('result', inputMovieCropped, true);
				otherwise
					% body
			end
		end
		commandwindow
		% settings taken from original imagej implementation
		bpstr= [' filter_large=' num2str(options.imagejFFTLarge) ' filter_small=' num2str(options.imagejFFTSmall) ' suppress=None tolerance=5 process'];
		MIJ.run('Bandpass Filter...',bpstr);
		% grab the image from imagej
		inputMovieFFT = MIJ.getCurrentImage;
		% mijiAlreadyOpen
		MIJ.run('Close');
		% close imagej instance
		if mijiAlreadyOpen==0
			MIJ.exit;
		end
		toc(startTime);
		% divide lowpass from image

		switch inputMovieName
			case 'inputMovie'
				inputMovie = bsxfun(@rdivide,single(inputMovie),single(inputMovieFFT));
			case 'inputMovieCropped'
				inputMovieCropped = bsxfun(@rdivide,single(inputMovieCropped),single(inputMovieFFT));
			otherwise
				% body
		end
		% choose whether to save a copy of the lowpass fft
		% expand this to include the raw turboreg
		if ~isempty(options.saveNormalizeBeforeRegister)
			display('saving lowpass...')
			if ~isempty(options.refFrameMatrix)
				inputMovieFFT = inputMovieFFT(:,:,1:end-1);
			end
			if exist(options.saveNormalizeBeforeRegister,'file')
				appendDataToHdf5(options.saveNormalizeBeforeRegister, options.inputDatasetName, inputMovieFFT);
			else
				createHdf5File(options.saveNormalizeBeforeRegister, options.inputDatasetName, inputMovieFFT);
			end
		end
		clear inputMovieFFT;
	end
	function cropAndNormalizeInputMovie()
		if strcmp(options.cropCoords,'manual')
			cc = getCropSelection(inputMovie(:,:,1));
			inputMovieCropped = inputMovie(cc(2):cc(4), cc(1):cc(3), :);
			display(['cropped dims: ' num2str(size(inputMovieCropped))])
		elseif ~isempty(options.cropCoords)
			display('cropping stack...');
			cc = options.cropCoords;
			inputMovieCropped = inputMovie(cc(2):cc(4), cc(1):cc(3), :);
			% Display the subsetted image with appropriate axis ratio
			[~,~] = openFigure(9, '');
			subplot(1,2,1);imagesc(inputMovie(:,:,1));title('original');
			axis image; colormap gray; drawnow;
			subplot(1,2,2);imagesc(inputMovieCropped(:,:,1));title('cropped region');
			axis image; colormap gray; drawnow;
			display(['cropped dims: ' num2str(size(inputMovie))])
			display(['cropped dims: ' num2str(size(inputMovieCropped))])
		else
			inputMovieCropped = inputMovie;
		end
		% do mean subtraction and matrix inversion to improve turboreg
		Ntime = size(inputMovieCropped,3);
		if options.meanSubtract==1
			switch options.normalizeType
				case 'imagejFFT'
					imagefFftOnInputMovie('inputMovieCropped');
				case 'divideByLowpass'
					display('dividing movie by lowpass...')
					inputMovieCropped = normalizeMovie(single(inputMovieCropped),'normalizationType','imfilter','blurRadius',20,'waitbarOn',1);
					% playMovie(inputMovieCropped);
				case 'highpass'
					display('high-pass filtering...')
					[inputMovieCropped] = normalizeMovie(single(inputMovieCropped),'normalizationType','fft','freqLow',7,'freqHigh',500,'bandpassType','lowpass','showImages',0,'bandpassMask','gaussian');
					% [inputMovieCropped] = normalizeMovie(single(inputMovieCropped),'normalizationType','fft','freqLow',1,'freqHigh',7,'bandpassType','lowpass','showImages',0,'bandpassMask','gaussian');
				otherwise
					% do nothing
			end

			if options.complementMatrix==1
				display('mean subtracting and complementing matrix...');
			else
				display('mean subtracting...');
			end
			reverseStr = '';
			for frameInd=1:Ntime
			    thisFrame=squeeze(inputMovieCropped(:,:,frameInd));
			    meanThisFrame = mean(thisFrame(:));
			    inputMovieCropped(:,:,frameInd) = inputMovieCropped(:,:,frameInd)-meanThisFrame;
			    if options.complementMatrix==1
			    	inputMovieCropped(:,:,frameInd) = imcomplement(inputMovieCropped(:,:,frameInd));
			    end
			    reverseStr = cmdWaitbar(frameInd,Ntime,reverseStr,'inputStr','normalizing movie','waitbarOn',1,'displayEvery',5);
			end
		end
		% GammaValue = 2.95
		% GammaValue = 0.25
		% inputMovieCropped = 255 * (inputMovieCropped/255).^ GammaValue;
		% playMovie(inputMovieCropped);
	end
end
function cropCoords = getCropSelection(thisFrame)
	% get a crop of the input region
	[~,~] = openFigure(9, '');
	subplot(1,2,1);imagesc(thisFrame); axis image; colormap gray; title('select region')

	% Use ginput to select corner points of a rectangular
	% region by pointing and clicking the subject twice
	p = ginput(2);

	% Get the x and y corner coordinates as integers
	cropCoords(1) = min(floor(p(1)), floor(p(2))); %xmin
	cropCoords(2) = min(floor(p(3)), floor(p(4))); %ymin
	cropCoords(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
	cropCoords(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

	% Index into the original image to create the new image
	thisFrameCropped = thisFrame(cropCoords(2):cropCoords(4), cropCoords(1): cropCoords(3));

	% Display the subsetted image with appropriate axis ratio
	[~, ~] = openFigure(9, '');
	subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;
end