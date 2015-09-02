function eventsAroundInputTrain(signalMatrix,inputTrain,inputRoi)
	% SEE alignSignal() function, this is obsolete - 2013.11.18 [20:06:40]
	% biafra ahanonu
	% started: 2013.11.04
	% Sums all events in signalMatrix (MxN) that are within inputRoi (1xN) of points in inputTrain(1xN)
	% inputs
		% signalMatrix - MxN matrix of arbitrary signals
		% inputTrain - 1xN input that must contain points within 1:N of signalMatrix, e.g. [2 200 500]
		% inputRoi - 1xN that gives the +/- region to look, e.g. [-30:30]
	% changelog


	[testpeaks] = identifySpikes(thisTrace);
	spikeROI = [-40:40];
	extractMatrix = bsxfun(@plus,testpeaks',spikeROI);
	extractMatrix(extractMatrix<=0)=1;
	extractMatrix(extractMatrix>=size(IcaTraces,2))=size(IcaTraces,2);
	% extractMatrix
	spikeCenterTrace = reshape(IcaTraces(i,extractMatrix),size(extractMatrix));