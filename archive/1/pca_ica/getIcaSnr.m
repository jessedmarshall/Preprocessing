function [IcaSnr IcaMse] = getIcaSnr(IcaTraces)
	% biafra ahanonu
	% started: 2013.11.04 [11:54:09]
	% obtains an approximate SNR for an input signal

	for i=1:size(IcaTraces,1)
		X=IcaTraces(i,:);
		Xapp=zeros(1,length(X));
		[testpeaks] = identifySpikes(X);
		Xapp(testpeaks)=X(testpeaks);
		[psnr,mse,maxerr,L2rat] = measerr(X,Xapp);
		IcaSnr(i)=psnr;
		IcaMse(i)=mse;
	end