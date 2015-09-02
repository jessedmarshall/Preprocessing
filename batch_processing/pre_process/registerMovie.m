function [registeredMovie] = registerMovie(inputMovie,varargin)
	% takes an input movie and registers it to a set frame
	% biafra ahanonu
	% started: 2014.03.21
	% inputs
		%
	% outputs
		%
	% sources
		% http://www.mathworks.com/help/images/registering-an-image.html
		% http://www.mathworks.com/help/vision/examples/find-image-rotation-and-scale-using-automated-feature-matching.html?prodcode=VP
		% http://www.mathworks.com/company/newsletters/articles/automating-image-registration-with-matlab.html
		% http://www.mathworks.com/help/images/ref/imregister.html
		% http://www.mathworks.com/help/images/-automatic-registration.html
		% http://www.mathworks.com/discovery/image-registration.html

	% changelog
		%
	% TODO
		%


	%========================
	% type of method to use for registration
	options.registerType = 'imregister';
	%
	options.refFrameNo = 1;
	%
	options.parallel = 0;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	openCloseMatlabPool(options);

	try
		switch options.registerType
			case 'imregister'
				if options.parallel==0
					[optimizer,metric] = imregconfig('Multimodal');
					dimsMovie = size(inputMovie);
					registeredMovie = zeros([dimsMovie(1) dimsMovie(2) dimsMovie(3)]);
					reverseStr = '';
					refFrame = squeeze(inputMovie(:,:,1));
					nFrames = size(inputMovie,3);
					for frame=1:nFrames
					    distorted = squeeze(inputMovie(:,:,frame));
					    registeredMovie(:,:,frame) = imregister(distorted,refFrame,'rigid',optimizer,metric);
					    reverseStr = cmdWaitbar(frame,nFrames,reverseStr,'inputStr','registering movie','displayEvery',10);
					end
				else
					% % for reasons of memory, this isn't put into a separate function
					% subsetSize = 1000;
					% numSubsets = ceil(length(inputMovie)/subsetSize)+1;
					% subsetList = round(linspace(1,length(inputMovie),numSubsets));
					% refFrame = squeeze(inputMovi{options.refFrameNo});
					% for thisSet=1:(length(subsetList)-1)
					% 	display([num2str(subsetList(thisSet)) ' ' num2str(subsetList(thisSet+1)) ' ' num2str(subsetList(thisSet+1)/subsetList(end))])
					% 	movieSubset = subsetList(thisSet):subsetList(thisSet+1);
					% 	movieDataTemp(movieSubset) = inputMovie(movieSubset);
					% 	% loop over and register each frame
					% 	% parfor_progress(length(movieSubset));
					% 	parfor i=movieSubset
					% 		distorted = squeeze(movieDataTemp{frame});
					% 		movieDataTemp{i} = imregister(distorted,refFrame,'rigid',optimizer,metric);
					% 			    reverseStr = cmdWaitbar(frame,nFrames,reverseStr,'inputStr','registering movie','displayEvery',10);
					% 	end
					% 	inputMovie(movieSubset)=movieDataTemp(movieSubset);
					% 	clear movieDataTemp;
					% end

					% % ========================
					% display('converting cell array back to matrix')
					% %Convert cell array back to 3D matrix
					% inputMovie = cat(3,inputMovie{:});
					% inputMovie = single(inputMovie);

					% openCloseMatlabPool(options);
				end
			case 'dftregistration'
				dimsMovie = size(inputMovie);
				registeredMovie = zeros([dimsMovie(1) dimsMovie(2) dimsMovie(3)]);
				reverseStr = '';
				refFrame = squeeze(inputMovie(:,:,1));
				nFrames = size(inputMovie,3);
				for frame=1:nFrames
				    currentFrame = squeeze(inputMovie(:,:,frame));
				    reverseStr = cmdWaitbar(frame,nFrames,reverseStr,'inputStr','registering movie','displayEvery',10);
					[output currentFrameFFtReg] = dftregistration(fft2(refFrame),fft2(currentFrame),100);
					registeredMovie(:,:,frame) = abs(ifft2(currentFrameFFtReg));
				end
			otherwise
				body
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

function cropCoords = getCropSelection(thisFrame)
	% get a crop of the input region
	figure(9);close(9);figure(9);
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
	figure(9);subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;

function [movieData] = convertMatrixToCell(inputMovie)
	%Get dimension information about 3D movie matrix
	[inputMovieX inputMovieY inputMovieZ] = size(inputMovie);
	reshapeValue = size(inputMovie);
	%Convert array to cell array, allows slicing (not contiguous memory block)
	movieData = squeeze(mat2cell(inputMovie,inputMovieX,inputMovieY,ones(1,inputMovieZ)));

function openCloseMatlabPool(options)
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
		matlabpool('open',maxCores);
	end

	% ========================
	%Close the workers
	if matlabpool('size')&options.closeMatlabPool
		matlabpool close
	end