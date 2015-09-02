function [peakOutputStat] = computePeakStatistics(inputSignals,varargin)
	% get slope ratio, the average trace from detected peaks, and other peak-related statistics
	% biafra ahanonu
	% started: 2013.12.09
	% inputs
		% inputSignals = [n m] matrix where n={1....N}
	% outputs
		% slopeRatio
		% traceErr
		% fwhmSignal
		% avgPeakAmplitude
		% spikeCenterTrace
		% pwelchPxx
		% pwelchf
	% changelog
		% 2013.12.24 - changed output so that it is a structure, allows more flexibility when adding new statistics.

	%========================
	%
	options.spikeROI = [-40:40];
	%
	options.slopeFrameWindow = 10;
	%
	options.waitbarOn = 1;
	% determine whether power-spectral density should be calculated
	options.psd = 0;
	% should fwhm analysis be plotted?
	options.fwhmPlot = 0;
	% save time if already computed peaks
	options.testpeaks = [];
	options.testpeaksArray = [];
	% get options
	options = getOptions(options,varargin);
	fn=fieldnames(options);
	for i=1:length(fn)
	    eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	peakOutputStat.fwhmSignal = [];
	% get a list of all indices to pull out
	nSignals = size(inputSignals,1);
	reverseStr = '';
	if isempty(options.testpeaks)
		[testpeaks testpeaksArray] = computeSignalPeaks(inputSignals,'waitbarOn',options.waitbarOn,'makeSummaryPlots',0);
	else
		testpeaks = options.testpeaks;
		testpeaksArray = options.testpeaksArray;
	end
	for i=1:nSignals
		[peakStat] = peakStats(testpeaksArray{i},inputSignals(i,:),spikeROI,slopeFrameWindow,options);

		peakOutputStat.avgSpikeTrace(i,:) = peakStat.avgSpikeTrace;
		peakOutputStat.slopeRatio(i) = peakStat.slopeRatio;
		peakOutputStat.traceErr(i) = peakStat.traceErr;
		peakOutputStat.fwhmSignal = [peakOutputStat.fwhmSignal; peakStat.fwhmTrace(:)];
		peakOutputStat.avgFwhm(i) = nanmean(peakStat.fwhmTrace(:));
        peakOutputStat.fwhmSignalSignals{i} = peakStat.fwhmTrace(:);
		peakOutputStat.avgPeakAmplitude(i) = peakStat.avgPeakAmplitude;
		peakOutputStat.spikeCenterTrace{i} = peakStat.spikeCenterTrace;
		if options.psd==1
			peakOutputStat.pwelchPxx{i} = peakStat.pwelchPxx;
			peakOutputStat.pwelchf{i} = peakStat.pwelchf;
		end

		% reduce waitbar access
		reverseStr = cmdWaitbar(i,nSignals,reverseStr,'inputStr','getting statistics','waitbarOn',options.waitbarOn,'displayEvery',50);
    end

    if options.fwhmPlot~=0
	    fwhmMax = max(peakOutputStat.fwhmSignal);
	    figCount = 1;
	    plotCount = 1;
	    sheight = 10;
	    swidth = 10;
	    for i=1:nSignals
	        figure(143+figCount)
	        subplot(sheight,swidth,plotCount);
	            hist(peakOutputStat.fwhmSignalSignals{i},[0:fwhmMax]);
	                % box off;
	            h = findobj(gca,'Type','patch');
	            set(h,'FaceColor',[0 0 0],'EdgeColor',[0 0 0])
	            set(gca,'xlim',[0 fwhmMax],'ylim',[0 20]);
	            if plotCount~=1
	                set(gca,'XTickLabel','','YTickLabel','');
	            end
	        plotCount = plotCount+1;
	        if (mod(i,sheight*swidth)==0)
	           figCount = figCount+1;
	           plotCount = 1;
	        end
	    end
	end

