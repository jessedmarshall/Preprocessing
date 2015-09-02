function [options] = getSettings(functionName)
    % send back default options to getOptions
    % biafra ahanonu
    % started: 2014.12.10
    %
    % inputs
    %   options - structure with options given
    %   inputArgs - as stated
    %
    % note
    %   don't let this function call getOptions! Else you'll potentially get into an infinite loop.

    % changelog
    %
    % TODO
    %   allow input of an option structure - DONE!

    switch functionName
        case 'modelGetStim'
            options.array = 'discreteStimulusArray';
            options.nameArray = 'stimulusNameArray';
            options.idArray = 'stimulusIdArray';
            options.stimFramesOnly = 0;
        otherwise
            options = [];
    end