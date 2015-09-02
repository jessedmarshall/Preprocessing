function [ICthresholded] = thresholdICs(thisFilt)
    % biafra ahanonu
    % adapted from SpikeE
    % updated: 2013.10.xx

    % changelog
        % updated: 2013.11.04 [15:30:05] added try...catch block to get around some errors for specific filters

    threshold = 0.5;

    % Threshold
    maxVal=max(thisFilt(:));
    thisFilt(thisFilt<maxVal*threshold)=0;

    % Normalize
    thisFilt=thisFilt/maxVal;

    % Remove any pixels not connected to the IC max value
    % if there is a filter with max values at the edge, try...catch to get around error
    try
        [indx indy] = find(thisFilt==1); %Find the maximum
        B = bwlabeln(thisFilt);
        thisFilt(B~=B(indx,indy)) = 0;
    catch
    end
    ICthresholded=thisFilt;