function simResult=makeResultsMovie(imgs, estParams, estCellTraces, varargin)

% imgs: real data. nypix x nxpix x nFrames
% estParams: parameters estimated by algorithm. nCells x 5 (or 6)
% estCellTraces: estimated fluorescence traces. nCells x nFrames

% options:
% options.writeAVI: Toggle. if on, makes an AVI file with filename specified by
%       varargin{3}
% options.markCentroids: Toggle. if on, marks the centroids of the estimated cells.
% options.plotTraces: Toggle. if on, plots the traces of all cells below movies.
% options.lims: limits for a subregion of movie, [ymin ymax xmin xmax]
%       ie [20 50 40 60] restricts movie to pixels imgs(20:50,40:60,:)
% options.aviName: filename (string) for writing avi file
% options.framerate: framerate for writing AVI file
% options.compareTraces: actual/ROI cell traces, same size as estCellTraces
% options.skipSim: exclude the simulation movie


% extract optional parameters
haveGroundTruth=0;
imgsYLims=1:size(imgs,1);
imgsXLims=1:size(imgs,2);
framerate=19.3;
writeAVI=0;
plotTraces=0;
markCentroids=0;
vlm=0;
grayscale=0;
haveSimResult=0;
plotCvxHulls=0;
skipSim=0;
specificCvxHull=[];
if ~isempty(varargin)
    if length(varargin)>1
        warning('Using incorrect structure for options, skipping all options')
    else
        options=varargin{1};
    
        % limits for data display
        if isfield(options, 'lims')
            lims=options.lims;
            imgsYLims=lims(1):lims(2);
            imgsXLims=lims(3):lims(4);
        end

        % name for avi file
        if isfield(options, 'aviName')
            fName=options.aviName;
        end

        % framerate for avi file
        if isfield(options, 'framerate')
            framerate=options.framerate;
        end

        % actual traces / roi traces / ground truth
        if isfield(options, 'compareTraces')
            realCellTraces=options.compareTraces;
            haveGroundTruth=1;
        end
        
        if isfield(options, 'writeAVI')
            writeAVI=options.writeAVI;
        end
        
        if isfield(options, 'markCentroids')
            markCentroids=options.markCentroids;
        end
        
        if isfield(options, 'plotTraces')
            plotTraces=options.plotTraces;
        end
        
        if isfield(options, 'vlm')
            vlm=options.vlm;
        end
        
        if isfield(options, 'grayscale')
            grayscale=options.grayscale;
        end
        if isfield(options, 'simResult')
            simResult=options.simResult;
            haveSimResult=1;
        end
        if isfield(options, 'cvxHulls')
            plotCvxHulls=1;
            cvxHulls=options.cvxHulls;
        end
        if isfield(options, 'specificCvxHull')
            specificCvxHull=options.specificCvxHull;
        end
        if isfield(options, 'skipSim')
            skipSim=options.skipSim;
        end
    end
end
[imgs, estParams, estCellTraces, outOfRangeCells] = adjustMovieParamsToSmallerArea(imgs, imgsXLims, imgsYLims, estParams, estCellTraces);
imgSize=size(imgs(:,:,1));
nCells=size(estParams,1);
nFrames=size(imgs,3);
if haveGroundTruth
    realCellTraces(outOfRangeCells,:)=[];
end

if ~haveSimResult && ~skipSim
    % create a simulated movie from the estimated parameters
    disp('Recreating simulated data from algorithm estimate...')

    cellImgs=calcCellImgs(estParams, imgSize);
    cellImgs=reshape(cellImgs, imgSize(1)*imgSize(2), nCells);
    simResult=zeros([imgSize(1)*imgSize(2), nFrames], 'single');
    for fr=1:nFrames
        simResult(:,fr)=1+cellImgs*estCellTraces(:,fr);
        if mod(fr, 100)==0
            disp(['Frame ' num2str(fr) ' of ' num2str(nFrames)])
        end
    end
    simResult=reshape(simResult, size(imgs));
    if vlm
        bg=median(imgs,3);
        simResult=simResult+repmat(bg,[1 1 size(imgs,3)]);
        imgs=imgs+1;
    end
    disp('Simulation calculation done.')
else
    nCells=size(estParams,1);
    if vlm
        imgs=imgs+1;
    end
    if length(imgsYLims)~=size(imgs,1) || length(imgsXLims)~=size(imgs,2)
        imgs=imgs(imgsYLims,imgsXLims,:);
        if ~skipSim
            simResult=simResult(imgsYLims,imgsXLims,:);
        end
    end
end
traceLength=size(estCellTraces,2);

if plotCvxHulls
    for cInd=1:length(cvxHulls)
        cvxHulls{cInd}(:,1)=cvxHulls{cInd}(:,1)-min(imgsXLims)+1;
        cvxHulls{cInd}(:,2)=cvxHulls{cInd}(:,2)-min(imgsYLims)+1;
    end
    if ~isempty(specificCvxHull)
        specificCvxHull(:,1)=specificCvxHull(:,1)-min(imgsXLims)+1;
        specificCvxHull(:,2)=specificCvxHull(:,2)-min(imgsYLims)+1;
    end
end

% colors for plotting centroids and traces
colors=[1 1 1;
        1 0 0;
        0 1 0;
        0 0 0;
        0 1 1;
        1 0 1;
        1 1 0];
nColors=size(colors,1);

