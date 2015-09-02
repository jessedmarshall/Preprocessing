function [options] = getOptions(options,inputArgs,varargin)
    % gets default options for a function, replaces with inputArgs inputs if they are present
    % biafra ahanonu
    % started: 2013.11.04
    %
    % inputs
    %   options - structure with options given
    %   inputArgs - as stated
    %
    % note
    %   use the 'options' name-value pair to input an options structure that will overwrite default options in a function, example below.
    %   options.Stargazer = 1;
    %   options.SHH = 0;
    %   getMutations(mutationList,'options',options);
    %
    %   This is in contrast to using name-value pairs, both will produce the same result.
    %   getMutations(mutationList,'Stargazer',1,'SHH',0);
    %
    % usage
    %   %========================
    %   options.movieType = 'tiff';
    %   % get options
    %   options = getOptions(options,varargin);
    %   % unpack options into current workspace, comment out if want to just call options structure
    %   fn=fieldnames(options);
    %   for i=1:length(fn)
    %       eval([fn{i} '=options.' fn{i} ';']);
    %   end
    %   %========================

    % changelog
    %   2014.02.12 [11:56:00] - added feature to allow input of an options structure that contains the options instead of having to input multiple name-value pairs.
    %   2014.12.10 [19:32:54] - now gets calling function and uses that to get default options
    % TODO
    %   +allow input of an option structure - DONE!
    %   +call settings function to have defaults for all functions in a single place - DONE!

    % get default options for a function
    [ST,I] = dbstack;
    % fieldnames(ST)
    functionName = {ST.name};
    functionName = functionName{2};
    [optionsTmp] = getSettings(functionName);
    if isempty(optionsTmp)

    else
        options = optionsTmp;
    end

    %Process options
    validOptions = fieldnames(options);

    % inputArgs = inputArgs{1};
    for i = 1:2:length(inputArgs)
        val = inputArgs{i};
        if ischar(val)
            %display([inputArgs{i} ': ' num2str(inputArgs{i+1})]);
            if strcmp('options',val)
                inputOptions = inputArgs{i+1};
                [options] = mirrorRightStruct(inputOptions,options);
            elseif ~isempty(strmatch(val,validOptions))
                % way more elegant
                options.(val) = inputArgs{i+1};
                % eval(['options.' val '=' num2str(inputArgs{i+1}) ';']);
            end
        else
            continue;
        end
    end
    %display(options);

function [pullStruct] = mirrorRightStruct(pushStruct,pullStruct)
    % overwrites fields in pullStruct with those in pushStruct, other pullStruct fields remain intact
    % more generally, copies fields in pushStruct into pullStruct, if there is an overlap in field names, pushStruct overwrites.
    pushNames = fieldnames(pushStruct);
    for name = 1:length(pushNames)
        iName = pushNames{name};
        pullStruct.(iName) = pushStruct.(iName);
    end