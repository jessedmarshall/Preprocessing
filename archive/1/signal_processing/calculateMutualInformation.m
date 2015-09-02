function [MI] = calculateMutualInformation(responseSignal,stimulusSignal)
	% biafra ahanonu
	% started: 2013.11.04 [16:27:29]
	% adapted from SpikeE code written by Lacey Kitch in 2012
	%
	% This function calculates the mutual information between all signals in responseSignal to stimulusSignal. It outputs a 1xN vector, where N = num of signals, of MI values.
	%
	% Y is the response variable
	% X is the matrix of traces
	% changelog
		% 2013.11.18 [20:09:13]

	try
	    % get parameters
	    numXtraces=size(responseSignal,1);
	    yTrace=stimulusSignal;
	    numValuesY=size(yTrace,1);

	    numPoints=length(responseSignal);
	    if length(yTrace)~=numPoints
	        error('Y trace not same length as X traces')
	    else
	        % divide y to have numValuesY discrete values, range 0 to
	        % numValuesY-1
	        Y=round((yTrace-min(yTrace))*(numValuesY-1)/(max(yTrace)-min(yTrace)));
	    end
	    % put X data into logical matrix
	    X=false(numXtraces, numPoints);
	    for i=1:numXtraces
            X(i,:)=logical(responseSignal(i,:));
	    end

	    % calculate probabilities
	    logProbX0=log(sum(1-X,2))-log(numPoints);
	    logProbX1=log(sum(X,2))-log(numPoints);
	    logProbY=zeros(1,numValuesY);
	    logProbX0givenY=zeros(numXtraces, numValuesY);
	    logProbX1givenY=zeros(numXtraces, numValuesY);
	    for yVal=0:numValuesY-1
	        logProbY(yVal+1)=log(sum(Y==yVal))-log(numPoints);
	        theseX=X(:,Y==yVal);
	        logProbX0givenY(:,yVal+1)=log(sum(1-theseX,2)+1)-log(size(theseX,2)+1);
	        logProbX1givenY(:, yVal+1)=log(sum(theseX,2)+1)-log(size(theseX,2)+1);
	    end
	    logProbX0andY=log(exp(logProbX0givenY).*repmat(exp(logProbY),numXtraces,1));
	    logProbX1andY=log(exp(logProbX1givenY).*repmat(exp(logProbY),numXtraces,1));

	    % calculate MI
	    MI=sum(exp(logProbX0andY).*(logProbX0andY-repmat(logProbX0,1,numValuesY)-repmat(logProbY,numXtraces,1)),2)+...
	        sum(exp(logProbX1andY).*(logProbX1andY-repmat(logProbX1,1,numValuesY)-repmat(logProbY,numXtraces,1)),2);

	% In case of errors
	catch errorObj

	    % If there is a problem, we display the error message
	    errordlg(getReport(errorObj,'extended','hyperlinks','off'),'Error');
	end