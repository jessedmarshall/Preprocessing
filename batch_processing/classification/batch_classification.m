function [allsubjectStats] = batch_classification(inputPath,folderRegexp,protocol,varargin)
    % example function with outline for necessary components
    % biafra ahanonu
    % started: 2014.06.17
    % inputs
        % inputPath
        % folderRegexp
        % protocol
    % outputs
        %

    % changelog
        %
    % TODO
        %

    %========================
    % regular expression to
    options.subjectRegexp = '(m|f)\d+';
    % special protocol cases
    options.exceptionsSubjectList = {'m805','m809','m816','m817','m822'};
    % exception protocol for the subject list
    options.exceptionsSubjectProtocol = 'p92';
    % number of trials to train on
    options.numTrainingTrials = 3;
    % index of trial
    options.startFolderIdx = 3;
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    try
        files = genpath(inputPath);
        files = regexp(files,';','split');
        % folderRegexp = 'DFOF';
        fileList = {};
        for file=1:length(files)
            filename = files{file};
            if(~isempty(regexp(filename, folderRegexp, 'once')))
                fileList{end+1,1} = filename;
            end
        end
        %
        x = regexp(fileList,options.subjectRegexp,'once','match');
        for i=1:length(x)
            newX(i) = str2num(strrep(strrep(x{i},'m',''),'f',''));
        end
        nameList = sort(unique(x));
        nameList
        subjList = unique(newX);

        % fileInfo.protocol = regexp(fileStr,'p\d+', 'match');
        % if ~isempty(fileInfo.protocol)
        %     fileInfo.protocol = fileInfo.protocol{1};
        % else
        %     fileInfo.protocol = 'p000';
        % end

        %
        classifyMethod = {'beginning','spaced_out'};
        classifyMethod = 'spaced_out';
        %
        classifierTypeList = {'glm','nnet','svm'};
        classifierTypeList = {'nnet','glm','svm'};
        startTime = tic;
        for classifierType = classifierTypeList
            classifierType = char(classifierType);
            for subjNo=1:length(nameList)
                try
                    thisSubj = nameList(subjNo);

                    % only save partial list to make classifier to
                    [success] = saveFolderList('spaced_out',fileList,thisSubj,subjNo,protocol,options)

                    ioptions.classifierType = classifierType;
                    ioptions.folderListInfo = char(strcat('private',filesep,'analyze',filesep,protocol,filesep, thisSubj, '.txt'));
                    ioptions.picsSavePath = char(strcat('private',filesep,'analyze',filesep,protocol,filesep, thisSubj, '\'));
                    ioptions.classifierFilepath = char(strcat('private',filesep,'classifier',filesep,protocol,'_', thisSubj, '.mat'));
                    ioptions.runArg = 'trainClassifier';
                    if sum(ismember(options.exceptionsSubjectList,thisSubj))==1
                        ioptions.classifierFilepath = char(strcat('private',filesep,'classifier',filesep,protocol,'_', thisSubj, '.mat'));
                        ostruct = controllerAnalysis('options',ioptions,'protocol',options.exceptionsSubjectProtocol);
                    else
                        ostruct = controllerAnalysis('options',ioptions);
                    end

                    % save entire list for classifier
                    [success] = saveFolderList('all',fileList,thisSubj,subjNo,protocol,options)

                    ioptions.runArg = 'testClassifier';
                    if sum(ismember(options.exceptionsSubjectList,thisSubj))==1
                        ostruct = controllerAnalysis('options',ioptions,'protocol',options.exceptionsSubjectProtocol);
                    else
                        ostruct = controllerAnalysis('options',ioptions);
                    end
                    summaryStats = ostruct.summaryStats;
                    nRows = length(summaryStats.assayNum);
                    summaryStats.classifierType = repmat({classifierType},[nRows 1]);
                    summaryStats.classifyMethod = repmat({classifyMethod},[nRows 1]);
                    summaryStats = struct2table(summaryStats);
                    summaryStats = summaryStats(~isnan(cell2mat(summaryStats.assayNum)),:);
                    writetable(summaryStats,char(strcat('private',filesep,'data',filesep,protocol,'_',thisSubj,'_classifySummary.tab')),'FileType','text','Delimiter','\t');
                    if exist('allsubjectStats','var')
                        allsubjectStats = [allsubjectStats;summaryStats];
                    else
                        allsubjectStats = summaryStats;
                    end
                    writetable(allsubjectStats,char(strcat('private',filesep,'data',filesep,protocol,'_classifySummary.tab')),'FileType','text','Delimiter','\t');
                catch err
                    display(repmat('@',1,7))
                    disp(getReport(err,'extended','hyperlinks','on'));
                    display(repmat('@',1,7))
                end
            end
        end
        toc(startTime)
    catch err
        display(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        display(repmat('@',1,7))
    end

function [success] = saveFolderList(folderIdxStr,fileList,thisSubj,subjNo,protocol,options)
    % saves all or a specific subset of a folder list

    success = 0;
    subjIdx = ~cellfun('isempty',regexp(fileList,strrep(thisSubj,'m',''),'match'));
    newFileList{subjNo} = {fileList{subjIdx,1}}';
    nSubjFiles = length(newFileList{subjNo});
    switch folderIdxStr
        case 'spaced_out'
            folderIdx = floor(linspace(options.startFolderIdx,nSubjFiles-3,options.numTrainingTrials));
        case 'beginning'
            folderIdx = options.startFolderIdx:(options.startFolderIdx+options.numTrainingTrials);
        case 'all'
            folderIdx = 1:nSubjFiles;
        otherwise
            % do nothing
    end
    % save list
    fid = fopen(char(strcat('private',filesep,'analyze',filesep,protocol,filesep,thisSubj,'.txt')), 'wt');
        fprintf(fid, '%s\n', newFileList{subjNo}{folderIdx});
    fclose(fid);
    success = 1;
