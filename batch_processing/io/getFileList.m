function [fileList] = getFileList(inputDir, filterExp,varargin)
    % gathers a list of files based on an input regular expression
    % biafra ahanonu
    % started: 2013.10.08 [11:02:31]
    % inputs
        % inputDir - directory to gather files from and regexp filter for files
        % filterExp - regexp used to find files
    % outputs
        % file list, full path

    % changelog
        % 2014.03.21 - added feature to input cell array of filters
    % TODO
        %

    %========================
    options.recusive = 0;
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %     eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    if ~strcmp(class(filterExp),'cell')
        filterExp = {filterExp};
    end
    if strcmp(class(inputDir),'char')
        inputDir = {inputDir};
    end

    fileList = {};
    for thisDir=inputDir
        thisDir = thisDir{1};
        if options.recusive==0
            files = dir(thisDir);
        else
            files = dirrec(thisDir)';
        end
        for file=1:length(files)
            if options.recusive==0
                filename = files(file,1).name;
                if(~isempty(cell2mat(regexpi(filename, filterExp))))
                    fileList{end+1} = [thisDir filesep filename];
                end
            else
                filename = files(file,:);
                filename = filename{1};
                if(~isempty(cell2mat(regexpi(filename, filterExp))))
                    fileList{end+1} = [filename];
                end
            end
        end
    end
end