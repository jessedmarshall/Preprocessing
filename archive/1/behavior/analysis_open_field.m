% biafra ahanonu
% 2013.02.23
% open field parser
% script goes through each open field test and parses/bins the data to make
% analysis easier in R

function [exportMouseData,multiMouseData] = analysis_open_field(data,properties)
    % if ~exist('data','var'), tol = eps; end
    % if ~exist('properties','var'), tol = eps; end
    DATA_DIR = 'C:/Users/B/Dropbox/biafra/Stanford/Lab/schnitzer/data/open_field/analysis'
    OUTPUT_CSV = 'database.mice.open_field.huntington.csv'

    % Number of bins to split data into
    NUM_SPLIT_BINS = 12;
    bins = NUM_SPLIT_BINS;
    % number of minutes in a trial
    trialMinutes = 30;
    % Preallocate for speed
    % multiMouseData = zeros();
    multiMouseData = [];
    exportMouseData = [];

    % ask user for directory
    DEFAULT_DIR = 'C:/Users/B/Dropbox/biafra/Stanford/Lab/schnitzer/data/open_field/huntington_raw/';
    usrDir = uigetdir(DEFAULT_DIR);
    if ISPC
        usrFiles = ls(usrDir);
    elseif ISMAC
        usrFiles = ls(usrDir);
    elseif ISUNIX
        usrFiles = ls(usrDir);
    end
    % Number of tests and subject
    listOfSubjects = [];
    listOfTests = [];
    if ~strcmp(class(data),'double')
        % first two files are . and ..
        for subject = 3:size(usrFiles,1)
            % get filename
            fileToRead = [usrFiles(subject,:)];
            % get file info to be parsed
            fileInfo = regexp(fileToRead,'\.','split');
            fileInfo = regexp(fileInfo{1},'_','split');
            % read out test and subject information
            test = str2num(fileInfo{7});
            canulaTime = fileInfo{4};
            canulaTime = strcmp(canulaTime,'pre');
            % subject = str2num(fileInfo{9})
            listOfTests = [listOfTests test];
            listOfSubjects = [listOfSubjects subject];
            % open file identifier
            [usrDir '\' fileToRead];
            fid = fopen([usrDir '\' fileToRead],'rt');
            % read in data line-by-line
            multiMouseData.data{test,subject} = textscan(fid, '%f%f%f%f%f%f%f%f%f%f%f', 'TreatAsEmpty', '"-"', 'EmptyValue', nan,'Headerlines',33,'delimiter',',','CollectOutput',1);
            multiMouseData.data{test,subject} = multiMouseData.data{test,subject}{1,1};
            % close file id
            fclose(fid);
            % mouse.data = multiMouseData.data{test,subject};
            ['Loaded: ',fileToRead]
            if strcmp(properties,'no')
                mouseData = 1;
            elseif strcmp(properties,'yes')&&~strcmp(class(data),'double')
                mouseDataToPass = multiMouseData.data{test,subject};
                mouseInfo = [test subject canulaTime];
                singleMouseData = mouseProperties(mouseDataToPass(2:end,:),mouseInfo,bins,trialMinutes);
                exportMouseData = [exportMouseData; singleMouseData];
                % plot
                subplotNum = 4;
                figure(1)
                    subplot(subplotNum,round(size(usrFiles,1)/subplotNum),subject-2);
                    plot(singleMouseData(:,1))
                    % VRiD_color_plot(mouseDataToPass(2:end,3),mouseDataToPass(2:end,4),'',0)
                figure(2)
                    subplot(subplotNum,round(size(usrFiles,1)/subplotNum),subject-2);
                    % make a color plot
                    VRiD_color_plot(mouseDataToPass(2:end,3),mouseDataToPass(2:end,4),'',0)
            end
        end
    else
        exportMouseData = data;
    end
    exportFileLocation = [DATA_DIR '/' OUTPUT_CSV];
    % write out headers
    exportHeaders = {'distance','velocity','test','subject','canulaTime','time'};
    fid = fopen(exportFileLocation,'w');
        % exportHeaderFormat = [repmat('%s,',1,size(exportHeaders,2))];
        % exportHeaderFormat = [exportHeaderFormat(1:end-1), '\n'];
        exportStr = sprintf('%s,', exportHeaders{:});
        fprintf(fid, '%s\n', exportStr(1:end-1));
    fclose(fid);
    % write out data
    dlmwrite(exportFileLocation,exportMouseData,'-append','delimiter',',');
    % try
    %     if strcmp(properties,'no')
    %         mouseData = 1
    %     elseif strcmp(properties,'yes')&&~strcmp(class(data),'double')
    %         mouseData = mouseProperties(multiMouseData,listOfTests,listOfSubjects,bins)
    %     end
    % catch err
    %     disp(err);
    % end
    % fid = fopen([DATA_DIR '/' OUTPUT_CSV], 'w');
    % Fmt = [repmat('%f,',1,size(mouseData,2)), '\n'];
    % fprintf(fid, Fmt, transpose(mouseData));
    % fclose(fid);
end

function singleMouseData = mouseProperties(data,mouseInfo,bins,trialMinutes)
    mouse.data = data;
    % Average or sum all values in a given bin
    mouse.dim = size(mouse.data(:,8));
    % reshape(mouse.data(:,8),bins,mouse.dim(1)/bins);
    % Reshape vector so [n 1] -> [bins n/bins]
    mouse.properties = nansum(reshape(mouse.data(:,8),bins,mouse.dim(1)/bins),2);
    mouse.properties(1:bins,end+1) = nanmean(reshape(mouse.data(:,9),bins,mouse.dim(1)/bins),2);
    addMouseInfo = repmat(mouseInfo,size(mouse.properties,1),1);
    mouse.properties = [mouse.properties addMouseInfo];
    % add the time, in minutes
    time = [trialMinutes/bins:trialMinutes/bins:trialMinutes];
    mouse.properties = [mouse.properties time'];
    % export data
    singleMouseData = mouse.properties;
end
%% parseDataOld: function description
function [outputs] = parseDataOld(arg)
    if strcmp(class(data),'double')
        for test=numberOfTests
            for subject=numberOfSubjects
                %% Import data
                test
                subject
                % mouse = importdata(['C:/Users/B/Dropbox/biafra/Stanford/Lab/schnitzer/data/open_field/all/hd_openfield',num2str(test),'_subject_',num2str(1),'.txt'],',',33);
                % mouse.colheaders=regexp(mouse.textdata(32,1),',','split');
                % mouse.data=str2double(mouse.textdata([34:end],[1:9]));

                fileToRead = ['C:/Users/B/Dropbox/biafra/Stanford/Lab/schnitzer/data/open_field/huntington_raw/hd_openfield',num2str(test),'_subject_',num2str(subject),'.txt'];
               % mouseALL.data{test,subject} = dlmread(fileToRead,',',34,0);

                fid = fopen(fileToRead,'rt');
                mouseALL.data{test,subject} = textscan(fid, '%f%f%f%f%f%f%f%f%f%f%f', 'TreatAsEmpty', '"-"', 'EmptyValue', nan,'Headerlines',33,'delimiter',',','CollectOutput',1);
                fclose(fid);
                mouseALL.data{test,subject} = mouseALL.data{test,subject}{1,1};
                mouse.data = mouseALL.data{test,subject};
                ['Loaded: ',fileToRead]

                % %% Average or sum all values in a given bin
                % mouse.dim = size(mouse.data(:,8));
                % % reshape(mouse.data(:,8),bins,mouse.dim(1)/bins);
                % % Reshape vector so [n 1] -> [bins n/bins]
                % mouse.distance = nansum(reshape(mouse.data(:,8),bins,mouse.dim(1)/bins),2);
                % mouse.distance(1:bins,2) = subject;
                % mouse.distance(1:bins,3) = test;
                % % Add to greater subject matrix
                % mouseData = [mouseData; mouse.distance];
            end
        end
    else
        mouseALL = data
    end
    if strcmp(properties,'no')
        mouseData = 1
    elseif strcmp(properties,'yes')&&~strcmp(class(data),'double')
        mouseData = mouseProperties(mouseALL,numberOfTests,numberOfSubjects,bins)
    end
end
