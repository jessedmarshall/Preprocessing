function compareToICAresults(imgs, icImgs, icTraces, allCellImages, allCellParams,...
    allCellTraces, varargin)

% inputs
% imgs: the full movie
% icImgs: pixels x pixels x nICs, the ICA result images
% icTraces: nICs x nFrances, the ICA result traces
% allCellImages: cell images output by EM_main
% allCellParams: cell params output by EM_main
% allCellTraces: cell traces output by EM_main
% playbackFramerate: framerate to play movie (hz)
% playTwoMoviesWithContours: toggle. if =1, then plays two side by side
%       movies, left of the data with ICA contours and centroids overlaid,
%       and right of the data with EM contours and centroids overlaid
%   if =0, then plays one copy of the movie, with ICA (.) and EM (+) centroids
%   overlaid
%
%   in both movie versions, the centroids/contours turn to green from black
%   when that cell/IC is active

playbackFramerate=20;
playTwoMoviesWithContours=0;
haveEvents=0;
xlims=1:size(imgs,2);
ylims=1:size(imgs,1);
writeAVI=1;
fName='compareToICAMovie';
if ~isempty(varargin)
    options=varargin{1}
    if isfield(options, 'playbackFramerate')
        playbackFramerate=options.playbackFramerate;
    end
    if isfield(options, 'playTwoMoviesWithContours')
        playTwoMoviesWithContours=options.playTwoMoviesWithContours;
    end
    if isfield(options, 'xlims')
        xlims=options.xlims;
    end
    if isfield(options, 'ylims')
        ylims=options.ylims;
    end
    if isfield(options, 'emEvents')
        if isfield(options, 'icEvents')
            haveEvents=1;
            icEvents=options.icEvents;
            emEvents=options.emEvents;
        else
            warning('Warning: must input both ICA and EM events to use events, not using events in movie');
        end
    elseif isfield(options, 'icaEvents')
            warning('Warning: must input both ICA and EM events to use events, not using events in movie');
    end
end
    
centroidOptions.icSizeThresh=0;
[icCentroids,~,~] = getICcentroids(icImgs, icTraces, centroidOptions);
[~,icCentroids,icTraces,outOfRangeCells] = adjustMovieParamsToSmallerArea(imgs, xlims, ylims, icCentroids, icTraces);
icImgs=icImgs(ylims,xlims,:);
icImgs(:,:,outOfRangeCells)=[];
if haveEvents
    icEvents(outOfRangeCells)=[];
end
size(icImgs)
size(icCentroids)
size(icEvents)

[imgs,allCellParams,allCellTraces,outOfRangeCells] = adjustMovieParamsToSmallerArea(imgs, xlims, ylims, allCellParams, allCellTraces);
allCellImages=allCellImages(ylims,xlims,:);
allCellImages(:,:,outOfRangeCells)=[];

if haveEvents
    emEvents(outOfRangeCells)=[];
end


% 
% redunCellImgs=find(sum(allCellTraces,2)==0);
% allCellImages(:,:,redunCellImgs)=[];
% allCellParams(redunCellImgs,:)=[];
% allCellTraces(redunCellImgs,:)=[];

nFrames=size(imgs,3);
icThreshes=3*std(icTraces,0,2);
emThresh=0.015;

icContours=cell(size(icCentroids,1),1);
for icInd=1:size(icCentroids,1)
    thisICimg=icImgs(:,:,icInd);
    [maxVal, maxPosition]=max(thisICimg(:));
    thisICimg(thisICimg<0.3*maxVal)=0;
    thisICimg(thisICimg>0)=1;
    thisICimg=bwlabel(logical(thisICimg));
    thisICimg(thisICimg~=thisICimg(maxPosition))=0;
    info=regionprops(logical(thisICimg),'ConvexHull');
    icContours{icInd}=info.ConvexHull;
end

