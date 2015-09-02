function [eventTimes, peakTimes, eventAmps, eventBin, cellTraceSigmas] = detectEvents(cellTraces, varargin)

% Written by Lacey Kitch in 2013
% Based on code written by Laurie Burns in 2011

% cellTraces is nCells x nFrames
% numSigmasThresh is the number of std devs above baseline we require
% calcSigma is a toggle, if 1, we fit the std of each trace
% noiseSigma is the noise std dev of the movie, we use this if calcSigma=0

numSigmasThresh=3;
calcSigma=0;
noiseSigma=0.005;
doSubMedian=0;
medFiltSize=200;
doMovAvg=0;
movAvgFiltSize=5;
movAvgReqSize=8;
reportMidpoint=0;
minTimeBtEvents=3;
offsetFrames=0;
displayPeaks=0;

if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'numSigmasThresh')
        numSigmasThresh=options.numSigmasThresh;
    end
    if isfield(options, 'calcSigma')
        calcSigma=options.calcSigma;
    end
    if isfield(options, 'noiseSigma')
        noiseSigma=options.noiseSigma;
    end
    if isfield(options, 'doSubMedian')
        doSubMedian=options.doSubMedian;
    end
    if isfield(options, 'medFiltSize')
        medFiltSize=options.medFiltSize;
    end
    if isfield(options, 'doMovAvg')
        doMovAvg=options.doMovAvg;
    end
    if isfield(options, 'movAvgFiltSize')
        movAvgFiltSize=options.movAvgFiltSize;
    end
    if isfield(options, 'movAvgReqSize')
        movAvgReqSize=options.movAvgReqSize;
    end
    if isfield(options, 'reportMidpoint')
        reportMidpoint=options.reportMidpoint;
    end
    if isfield(options, 'minTimeBtEvents')
        minTimeBtEvents=options.minTimeBtEvents;
    end
    if isfield(options, 'offsetFrames')
        offsetFrames=options.offsetFrames;
    end
    if isfield(options, 'displayPeaks')
        displayPeaks=options.displayPeaks;
    end
end
    

nCells = size(cellTraces,1);
cellTraceSigmas = zeros(nCells,1);

% find trace std dev, or fit it
if calcSigma
    
    fInc=0.0005;
    fVals=(-0.05:fInc:0.05)';

    
    % Get SD by fitting gaussian to the histogrammed data (because of heavy pos
    % tail from bursting)
    for cellnum = 1 : nCells    
        %xdata = linspace(-0.3,0.3,1000)';         %%%% might want to take a look at these values
        if doSubMedian
            ydata = hist(cellTraces(cellnum,:) - ...
                ordfilt2(cellTraces(cellnum,:)',ordFiltOrder,ones(ordFiltDomain,1),'symmetric')',fVals)';
        else
            ydata=hist(cellTraces(cellnum,:)-mean(cellTraces(cellnum,:)), fVals)'; 
        end

        options = fitoptions('method','nonlinearleastsquares',...
            'startpoint',[100 0 0.005]);
        
        
        try
            fitres = fit(fVals(2:end-1),ydata(2:end-1),'gauss1',options);
            cellTraceSigmas(cellnum,1) = (fitres.c1/sqrt(2));
        catch %#ok<CTCH>
            disp('fit failed...')
            cellTraceSigmas(cellnum,1) = std(cellTraces(cellnum,:));
        end
    end
    % clear cellTraces
    %clear options fitres xdata ydata cellnum plotcount plottingOn
else
    cellTraceSigmas=noiseSigma*ones(nCells,1);
end


% Run the peak finding
eventTimes = cell(nCells,1);
peakTimes = cell(nCells,1);
offsetpeaks = cell(nCells,1);
riseTimes = cell(nCells,1);
thresh = zeros(nCells,1);


% get the traces shifted by the filtered trace
if doSubMedian
    paddedCellTraces=padarray(cellTraces, [0 ceil(medFiltSize/2)]);
    medSubTraces=paddedCellTraces-medfilt1(paddedCellTraces',medFiltSize)';
    medSubTraces(:,1:ceil(medFiltSize/2))=[];
    medSubTraces(:,end-ceil(medFiltSize/2)+1:end)=[];
else
    medSubTraces=cellTraces;
end


for c=1:size(cellTraces,1)
    
    offsetpeaks{c} = zeros(1,0);
    % set the threshold to a multiple of the SD of the trace for that cell
    thresh(c) = numSigmasThresh*cellTraceSigmas(c);

    if doMovAvg
        inputsignal = filtfilt(ones(1,movAvgFiltSize)/movAvgFiltSize,1,medSubTraces(c,:));
    else
        inputsignal=medSubTraces(c,:);
    end

    % find peaks that satisfy the minimum height, the minimum number of
    % frames between peaks, and the required moving average size above
    % thresh
    if max(inputsignal)>=thresh(c)
        [~,testpeaks] = findpeaks(inputsignal,'minpeakheight',thresh(c));
        [~,testpeaks2] = findpeaks(inputsignal,'minpeakdistance',minTimeBtEvents);
        testpeaks = intersect(testpeaks,testpeaks2);
        clear testpeaks2
        testpeaks = intersect(testpeaks,find(filtfilt(ones(1,movAvgReqSize)/movAvgReqSize,1,...
            medSubTraces(c,:))>thresh(c)));
    else
        testpeaks=[];
    end

    % if there are none, move on to next cell
    if isempty(testpeaks)
        eventTimes{c} = zeros(1,0);
        riseTimes{c} = zeros(1,0);
        offsetpeaks{c} = zeros(1,0);
        continue
    end
    
    % find the trough, and thus the rise time and rise amplitude
    [theseRiseTimes,theseRiseHeights] = findRecentTroughs(inputsignal,inputsignal,testpeaks);
    okpeaks = theseRiseHeights > thresh(c); % get the peaks with increase greater than thresh

    peakTimes{c} = testpeaks(okpeaks);
    if reportMidpoint
        eventTimes{c} = round(1/2*(testpeaks(okpeaks) + theseRiseTimes(okpeaks)));
        eventTimes{c}(eventTimes{c}<1)=1;
    else
        eventTimes{c} = testpeaks(okpeaks);
    end
    riseTimes{c} = theseRiseHeights(okpeaks);

end

% what is offsetpeaks? do we need it?

% what check is this doing?
for cellNum=1:size(cellTraces,1)
    thesePeaks=offsetpeaks{cellNum};
    theseRises=riseTimes{cellNum};
    thesePeaks=thesePeaks-offsetFrames;
    riseTimes{cellNum}=theseRises(thesePeaks>0);
    offsetpeaks{cellNum}=thesePeaks(thesePeaks>0);
end
eventAmps=offsetpeaks;

if displayPeaks
    figure;
    for cInd=1:size(cellTraces,1)
        plot(cellTraces(cInd,:)); hold on; plot(eventTimes{cInd}, cellTraces(cInd,eventTimes{cInd}), 'r.')
        xlim([0 size(cellTraces,2)])
        pause(1)
        hold off
    end
end

eventBin=zeros(size(cellTraces));
for cInd=1:size(cellTraces,1)
    eventBin(cInd,eventTimes{cInd})=1;
end