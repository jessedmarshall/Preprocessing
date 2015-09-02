function [inputMovies] = createMontageMovie(inputMovies,varargin)
	% creates a movie montage from a cell array of movies
	% adapted from signalSorter and other subfunction.
	% biafra ahanonu
	% started: 2015.04.09
	%========================
	options.identifyingText = [];

	options.normalizeMovies = ones([length(inputMovies) 1]);
	% if want the montage to be in a row
	options.singleRowMontage = 0;
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
		nMovies = length(inputMovies);

		for movieNo = 1:nMovies
			if options.normalizeMovies(movieNo)==1
				[inputMovies{movieNo}] = normalizeVector(single(inputMovies{movieNo}),'normRange','zeroToOne');
			end
		end
		if ~isempty(options.identifyingText)
			for movieNo = 1:nMovies
				[inputMovies{movieNo}] = addText(inputMovies{movieNo},options.identifyingText{movieNo});
			end
		end
		for movieNo = 1:nMovies
			maxVal = nanmax(inputMovies{movieNo}(:));
			inputMovies{movieNo} = padarray(inputMovies{movieNo},[3 3],maxVal,'both');
		end

		if options.singleRowMontage==0
			[xPlot yPlot] = getSubplotDimensions(nMovies);
		else
			xPlot = 1;
			yPlot = nMovies;
		end
		% movieLengths = cellfun(@(x){size(x,3)},inputMovies);
		% maxMovieLength = max(movieLengths{:});
		inputMovieNo = 1;
		for xNo = 1:xPlot
			for yNo = 1:yPlot
				if inputMovieNo>length(inputMovies)
					[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},NaN(size(inputMovies{1})),'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',0);
				elseif yNo==1
					[behaviorMovie{xNo}] = inputMovies{inputMovieNo};
				else
					[behaviorMovie{xNo}] = createSideBySide(behaviorMovie{xNo},inputMovies{inputMovieNo},'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',0);
				end
				size(behaviorMovie{xNo})
				inputMovieNo = inputMovieNo+1;
			end
		end
		display(['size behavior: ' num2str(size(behaviorMovie{1}))])
		behaviorMovie{1} = permute(behaviorMovie{1},[2 1 3]);
		display(['size behavior: ' num2str(size(behaviorMovie{1}))])
		display(repmat('-',1,7))
		for concatNo = 2:length(behaviorMovie)
			[behaviorMovie{1}] = createSideBySide(behaviorMovie{1},permute(behaviorMovie{concatNo},[2 1 3]),'pxToCrop',[],'makeTimeEqualUsingNans',1,'normalizeMovies',0);
			behaviorMovie{concatNo} = {};
			size(behaviorMovie{1});
		end
		inputMovies = behaviorMovie{1};
		% behaviorMovie = cat(behaviorMovie{:},3)
		% do something
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

end
function [movieTmp] = addText(movieTmp,inputText)
	nFrames = size(movieTmp,3);
	maxVal = nanmax(movieTmp(:));
	minVal = nanmin(movieTmp(:));
	reverseStr = '';
	for frameNo = 1:nFrames
		movieTmp(:,:,frameNo) = squeeze(nanmean(...
			insertText(movieTmp(:,:,frameNo),[0 0],inputText,...
			'BoxColor',[maxVal maxVal maxVal],...
			'TextColor',[minVal minVal minVal],...
			'AnchorPoint','LeftTop',...
			'BoxOpacity',1)...
		,3));
		reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','adding text to movie','waitbarOn',1,'displayEvery',10);
	end
	% maxVal = nanmax(movieTmp(:))
	% movieTmp(movieTmp==maxVal) = 1;
	% 'BoxColor','white'
end