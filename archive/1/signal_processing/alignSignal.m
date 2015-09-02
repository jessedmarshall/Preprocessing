function [alignedSignal] = alignSignal(responseSignal, alignmentSignal,timeSeq,varargin)
	% biafra ahanonu
	% updated: 2013.11.13 [23:47:34]
	% aligns values in responseSignal to binary points in alignmentSignal (e.g. 1=align to this time-point)
	% inputs
		% responseSignal = MxN matrix of M signals over N points
		% alignmentSignal = a 1xN vector of 0s and 1s, where 1s will be alignment points
		% timeSeq = 1xN sequence giving time around alignments points to process, e.g. -2:2.
	% outputs
		% alignedSignal = a matrix of size 1xlength(timeSeq) if sum all signals or Mxlength(timeSeq) if keep the sums for each signal separate
	% TODO
		% got around looping over alignment points, but there must be a way to skip looping over the input signals...
		% parfor this...
	% changelog
		% 2013.11.14 [00:45:17] initial unit tests show that it's complete, sick
		% 2013.11.14 - finished bsxfun-ing the loop over the signal, haven't speed-tested to see if it is faster...should be. Keeping for-loop code in case need to add some sort of processing there later.

	%========================
	% old way of saving, only temporary until full switch
	options.overallAlign = 0;
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% check that inputs are correct
	if isempty(responseSignal)|isempty(alignmentSignal)|isempty(timeSeq)
		alignedSignal = [];
		return
	end
	% attempt to align the input signals to the alignment points
	try
		% create a function to do the outer product
		% note: we do this to avoid a for-loop over all alignment indices. this allows us to create a large matrix containing all the indices that need to be aligned
		outerFun = @(x,y) x+y;
		% get number of signals to analyze
		nSignals = size(responseSignal,1);
		% number of points
		nAlignPoints = length(timeSeq);
		% pre-allocate the aligned signal
		alignedSignal = zeros(nSignals,nAlignPoints);
		% find the locations to align
		alignIndicies = find(alignmentSignal==1);
		%
		nAlignIdx = length(alignIndicies);
		% outer the time sequence and the current indices to get a MxN matrix of M indices before/after N alignment points
		alignIdx = bsxfun(outerFun,timeSeq',alignIndicies);

		% for signalNum = 1:nSignals
		% 	thisSignal = responseSignal(signalNum,:);
		% 	% get the indices and then just sum over N dimension to get total response at each time-point before/after alignment points
		% 	thisAlignedSignal = sum(thisSignal(alignIdx),2);
		% 	% all to alignedSignal matrix
		% 	alignedSignal(signalNum,:) = thisAlignedSignal;
		% end

		% faster, non-loop method
		% get the indices as a Mx(nAlignPoints*nAlignIdx)
		alignedSignal = responseSignal(:,alignIdx);
		% reshape so have all alignment points as own 2D matrix
		alignedSignal = sum(reshape(alignedSignal', [nAlignPoints nAlignIdx nSignals]),2);
		% squeeze to 2D, flip so have [nSignals nAlignPoints] matrix
		alignedSignal = squeeze(alignedSignal)'
		% reshape(alignedSignal, [length(alignIdx) nSignals nAlignPoints])

		% if want to get the sum over all input signals
		if options.overallAlign==1
			alignedSignal = sum(alignedSignal,2);
		end
	catch errorObj
		errorObj.message
		errorObj.stack
		alignedSignal=[];
	end