% make movie
h=figure(20);
set(gcf, 'Color', 'White')
maxVals=max(imgs,[],3);
minVals=min(imgs,[],3);
CLimBottom=prctile(minVals(:),50);
CLimTop=prctile(maxVals(:),90);

% set up AVI writer
if writeAVI
    writerObj = initAVIwriter(fName, framerate);
end

if plotTraces
    ylims=[-0.01, max(estCellTraces(:))];
end

if ~skipSim
    % loop through frames and create movie
    for fr=1:size(imgs,3)

        figure(h)

        if ~strcmp(get(h, 'CurrentCharacter'), 'q')

            if plotTraces
                subplot(3,2,[1,3])
            else
                subplot(1,2,1)
            end
            imagesc(imgs(:,:,fr))
            if grayscale
                colormap(gray)
            end
            set(gca, 'CLim', [CLimBottom, CLimTop])
            set(gca, 'XTick', [], 'YTick', [])
            if markCentroids
                hold all
                for cInd=1:nCells
                    plot(estParams(cInd,1),estParams(cInd,2),'.',...
                        'Color', colors(mod(cInd,nColors)+1,:))
                end
                hold off
            end
            if plotCvxHulls
                hold on
                for cInd=1:length(cvxHulls)
                    plot(cvxHulls{cInd}(:,1),cvxHulls{cInd}(:,2),...
                        'Color', [1 1 1])
                end
                if ~isempty(specificCvxHull)
                    plot(specificCvxHull(:,1),specificCvxHull{cInd}(:,2),'m', 'Linewidth', 1.5)
                end
                hold off
            end


            if plotTraces
                subplot(3,2,[1,3]+1)
            else
                subplot(1,2,2)
            end
            imagesc(simResult(:,:,fr))
            set(gca, 'CLim', [CLimBottom, CLimTop])
            if grayscale
                colormap(gray)
            end
            set(gca, 'XTick', [], 'YTick', [])
            if markCentroids
                hold on
                for cInd=1:nCells
                    plot(estParams(cInd,1),estParams(cInd,2),'.',...
                        'Color', colors(mod(cInd,nColors)+1,:))
                end
                hold off
            end

            if plotTraces
                subplot(3,2,5:6)
                for cInd=1:nCells
                    if haveGroundTruth
                        plot((1/19.3)*(1:traceLength),realCellTraces(cInd,:),'--',...
                            'Color',colors(mod(cInd,nColors)+1,:))
                        hold on
                    end 
                    plot((1/19.3)*(1:traceLength),estCellTraces(cInd,:),...
                        'Color', colors(mod(cInd,nColors)+1,:))
                    hold on
                    plot(fr/19.3,estCellTraces(cInd,fr),'.',...
                        'Color', colors(mod(cInd,nColors)+1,:),'Markersize',20)
                end
                set(gca, 'Fontsize', 16)
                xlabel('Time (s)')
                ylabel('\Delta F / F')
                xlim([0, traceLength/19.3])
                ylim(ylims)
                hold off
            end

            if writeAVI
                thisFrame=getframe(gcf);
                writeVideo(writerObj,thisFrame);
            else
                pause(1/framerate)
            end
        end
    end
else
    
        % loop through frames and create movie
    for fr=1:size(imgs,3)

        figure(h)

        if ~strcmp(get(h, 'CurrentCharacter'), 'q')

            if plotTraces
                subplot(4,4,1:12)
            end
            imagesc(imgs(:,:,fr))
            if grayscale
                colormap(gray)
            end
            set(gca, 'CLim', [CLimBottom, CLimTop])
            set(gca, 'XTick', [], 'YTick', [])
            if markCentroids
                hold all
                for cInd=1:nCells
                    plot(estParams(cInd,1),estParams(cInd,2),'.',...
                        'Color', colors(mod(cInd,nColors)+1,:))
                end
                hold off
            end
            if plotCvxHulls
                hold on
                for cInd=1:length(cvxHulls)
                    plot(cvxHulls{cInd}(:,1),cvxHulls{cInd}(:,2),...
                        'Color', [1 1 1])
                end
                if ~isempty(specificCvxHull)
                    plot(specificCvxHull(:,1),specificCvxHull(:,2),'m', 'Linewidth', 1.5)
                end
                hold off
            end

            if plotTraces
                subplot(4,4,13:16)
                for cInd=1:nCells
                    if haveGroundTruth
                        plot((1/19.3)*(1:traceLength),realCellTraces(cInd,:),'--',...
                            'Color',colors(mod(cInd,nColors)+1,:))
                        hold on
                    end 
                    plot((1/19.3)*(1:traceLength),estCellTraces(cInd,:),...
                        'Color', colors(mod(cInd,nColors)+1,:))
                    hold on
                    plot(fr/19.3,estCellTraces(cInd,fr),'.',...
                        'Color', colors(mod(cInd,nColors)+1,:),'Markersize',20)
                end
                set(gca, 'Fontsize', 16)
                xlabel('Time (s)')
                ylabel('\Delta F / F')
                xlim([0, traceLength/19.3])
                ylim(ylims)
                hold off
            end

            if writeAVI
                thisFrame=getframe(gcf);
                writeVideo(writerObj,thisFrame);
            else
                pause(1/framerate)
            end
        end
    end
    
end
if writeAVI
    close(writerObj)
end

% from file makeResultsMovie on 12/16/13 at 10:18am