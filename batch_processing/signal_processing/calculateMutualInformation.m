function [MI] = calculateMutualInformation(responseSignal,stimulusSignal)
	% calculates the mutual information between n signals in responseSignal [n t] to stimulusSignal [1 t] and outputs a [1 n] vector of MI values.
	% biafra ahanonu
	% started: 2013.11.04 [16:27:29]
	% adapted from SpikeE code written by Lacey Kitch in 2012
		% X is the response matrix
		% Y is the stimulus matrix
	% inputs
		%
	% outputs
		%
	% changelog
		% 2013.11.18 [20:09:13]
		% 2013.12.26 streamlined some calculations and made naming consistent
	% TODO
		%
	try
	    % get parameters
	    nSignals=size(responseSignal,1);
	    nStims=size(stimulusSignal,1);
	    nPoints=size(responseSignal,2);
		MI = nan(nSignals,1);

	    if length(stimulusSignal)~=nPoints
	        display('length of response and stimulus are not equal');
	        return
	    else
	        % divide y to have nStims discrete values, range 0 to nStims-1
	        % Y=round((stimulusSignal-min(stimulusSignal))*(nStims-1)/(max(stimulusSignal)-min(stimulusSignal)));
	        Y = logical(stimulusSignal);
	    end
	    % put X data into logical matrix
       	X=logical(responseSignal);

	    % pre-allocate matrix
	    % logProbY=zeros(1,nStims);
	    % logProbX0givenY=zeros(nSignals, nStims);
	    % logProbX1givenY=zeros(nSignals, nStims);
	    % calculate the joint probabilities
	    % for yVal=0:nStims-1
	    %     logProbY(yVal+1)=log(sum(Y==yVal))-log(nPoints);
	    %     theseX=X(:,Y==yVal);
	    %     logProbX0givenY(:,yVal+1)=log(sum(1-theseX,2)+1)-log(size(theseX,2)+1);
	    %     logProbX1givenY(:, yVal+1)=log(sum(theseX,2)+1)-log(size(theseX,2)+1);
	    % end

	    % calculate probabilities
	    logProbX0=log(sum(1-X,2))-log(nPoints);
	    logProbX1=log(sum(X,2))-log(nPoints);
	    logProbY=log(sum(Y))-log(nPoints);
	    theseX = X(:,logical(Y));
		logProbX0givenY=log(sum(1-theseX,2)+1)-log(size(theseX,2)+1);
		logProbX1givenY=log(sum(theseX,2)+1)-log(size(theseX,2)+1);
	    logProbX0andY=log(exp(logProbX0givenY).*repmat(exp(logProbY),nSignals,1));
	    logProbX1andY=log(exp(logProbX1givenY).*repmat(exp(logProbY),nSignals,1));

	    % calculate MI
	    MI=sum(exp(logProbX0andY).*(logProbX0andY-repmat(logProbX0,1,nStims)-repmat(logProbY,nSignals,1)),2)+...
	        sum(exp(logProbX1andY).*(logProbX1andY-repmat(logProbX1,1,nStims)-repmat(logProbY,nSignals,1)),2);

	catch errorObj
		% display error message
	    % errordlg(getReport(errorObj,'extended','hyperlinks','off'),'Error');
	end