function compareToICAresultsEdit(imgs, icImgs, icTraces, allCellImages, allCellParams,...
    allCellTraces, varargin)
% compared EM and PCAICA results
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
% changelog
    % 2014.01.17 [14:57:30] - biafra - altered so it doesn't plot contours, speeds up program

playbackFramerate=20;
playTwoMoviesWithContours=0;
% don't plot the cell contours
plotContours=0;
haveEvents=0;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'playbackFramerate')
        playbackFramerate=options.playbackFramerate;
    end
    if isfield(options, 'playTwoMoviesWithContours')
        playTwoMoviesWithContours=options.playTwoMoviesWithContours;
    end
    if isfield(options, 'plotContours')
        plotContours=options.plotContours;
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



% getICcentroids picks ICs that have a large enough local area of a certain
% value around the maximum value (check code for criterion)
[icCentroids, goodICinds, icTraces] = getICcentroids(icImgs, icTraces);
icImgs=icImgs(:,:,goodICinds);

redunCellImgs=find(sum(allCellTraces,2)==0);
allCellImages(:,:,redunCellImgs)=[];
allCellParams(redunCellImgs,:)=[];
allCellTraces(redunCellImgs,:)=[];

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

h=figure(12);
exitVar = 0;
fr = 1;
incrementCounter = 1;
suptitle(['e:exit    p:pause    r:rewind    f:forward | +:speed    -:slow    ]:+1    [:-1', 10, 10]);
% for fr=1:nFrames
while exitVar==0
    figure(h)
    incrementCounter = 1;
    keyIn = get(h, 'CurrentCharacter');
    set(h, 'CurrentCharacter', 'f')
    if ~strcmp(get(h, 'CurrentCharacter'), 'q')

        if playTwoMoviesWithContours

            subplot(121)
            hold off
            imagesc(imgs(:,:,fr))
            set(gca, 'CLim', [0.98, 1.15])
            hold on
            if plotContours==1
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
            else
                plot(icCentroids(:,1), icCentroids(:,2), 'k.', 'Markersize', 20)
                % plot(icContours{:}(:,1), icContours{:}(:,2), 'k');
            end
            title(['ICA | frame: ' num2str(fr) '/' num2str(nFrames) ' | fps: ' num2str(playbackFramerate*incrementCounter) ' skip:' num2str(playbackFramerate*incrementCounter), ' frames'])

            subplot(122)
            hold off
            imagesc(imgs(:,:,fr))
            set(gca, 'CLim', [0.98, 1.15])
            hold on
            if plotContours==1
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
            else
                plot(allCellParams(:,1), allCellParams(:,2), 'k.', 'Markersize', 20)
                % plot(emContours{:}(:,1), emContours{:}(:,2), 'k');
                % suptitle('Press q to quit | green = above threshold')
            end
            title('EM')
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
        pausetime=1/playbackFramerate;
        pause(pausetime)
    else
        break
    end
    if strcmp(keyIn,'e')%
        % if keydown==1
        % display('adas')
        % if user clicks f- finish
        exitVar = 1;
        set(h,'currentch','3');drawnow;
        % set(gcf,'CurrentCharacter','');
        break;
    elseif strcmp(keyIn,'1')%skip
        if playbackFramerate==1
            playbackFramerate = 60;
        else
            playbackFramerate = 1;
        end
    elseif strcmp(keyIn,'s')%skip
        fr = fr+round(playbackFramerate);
        set(h,'currentch','3');drawnow;
        keyIn = get(h,'CurrentCharacter');
    elseif strcmp(keyIn,'p')%pause
        pause
    elseif strcmp(keyIn,']')%pause
        pause
        incrementCounter = 1;
    elseif strcmp(keyIn,'[')%pause
        pause
        incrementCounter = -1;
    elseif strcmp(keyIn,'r')%rewind
        incrementCounter = -1;
    elseif strcmp(keyIn,'f')%forward
        incrementCounter = 1;
    elseif strcmp(keyIn,'+')%increase speed
        playbackFramerate = playbackFramerate*1.3;
        set(h,'currentch','3');drawnow;
        keyIn = get(h,'CurrentCharacter');
        % dirChange = dirChange*2;
    elseif strcmp(keyIn,'-')%decrease speed
        playbackFramerate = playbackFramerate/1.3;
        set(h,'currentch','3');drawnow;
        keyIn = get(h,'CurrentCharacter');
        % dirChange = dirChange/2;
    end
    fr = fr + incrementCounter;
end