function [peakStat] = peakStats(testpeaks,inputSignal,spikeROI,slopeFrameWindow,options)
	% finds peaks in the data then extracts information from them
	% [testpeaks dummyVar] = computeSignalPeaks(inputSignal);
	% if peaks exists, do statistics else return NaNs
	if ~isempty(testpeaks)
		% get a list of indices around which to extract spike signals
		extractMatrix = bsxfun(@plus,testpeaks',spikeROI);
		extractMatrix(extractMatrix<=0)=1;
		extractMatrix(extractMatrix>=size(inputSignal,2))=size(inputSignal,2);
		peakStat.spikeCenterTrace = reshape(inputSignal(extractMatrix),size(extractMatrix));
		spikeCenterTrace = peakStat.spikeCenterTrace;

		% get the average trace around a peak
		if size(spikeCenterTrace,1)==1
			peakStat.avgSpikeTrace = spikeCenterTrace;
		else
			peakStat.avgSpikeTrace = nanmean(spikeCenterTrace);
		end

		% get the peak amplitude
		peakStat.avgPeakAmplitude = peakStat.avgSpikeTrace(find(spikeROI==0));
		% slopeRatio = (peakDfof-avgSpikeTrace(find(spikeROI==-slopeFrameWindow)))/(peakDfof-avgSpikeTrace(find(spikeROI==slopeFrameWindow)));

		% get the deviation in the error
		peakStat.traceErr = sum(nanstd(spikeCenterTrace))/sqrt(size(spikeCenterTrace,1));

		% get a ratio metric (normalized between 1 and -1) for the asymmetry in the peaks
		areaPrePeak = abs(sum(peakStat.avgSpikeTrace(find(spikeROI==-slopeFrameWindow):find(spikeROI==0))));
		areaPostPeak = abs(sum(peakStat.avgSpikeTrace(find(spikeROI==0):find(spikeROI==slopeFrameWindow))));
		peakStat.slopeRatio = (areaPostPeak-areaPrePeak)/(areaPostPeak+areaPrePeak);
		% for graphing purposes, remove super large asymmetries
		peakStat.slopeRatio(find(peakStat.slopeRatio>5))=NaN;
		% avgSpikeTraceCut = avgSpikeTrace(find(spikeROI==-slopeFrameWindow):find(spikeROI==slopeFrameWindow));
		% slopeRatio = skewness(avgSpikeTraceCut./max(avgSpikeTraceCut));

		% get fwhm for all peaks
		for i=1:size(spikeCenterTrace,1)
			peakStat.fwhmTrace(i) = fwhm(spikeROI,spikeCenterTrace(i,:));
        end

		if options.psd==1
			% get the power-spectrum
			[peakStat.pwelchPxx peakStat.pwelchf] = pwelch(inputSignal,100,25,512,5);
		end
	else
		peakStat.avgSpikeTrace = nan(1,length(spikeROI));
		peakStat.spikeCenterTrace = nan(1,length(spikeROI));
		peakStat.avgPeakAmplitude = NaN;
		peakStat.slopeRatio = NaN;
		peakStat.fwhmTrace = NaN;
		peakStat.traceErr = NaN;
		if options.psd==1
			peakStat.pwelchPxx = NaN;
			peakStat.pwelchf = NaN;
		end
	end

function plotStatistics()
	% figure(92929)
	% hist(fwhmSignal,[0:nanmax(fwhmSignal)]); box off;
	% xlabel('FWHM (frames)'); ylabel('count');
	% title('full-width half-maximum for detected spikes');
	% h = findobj(gca,'Type','patch');
	% set(h,'FaceColor',[0 0 0],'EdgeColor','w')

% OLD CODE! IGNORE!
	% spikeROI = [-40:40];
	% extractMatrix = bsxfun(@plus,testpeaks',spikeROI);
	% extractMatrix(extractMatrix<=0)=1;
	% extractMatrix(extractMatrix>=size(IcaTraces,2))=size(IcaTraces,2);
	% % extractMatrix
	% spikeCenterTrace = reshape(IcaTraces(i,extractMatrix),size(extractMatrix));
	% avgSpikeTrace = nanmean(spikeCenterTrace);
	% traceErr = nanstd(spikeCenterTrace)/sqrt(size(spikeCenterTrace,1));
	%
	% errorbar(spikeROI, avgSpikeTrace, traceErr);
	% t=1:length(traceErr);
	% fill([spikeROI fliplr(spikeROI)],[avgSpikeTrace+traceErr fliplr(avgSpikeTrace-traceErr)],[4 4 4]/8, 'FaceAlpha', 0.4, 'EdgeColor','none')