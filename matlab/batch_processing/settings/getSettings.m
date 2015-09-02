function [options] = getSettings(functionName)
    % send back default options to getOptions
    % biafra ahanonu
    % started: 2014.12.10
    %
    % inputs
    %   functionName - name of function whose option should be loaded
    %
    % note
    %   don't let this function call getOptions! Else you'll potentially get into an infinite loop.

    % changelog
    %

    try
        switch functionName
            case 'modelGetStim'
                options.array = 'discreteStimulusArray';
                options.nameArray = 'stimulusNameArray';
                options.idArray = 'stimulusIdArray';
                options.stimFramesOnly = 0;
            otherwise
                options = [];
        end
    catch err
        display(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        display(repmat('@',1,7))
        options = [];
    end
end