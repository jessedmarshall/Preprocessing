function [inputSnr inputMse] = computeSignalSnr(inputSignals,varargin)
	% obtains an approximate SNR for an input signal
	% biafra ahanonu
	% started: 2013.11.04 [11:54:09]
	% inputs
		%
	% outputs
		%
	% options
		%
	% changelog
		% 2013.12.08 now uses RMS to calculate the SNR after removing the signal to get an estimated noise trace.

	%========================
	% frames around which to remove the signal for noise estimation
	options.timeSeq = [-10:10];
	options.waitbarOn = 1;
	% get options
	options = getOptions(options,varargin);
	%========================

	% to later calculate the signal idx
	outerFun = @(x,y) x+y;
	nSignals = size(inputSignals,1);
	reverseStr = '';
	[testpeaks testpeaksArray] = computeSignalPeaks(inputSignals,'makeSummaryPlots',0,'waitbarOn',0);
	for i=1:nSignals
		x=inputSignals(i,:);
		testpeaks = testpeaksArray{i};
		% Xapp=zeros(1,length(X));
		if ~isempty(testpeaks)
			signalIdx = bsxfun(outerFun,options.timeSeq',testpeaks);
			signalIdx = unique(signalIdx(:));
			if ~isempty(signalIdx)
				signalIdx(find(signalIdx>length(x)))=[];
				signalIdx(find(signalIdx<=0))=[];
				% remove signal then add back in noise based on signal statistics
				y = x;
				y(signalIdx) = NaN;
				y(signalIdx) = normrnd(nanmean(y),nanstd(y),[1 length(signalIdx)]);
				% remove noise from signal vector
				xtmp = zeros([1 length(x)]);
				xtmp(signalIdx) = 1;
				% x(~logical(xtmp)) = NaN;
				% compute SNR
				x_snr = (rootMeanSquare(x)/rootMeanSquare(y))^2;
				% x_snr = nanmean(x)/std(y);
				xRms = rootMeanSquare(x);
			else
				x_snr = NaN;
			end
		else
			x_snr = NaN;
			xRms = NaN;
		end
		if x_snr>4
			x_snr=NaN;
		end
		inputSnr(i)=x_snr;
		inputMse(i)=xRms;
		% Xapp(testpeaks)=X(testpeaks);
		% [psnr,mse,maxerr,L2rat] = measerr(X,Xapp);
		% IcaSnr(i)=psnr;
		% IcaMse(i)=mse;

		% reduce waitbar access
		reverseStr = cmdWaitbar(i,nSignals,reverseStr,'inputStr','obtaining SNR','waitbarOn',options.waitbarOn,'displayEvery',50);
	end

function [RMS] = rootMeanSquare(x)
	RMS = sqrt(nanmean(x.^2));