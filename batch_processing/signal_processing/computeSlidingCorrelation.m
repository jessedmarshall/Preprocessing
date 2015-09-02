function [slidingCorrelation] = computeSlidingCorrelation(vectorA,vectorB,varargin)
	% calculates the correlation between vectorA and vectorB over a sliding window
	% biafra ahanonu
	% 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%
	% changelog
		%
	% TODO
		%

	%========================
	options.windowSize = 100;
	options.correlationValue = 'Pearson';
	options.waitbarOn=1;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	lenA = length(vectorA);
	lenB = length(vectorB);
	timeSeq = (-options.windowSize/2):options.windowSize/2;

	% check that vectorA and vectorB are the same length, else return null
	if ~(lenB==lenA)
		display('two vectors are not the same length!')
		slidingCorrelation = [];
		return
	end

	% create a matrix of indicies
	% outerFun = @(x,y) x+y;
	alignIndicies = options.windowSize:(lenA-options.windowSize);
	alignIdx = bsxfun(@plus,timeSeq',alignIndicies);

	% pull out the indicies
	valuesA = vectorA(alignIdx);
	valuesB = vectorB(alignIdx);

	% looping may be faster than arrayfun here, so that method is used
	numWindows = length(valuesA);
	reverseStr = '';
	for i = 1:numWindows
		thisA = valuesA(:,i);
		thisB = valuesB(:,i);
		slidingCorrelation(i) = corr(thisA, thisB,'type',options.correlationValue);
		if mod(i,50)==0&options.waitbarOn==1|i==numWindows
		    reverseStr = cmdWaitbar(i,numWindows,reverseStr,'inputStr','getting sliding correlation');
		end
	end

	% pad either end of the matrix with NaNs of length = lenA, to get same length vector out
	nanVector = NaN(1,options.windowSize);
	slidingCorrelation = [nanVector slidingCorrelation nanVector];