emContours=cell(size(allCellParams,1),1);
for cInd=1:size(allCellParams,1)
    thisImg=allCellImages(:,:,cInd);
    thisImg(thisImg<0.7*max(thisImg(:)))=0;
    thisImg(thisImg>0)=1;
    info=regionprops(logical(thisImg),'ConvexHull');
    emContours{cInd}=info.ConvexHull;
end

pausetime=1/playbackFramerate;

if writeAVI
    writerObj = initAVIwriter(fName, playbackFramerate);
end

h=figure(12);
for fr=1:nFrames
    figure(h)
    set(h, 'CurrentCharacter', 'f')
    if ~strcmp(get(h, 'CurrentCharacter'), 'q')
    
        if playTwoMoviesWithContours

            subplot(121)
            hold off
            imagesc(imgs(:,:,fr))
            set(gca, 'CLim', [0.98, 1.15])
            hold on
            for icInd=1:size(icCentroids,1)
                if haveEvents
                    isActiveCell=min(abs(icEvents{icInd}-fr))<4; %#ok<USENS>
                else
                    isActiveCell=icTraces(icInd,fr)>icThreshes(icInd);
                end
                if isActiveCell
                    plot(icCentroids(icInd,1), icCentroids(icInd,2), 'g.', 'Markersize', 20)
                    plot(icContours{icInd}(:,1), icContours{icInd}(:,2), 'g');
                else
                    plot(icCentroids(icInd,1), icCentroids(icInd,2), 'k.', 'Markersize', 20)
                    plot(icContours{icInd}(:,1), icContours{icInd}(:,2), 'k');
                end
            end
            title('ICA')

            subplot(122)
            hold off
            imagesc(imgs(:,:,fr))
            set(gca, 'CLim', [0.98, 1.15])
            hold on
            for cInd=1:size(allCellParams,1)
                if haveEvents
                    isActiveCell=min(abs(emEvents{cInd}-fr))<4;
                else
                    isActiveCell=allCellTraces(cInd,fr)>emThresh;
                end
                if isActiveCell
                    plot(allCellParams(cInd,1), allCellParams(cInd,2), 'g.', 'Markersize', 20)
                    plot(emContours{cInd}(:,1), emContours{cInd}(:,2), 'g');
                else
                    plot(allCellParams(cInd,1), allCellParams(cInd,2), 'k.', 'Markersize', 20)
                    plot(emContours{cInd}(:,1), emContours{cInd}(:,2), 'k');
                end
            end
            title('EM')
            suptitle('Press q to quit | green = has event')
        else
            hold off
            imagesc(imgs(:,:,fr))
            set(gca, 'CLim', [0.98, 1.15])
            hold on
            for icInd=1:size(icCentroids,1)
                if haveEvents
                    isActiveCell=min(abs(icEvents{icInd}-fr))<4; %#ok<USENS>
                else
                    isActiveCell=icTraces(icInd,fr)>icThreshes(icInd);
                end
                if isActiveCell
                    plot(icCentroids(icInd,1), icCentroids(icInd,2), 'g.', 'Markersize', 20)
                else
                    plot(icCentroids(icInd,1), icCentroids(icInd,2), 'k.', 'Markersize', 20)
                end
            end
            for cInd=1:size(allCellParams,1)
                if haveEvents
                    isActiveCell=min(abs(emEvents{cInd}-fr))<4;
                else
                    isActiveCell=allCellTraces(cInd,fr)>emThresh;
                end
                if isActiveCell
                    plot(allCellParams(cInd,1), allCellParams(cInd,2), 'g+', 'Markersize', 20)
                else
                    plot(allCellParams(cInd,1), allCellParams(cInd,2), 'k+', 'Markersize', 20)
                end
            end
            if haveEvents
                title('Press q to quit | EM = +, ICA = . | green = has event') 
            else
                title('Press q to quit | EM = +, ICA = . | green = above threshold')
            end
        end
        
        if writeAVI
            thisFrame=getframe(gcf);
            writeVideo(writerObj,thisFrame);
        else
            pause(pausetime)
        end
    else
        break
    end
end
if writeAVI
    close(writerObj)
end
        