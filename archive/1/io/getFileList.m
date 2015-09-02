function [fileList] = getFileList(inputDir, filterExp)
    % biafra ahanonu
    % updated: 2013.10.08 [11:02:31]
    % inputs: directory to gather files from and regexp filter for files
    % outputs: file list, full path

    files = dir(inputDir);
    fileList = {};
    for file=1:length(files)
        filename = files(file,1).name;
        if(~isempty(regexp(filename, filterExp)))
            fileList{end+1} = [inputDir filesep filename];
        end
    end
