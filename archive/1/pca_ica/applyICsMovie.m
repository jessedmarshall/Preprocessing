function applyICsMovie(inputDir, inputID, fileRegExp, PCAsuffix, varargin)
    % biafra ahanonu
    % created: 2013.10.11
    % apply ICs to a movie

    %For each day, load the downsampled DFOF movie
    files = getFileList(inputDir, fileRegExp);
    % load movies, automatically concatenate
    numMovies = length(files);
    for tifMovie=1:numMovies
        display(['loading ' num2str(tifMovie) '/' num2str(numMovies) ': ' files{tifMovie}])
        tmpDFOF = load_tif_movie(files{tifMovie},1);
        if(tifMovie==1)
            DFOF(:,:,:) = tmpDFOF.Movie;
        else
            DFOF(:,:,end+1:end+length(tmpDFOF.Movie)) = tmpDFOF.Movie;
        end
    end

    filesToLoad={};
    filesToLoad{1} = [inputDir filesep inputID '_ICfilters' PCAsuffix '.mat'];
    for i=1:length(filesToLoad)
        display(['loading: ' filesToLoad{i}]);
        load(filesToLoad{i})
    end

    %Check maximum number of cores avaliable
    %maxCores = feature('numCores');
    %Open works = max core #, probably should do maxCores-1 for
        %stability...
    %matlabpool('open',maxCores);

    % get number of ICs and frames
    nICs = length(IC_filter{1,1}.Image);
    nFrames = size(DFOF,3);
    % pre-allocate traces
    IcaTraces = zeros(nICs,nFrames);
    ICfilters = IC_filter{1,1}.Image;

    waitbarHandle = waitbar(0, 'getting traces...');
    figure(42);
    colormap gray;
    % loop over and matrix multiple to get trace for each time-point
    for ICtoCheck = 1:nICs
        if(mod(ICtoCheck,3)==0)
            waitbar(ICtoCheck/nICs,waitbarHandle)
        end
        thisFilt = thresholdICs(ICfilters{1,ICtoCheck});

        % use bsxfun to matrix multiple 2D filt to 3D movie
        tmpTrace = sum(sum(bsxfun(@times,thisFilt,DFOF),1),2);
        IcaTraces(ICtoCheck,:) = tmpTrace(:);

%         for thisFrame=1:nFrames
%             %thisFiltThresholded = thresholdICs(thisFilt);
%             IcaTraces(ICtoCheck,thisFrame) = sum(sum(DFOF(:,:,thisFrame).*thisFilt))';
%             %thresholdedTrace(i) = sum(sum(tmpDFOF.Movie(:,:,i).*thisFiltThresholded));
%         end
%         subplot(2,1,1);
%         imagesc(thisFilt);
%         subplot(2,1,2);
%         plot(IcaTraces(ICtoCheck,:));
%         drawnow;
    end
    close(waitbarHandle);

    % save IC traces
    savestring = [inputDir filesep inputID '_ICtraces_applied' '.mat'];
    display(['saving: ' savestring])
    save(savestring,'IcaTraces');