function [trackingTableFiltered] = removeIncorrectObjs(tablePath,varargin)
    % removes incorrect objects from a tracking CSV file
    % biafra ahanonu
    % updated: 2014.05.01
    % inputs
        % tablePath - path to CSV file containing tracking information
    % outputs
        % trackingTableFiltered - table where each Slice (frame) only has a single associated set of column data, based on finding row with max area

    % changelog
        % updated: 2014.05.01 - improved speed by switching to more matrix operations-based filtering
    % TODO
        % make assumption of columns NOT hardcoded as is currently

    % ========================
    % grouping row
    options.groupingVar = 'Slice';
    % variable to sort on
    options.sortingVar = 'Area';
    % rows to sort by and in what direction
    options.sortRows = {options.groupingVar,options.sortingVar};
    options.sortRowsDirection = {'ascend','descend'};
    % max size of sorting var, e.g. max area size
    options.maxSortingVar = [];
    % 'true' if want to save the file
    options.saveFile = [];
    % columns to keep (obsolete!)
    options.listOfCols = {'Area','XM','YM','Major','Minor','Angle'};
    % information table to add pxToCm
    options.subjectInfoTable = [];
    % cm/s to use as a cutoff.
    options.velocityCutoff = 30*8;
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
        if strcmp(class(tablePath),'char')
            tablePath = {tablePath};
        end
        inputTablePaths = tablePath;
        nFiles = length(inputTablePaths);
        for pathNo=1:nFiles
            tablePath = inputTablePaths{pathNo};
            display(repmat('=',1,7))
            display([num2str(pathNo) '/' num2str(nFiles) ': ' tablePath])
            % make sure sort rows is updated
            options.sortRows = {options.groupingVar,options.sortingVar};
            % read in the table
            trackingTable = readtable(tablePath,'Delimiter','comma','FileType','text');
            tic
            % sort the rows, largest obj is first for each grouping variable value
            [trackingTableFiltered,index] = sortrows(trackingTable,options.sortRows,options.sortRowsDirection);
            % get the diff, allow index of first row in each slice, i.e. the max obj
            maxIdx = diff(trackingTableFiltered.(options.groupingVar));
            % first row should be indexed and offset corrected
            maxIdx = [1; maxIdx];
            % filter for largest objs
            trackingTableFiltered = trackingTableFiltered(logical(maxIdx),:);
            toc;tic
            % if remove maxSortingVar
            if ~isempty(options.maxSortingVar)
                maxIdx = trackingTableFiltered.(options.sortingVar)>options.maxSortingVar;
                trackingTableFiltered = trackingTableFiltered(~maxIdx,:);
            end

            % add NaN rows for missing grouping var
            groupingVarTmp = trackingTableFiltered.(options.groupingVar);
            nGroups = groupingVarTmp(end);
            completeGroupingVarSet = 1:nGroups;
            missingIdx = setdiff(completeGroupingVarSet,groupingVarTmp);
            % if missing idx, add NaN rows
            if ~isempty(missingIdx)
                display('adding missing data')
                tableNames = fieldnames(trackingTableFiltered);
                tableNames = setdiff(tableNames,{'Properties',options.groupingVar});
                tmpTable.(options.groupingVar) = missingIdx';
                nMissing = length(missingIdx);
                % setfield(tmpTable,{1,1},tableNames,{1:nMissing},nan)
                % for each field name, add NaNs
                for i=1:length(tableNames)
                    tmpTable.(tableNames{i}) = nan([1 nMissing])';
                end
                % add NaNs to output table
                trackingTableFiltered = [trackingTableFiltered;struct2table(tmpTable)];
                [trackingTableFiltered,index] = sortrows(trackingTableFiltered,options.sortRows,options.sortRowsDirection);
            end

            % add in pixel to cm column if asked
            if ~isempty(options.subjectInfoTable)
                options.originalColumns = {'XM','YM'};
                options.newColumns = {'XM_cm','YM_cm'};
                options.modifierColumn = 'pxToCm';
                options.delimiter = ',';
                subjectInfoTable = readtable(char(options.subjectInfoTable),'Delimiter',options.delimiter,'FileType','text');
                fileInfo = getFileInfo(tablePath);
                % fileInfoSaveStr = [fileInfo.date '_' fileInfo.protocol '_' fileInfo.subject '_' fileInfo.assay];
                % subjectInfoTable
                dateIdx = strcmp(subjectInfoTable.date,strrep(fileInfo.date,'_','.'));
                subjectIdx = subjectInfoTable.subject==fileInfo.subjectNum;
                assayIdx = strcmp(subjectInfoTable.assay,fileInfo.assay);
                thisTable = subjectInfoTable(dateIdx&subjectIdx&assayIdx,:);
                thisTable = thisTable(1,:);
                for columnNo = 1:length(options.originalColumns)
                    trackingTableFiltered.(options.newColumns{columnNo}) = trackingTableFiltered.(options.originalColumns{columnNo})/thisTable.(options.modifierColumn);
                end
            else
                options.originalColumns = {'XM','YM'};
                options.newColumns = {'XM_cm','YM_cm'};
                for columnNo = 1:length(options.originalColumns)
                    trackingTableFiltered.(options.newColumns{columnNo}) = trackingTableFiltered.(options.originalColumns{columnNo});
                end
            end

            % trackingTableFiltered(1:10,:)

            xdiff = [0; diff(trackingTableFiltered.XM)];
            ydiff = [0; diff(trackingTableFiltered.YM)];
            trackingTableFiltered.velocity = sqrt(xdiff.^2 + ydiff.^2);
            figure(pathNo)
            subplot(2,2,1)
            plot(trackingTableFiltered.XM_cm,trackingTableFiltered.YM_cm)
            subplot(2,2,2)
            plot(trackingTableFiltered.velocity)
            hold on; plot([1 size(trackingTableFiltered,1)],[2 2],'r');
            hold on; plot([1 size(trackingTableFiltered,1)],[options.velocityCutoff options.velocityCutoff],'r');


            velocityFilterIdx = trackingTableFiltered.velocity>=options.velocityCutoff;
            velocityFilterIdx = find(velocityFilterIdx);
            velocityFilterIdx = [find(isnan(trackingTableFiltered.velocity(:)))' velocityFilterIdx(:)'];
            % trackingTableFiltered = trackingTableFiltered(velocityFilterIdx,:);
            % velocity = velocity(velocityFilterIdx);
            if ~isempty(velocityFilterIdx)
                display('removing incorrect velocity rows')
                tableNames = fieldnames(trackingTableFiltered);
                tableNames = setdiff(tableNames,{'Properties',options.groupingVar});
                tmpTable.(options.groupingVar) = velocityFilterIdx(:);
                nMissing = length(velocityFilterIdx);
                % setfield(tmpTable,{1,1},tableNames,{1:nMissing},nan)
                % for each field name, add NaNs
                nanVector = nan([1 nMissing]);
                for i=1:length(tableNames)
                    tmpTable.(tableNames{i}) = nanVector(:);
                end
                % tmpTable
                % struct2table(tmpTable)
                % trackingTableFiltered(1:2,:)
                % add NaNs to output table
                trackingTableFiltered = trackingTableFiltered(trackingTableFiltered.velocity<options.velocityCutoff,:);
                trackingTableFiltered = [trackingTableFiltered;struct2table(tmpTable)];
                [trackingTableFiltered,index] = sortrows(trackingTableFiltered,options.sortRows,options.sortRowsDirection);
            end

            display('=====')
            % trackingTableFiltered(1:20,:)

            subplot(2,2,3)
            plot(trackingTableFiltered.XM_cm,trackingTableFiltered.YM_cm)
            subplot(2,2,4)
            plot(trackingTableFiltered.velocity)
            hold on; plot([1 size(trackingTableFiltered,1)],[2 2],'r');
            hold on; plot([1 size(trackingTableFiltered,1)],[options.velocityCutoff options.velocityCutoff],'r');
            % hold off
            % hist(trackingTableFiltered.velocity,100)
            % hold on; plot([2 2],[1 1000],'r');


            figure(pathNo+100)
            plot(trackingTableFiltered.XM_cm,trackingTableFiltered.YM_cm)

            fileInfoSaveStr = [strrep(strrep(fileInfo.date,'\','/'),'_','.') ' ' fileInfo.protocol ' ' fileInfo.subject ' ' fileInfo.assay];
            suptitle(fileInfoSaveStr);
            % suptitle(strrep(strrep(tablePath,'\','/'),'_','.'))

            % save filtered table if user ask
            if ~isempty(options.saveFile)
                [pathstr,name,ext] = fileparts(tablePath);
                options.newFilename = [pathstr '\' name '_cleaned.csv'];
                display(['saving: ' options.newFilename])
                writetable(trackingTableFiltered,options.newFilename,'FileType','text','Delimiter',',');
            end

            clear tmpTable trackingTableFiltered

            toc
        end
        % old way of doing it, much slower
        % trackingTableFiltered = rowfun(@keepMaxArea,trackingTable,...
            % 'InputVariables',options.listOfCols,...
            % 'GroupingVariable','Slice',...
            % 'OutputVariableName',options.listOfCols);
        % nSlices = trackingTableFiltered.Slice(end);
    catch err
        display(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        display(repmat('@',1,7))
    end

function [Area,XM,YM,Major,Minor,Angle] = keepMaxArea(Area,XM,YM,Major,Minor,Angle)
    idx = find(max(Area)==Area);
    Area = Area(idx);
    XM = XM(idx);
    YM = YM(idx);
    Major = Major(idx);
    Minor = Minor(idx);
    Angle = Angle(idx);