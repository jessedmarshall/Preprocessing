classdef behaviorAnalysis < dynamicprops
    % Performs analysis on behavior (response signals) compared to stimulus or other continuous signals during a trial.
    % biafra ahanonu
    % started: 2014.07.31
    % This is a re-write of old code from controllerAnalysis. Encapsulating the functions and variables as methods and properties in a class should allow easier maintenance/flexibility.
    % inputs
        %
    % outputs
        %

    % changelog
        %
    % TODO
        %

    % dynamicprops is a subclass of handle, allowing addition of properties

    properties(GetAccess = 'public', SetAccess = 'public')
        % public read and write access.

        defaultObjDir = pwd;
        % 0 = load variables from disk, reduce RAM usage. 1 = load from disk to ram, faster for analysis.
        loadVarsToRam = 0;
        % show GUI for view functions?
        guiEnabled = 1;
        % indices for folders to analyze, [] = all
        foldersToAnalyze = [];
        % indices for stimuli to analyze, [] = all
        discreteStimuliToAnalyze = [];
        % io settings
        fileFilterRegexp = 'crop';
        % loop over all files during analysis? 'individual' or 'group'
        analysisType  = 'group';
        % 1 = perform certain analysis on dF/F instead of peaks
        dfofAnalysis = 0;
        % 'filtered' returns auto/manually filtered signals/images, 'raw' returns raw
        modelGetSignalsImagesReturnType = 'filtered'
        % name of input dataset name for preprocessing
        inputDatasetName = '/1';
        %
        stimTriggerOnset = 0;
        picsSavePath = 'private\pics\';
        dataSavePath = 'private\data\';
        delimiter = ',';
        %
        hdf5Datasetname = '/1';
        % type of images to save analysis as '-dpng','-dmeta','-depsc2'
        imgSaveTypes = {'-dpng'};
        % colormap to be used
        colormap = customColormap([]);
        % use for stimulus related viewing functions
        % frames before/after stimulus to look
        timeSequence = [-50:50];
        postStimulusTimeSeq = [0:10];
        %
        stimulusTableValueName = 'frameSessionDownsampled';
        stimulusTableFrameName = 'frameSessionDownsampled';
        stimulusTableTimeName = 'time';
        stimulusTableSessionName = 'trial';

        % EM and PCAICA names
        rawICfiltersSaveStr = '_ICfilters.mat';
        rawICtracesSaveStr = '_ICtraces.mat';
        %
        rawROItracesSaveStr = '_ROItraces.mat';
        %
        rawEMStructSaveStr = '_emAnalysis.mat';
        %
        signalExtractionMethod = 'PCAICA';%EM

        settingOptions = struct(...
            'analysisType',  {{'group','individual'}},...
            'loadVarsToRam', {{0,1}},...
            'guiEnabled', {{0,1}},...
            'dfofAnalysis', {{0,1}},...
            'picsSavePath', {{'private\pics\'}},...
            'delimiter', {{',','tab'}},...
            'imgSaveTypes', {{'-dpng','-dmeta','-depsc2'}}...
        );

        % io folders
        inputFolders = {};
        videoDir = '';
        videoSaveDir = '';
        % if want to automatically save object to a specific location.
        objSaveLocation = [];

        % signal related
        % either the raw signals (traces) or
        rawSignals = {};
        %
        rawImages = {};
        % computed signal peaks/locations, to reduce computation in functions
        signalPeaks = {};
        %
        signalPeaksArray = {};
        % computed centroid locations {[x y],...}
        objLocations = {};
        % cellmaps indicating which cells were filtered
        rawImagesFiltered = {};
        % structure of classifier structures, each field in the property should be named after the folder's subject, e.g. classifierStructs.m667 is the classification structure for subject m667
        classifierStructs = {};
        % structure of classifier structures for each folder, e.g. after running classification on each
        classifierFolderStructs = {};
        % Automated or manual classification
        validManual = {};
        % from automated classification
        validAuto = {};
        % valid cells based on a regional modification
        validRegionMod = {};
        % polygon vertices from previously selected regions
        validRegionModPoly = {};
        % whether or not rawSignals/rawImages have been replaced by only valid signals, hence, ignore validManual/validAuto
        validPurge = 0;
        % ROI to use for exclusion analysis
        analysisROIArray = {};
        % number of expected [PCs ICs] for PCA-ICA, alter for other procedures
        numExpectedSignals = {};

        % subject info
        % all are cell array of strings or numbers as specified in the name
        dataPath = {};
        subjectNum = {};
        subjectStr = {};
        assay = {};
        protocol = {};
        assayType = {};
        assayNum = {};
        date = {};
        fileIDArray = {};
        fileIDNameArray = {};
        folderBaseSaveStr = {};

        % path to CSV/TAB file or matlab table containing trial information and frames when stimuli occur
        discreteStimulusTable = {};
        % cell array of strings
        stimulusNameArray = {};
        % cell array of strings, used for saving pictures/etc.
        stimulusSaveNameArray = {};
        % cell array of numbered values for stimulus, e.g. {65,10}
        stimulusIdArray = {};
        % [1 numTrialFrames] vectors with 1 for when stimulus occurs
        stimulusVectorArray = {};
        % vector sequence before/after to analyze stimulus
        stimulusTimeSeq = {};

        % path to a CSV/TAB file
        continuousStimulusTable = {};
        % cell array of strings
        continuousStimulusNameArray = {};
        % cell array of strings, used for saving pictures/etc.
        continuousStimulusSaveNameArray = {};
        % cell array of numbered values for stimulus, e.g. {65,10}
        continuousStimulusIdArray = {};
        % [1 numTrialFrames] vectors with 1 for when stimulus occurs
        continuousStimulusVectorArray = {};
        % vector sequence before/after to analyze stimulus
        continuousStimulusTimeSeq = {};

        % behavior metrics
        behaviorMetricTable = {};
        behaviorMetricNameArray = {};
        behaviorMetricIdArray = {};
    end
    properties(GetAccess = 'public', SetAccess = 'private')
        % public read access, but private write access.

        % summary statistics data save stores
        sumStats = {};
        detailStats = {};

        % counters and stores
        % index of current folder
        fileNum = 1;
        % same as fileNum, will transfer to this since more clear
        folderNum = 1;
        % number to current stimulus index
        stimNum = 1;
        figNames = {};
        figNo = {};
        figNoAll = 777;

        % signal related
        nSignals = {};
        nFrames = {};
        signalPeaksCopy = {};
        alignedSignalArray = {};
        alignedSignalShuffledMeanArray = {};
        alignedSignalShuffledStdArray = {};

        % stimulus
        % reorganize discreteStimulusTable into stimulus structures to reduce memory footprint
        discreteStimulusArray = {};
        discreteStimMetrics = {};

        % stimulus
        % reorganize discreteStimulusTable into stimulus structures to reduce memory footprint
        continuousStimulusArray = {};
        continuousStimMetrics = {};

        % behavior metric
        % reorganize behaviorMetricTable into stimulus structures to reduce memory footprint/provide common IO
        behaviorMetricArray = {};

        % distance metrics
        distanceMetric = {};
        distanceMetricShuffleMean = {};
        distanceMetricShuffleStd = {};

        % correlation metrics
        corrMatrix = {};

        % significant signals, different variables for controlling which signals are statistically significant, given some test
        currentSignificantArray = [];
        significantArray = {};
        sigModSignals = {};
        sigModSignalsAll = {};
        ttestSignSignals = {};

        % cross session alignment
        globalIDs = [];
        globalIDCoords = {};
        globalIDFolders = {};
        globalIDImages = {};
        globalRegistrationCoords = {};
        globalObjectMapTurboreg = [];
        globalStimMetric = [];
    end
    properties(GetAccess = 'private', SetAccess = 'private')
       % private read and write access
    end
    properties(Constant = true)
        % cannot be changed after object is created
        FRAMES_PER_SECOND =  5;
        DOWNSAMPLE_FACTOR =  4;
        MICRON_PER_PIXEL =  2.37;
    end

    methods
        % methods, including the constructor are defined in this block
        function obj = behaviorAnalysis(varargin)
            % CLASS CONSTRUCTOR
            display(repmat('#',1,7))
            display('constructing behavioral analysis object...')

            % Because the obj
            %========================
            % obj.exampleOption = '';
            % get options
            obj = getOptions(obj,varargin);
            % display(options)
            % unpack options into current workspace
            % fn=fieldnames(options);
            % for i=1:length(fn)
            %    eval([fn{i} '=options.' fn{i} ';']);
            % end
            %========================

            obj = initializeObj(obj);

            display('done!')
            display(repmat('#',1,7))
        end
        % getter and setter functions
        function dataPath = get.dataPath(obj)
            dataPath = obj.dataPath;
        end
    end
    methods(Static = true)
        % functions that are related but not dependent on instances of the class
        % function obj = loadObj(oldObj)
        %     [filePath,folderPath,~] = uigetfile('*.*','select text file that points to analysis folders','example.txt');
        %     % exit if user picks nothing
        %     % if folderListInfo==0; return; end
        %     load([folderPath filesep filePath]);
        %     oldObj = obj;
        %     obj = behaviorAnalysis;
        %     obj = getOptions(obj,oldObj);
        % end
    end
    methods(Access = private)
       % methods only executed by other class methods

       % model methods, usually for input-output like saving information to files
       % for obtaining the current stim from tables
       [behaviorMetric] = modelGetBehaviorMetric(obj,inputID)
    end
    methods(Access = protected)
       % methods only executed by other class methods, also available to subclasses
    end
    methods(Access = public)
       % these are in separate M-files

       [output] = modelGetStim(obj,idNum,varargin)

       % view help about the object
       obj = help(obj)

       % compute methods, performs some computation and returns calculation to class property
       obj = computeDiscreteAlignedSignal(obj)
       obj = computeSpatioTemporalClustMetric(obj)
       obj = computeSignalPeaksFxn(obj)
       obj = computeMatchObjBtwnTrials(obj)
       obj = computeAcrossTrialSignalStimMetric(obj)
       %
       obj = computeContinuousAlignedSignal(obj)
       %
       obj = computeClassifyTrainSignals(obj)
       obj = computeManualSortSignals(obj)
       % just need stimulus files
       obj = computePopulationDistance(obj)
       obj = computeDiscreteDimReduction(obj)
       obj = computeDiscreteRateStats(obj)
       obj = computeTrialSpecificActivity(obj)
       obj = modelEditStimTable(obj)

       % view methods, for displaying charts
       % no prior computation
       obj = viewStimTrigTraces(obj)
       obj = viewCorr(obj)
       obj = viewCreateObjmaps(obj)
       obj = computeDiscreteStimulusDecoder(obj)
       obj = viewMovie(obj)
       obj = viewContinuousSignalVideo(obj)

       % require pre-computation, individual
       obj = viewStimTrig(obj)
       obj = viewObjmapStimTrig(obj)
       obj = viewChartsPieStimTrig(obj)
       obj = viewObjmapSignificant(obj)
       obj = viewSpatioTemporalMetric(obj)
       % require pre-computation, group
       obj = viewPlotSignificantPairwise(obj)
       obj = viewObjmapSignificantPairwise(obj)
       obj = viewObjmapSignificantAllStims(obj)
       % require pre-computation, group, global alignment
       obj = viewMatchObjBtwnSessions(obj)
       % movies
       obj = viewMovieCreateSignalBasedStimTrig(obj)
       % require pre-computation and behavior metrics, individual
       obj = viewSignalBehaviorCompare(obj)

       % model methods, usually for input-output like saving information to files
       obj = modelReadTable(obj,varargin)
       obj = modelTableToStimArray(obj,varargin)
       obj = modelGetFileInfo(obj)
       obj = modelVerifyDataIntegrity(obj)
       obj = modelSaveImgToFile(obj,saveFile,thisFigName,thisFigNo,thisFileID)
       obj = modelSaveSummaryStats(obj)
       obj = modelSaveDetailedStats(obj)
       obj = modelVarsFromFiles(obj)
       obj = modelModifyRegionAnalysis(obj)
       obj = modelExtractSignalsFromMovie(obj)
       obj = modelAddNewFolders(obj)
       obj = modelPreprocessMovie(obj)
       obj = modelDownsampleRawMovies(obj)
       % helper
       [inputSignals inputImages signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj,varargin)
       [fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = getAnalysisSubsetsToAnalyze(obj)

       % set methods, for IO to specific variables in a controlled manner
       obj = setMainSettings(obj)
       obj = setStimulusSettings(obj)

       function obj = runDiscreteCompute(obj)
            % runs all necessary functions for discrete stimulus analysis

            % turn off gui elements, run in batch
            obj.guiEnabled = 0;

            fxnsToRun = {'computeDiscreteAlignedSignal',
            'computeSpatioTemporalClustMetric',
            'computeMatchObjBtwnTrials',
            'computeAcrossTrialSignalStimMetric',
            'modelSaveSummaryStats',
            'modelSaveDetailedStats',};

            scnsize = get(0,'ScreenSize');
            [idNumIdxArray, ok] = listdlg('ListString',fxnsToRun,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','functions to run?');

            fxnsToRun = {fxnsToRun{idNumIdxArray}};

            for thisFxn=fxnsToRun
                display(repmat('!',1,21))
                thisFxn{1}
                obj.(thisFxn{1});
            end

            % obj.computeDiscreteAlignedSignal();
            % obj.computeSpatioTemporalClustMetric();
            % obj.computeMatchObjBtwnTrials();
            % obj.computeAcrossTrialSignalStimMetric();
            % % save analysis
            % obj.modelSaveSummaryStats();
            % obj.modelSaveDetailedStats();

            % turn gui elements back on
            obj.guiEnabled = 1;

        end

       function obj = runDiscreteView(obj)
            % runs all currently implemented view functions

            % turn off gui elements, run in batch
            obj.guiEnabled = 0;

            fxnsToRun = {...
            'viewCreateObjmaps',
            'viewStimTrigTraces',
            'viewObjmapStimTrig',
            'viewStimTrig',
            'viewCorr',
            'viewChartsPieStimTrig',
            'viewObjmapSignificant',
            'viewSpatioTemporalMetric',
            'viewPlotSignificantPairwise',
            'viewObjmapSignificantPairwise',
            'viewObjmapSignificantAllStims'};

            scnsize = get(0,'ScreenSize');
            [idNumIdxArray, ok] = listdlg('ListString',fxnsToRun,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','functions to run?');

            fxnsToRun = {fxnsToRun{idNumIdxArray}};

            for thisFxn=fxnsToRun
                display(repmat('!',1,21))
                thisFxn{1}
                obj.(thisFxn{1});
            end

            % obj.viewStimTrig();
            % obj.viewObjmapStimTrig();
            % obj.viewChartsPieStimTrig();
            % obj.viewObjmapSignificant();
            % obj.viewSpatioTemporalMetric();

            % obj.viewPlotSignificantPairwise();
            % obj.viewObjmapSignificantPairwise();
            % obj.viewObjmapSignificantAllStims();

            % turn gui elements back on
            obj.guiEnabled = 1;

        end

        function obj = runPipeline(obj)
            % initialDir = pwd;
            % set back to initial directory in case exited early
            % restoredefaultpath;
            % loadBatchFxns();
            cd(obj.defaultObjDir);

            props = properties(obj);
            totSize = 0;
            for ii=1:length(props)
                currentProperty = getfield(obj, char(props(ii)));
                s = whos('currentProperty');
                totSize = totSize + s.bytes;
            end
            sprintf('%.f',totSize*1.0e-6)
            % fprintf(1, '%d bytes\n', totSize*1.0e-6);
             % runs all currently implemented view functions

             % turn off gui elements, run in batch
             obj.guiEnabled = 0;

             fxnsToRun = {...
             '=======analysis settings=======',
             'saveObj',
             'modelAddNewFolders',
             'setMainSettings',
             'setStimulusSettings'
             'modelGetFileInfo',
             'modelVerifyDataIntegrity',
             'initializeObj',
             '=======preprocess=======',
             'modelDownsampleRawMovies',
             'modelPreprocessMovie',
             'modelExtractSignalsFromMovie',
             '=======',
             'modelVarsFromFiles',
             '=======signal sorting=======',
             'computeManualSortSignals',
             'modelModifyRegionAnalysis',
             'computeClassifyTrainSignals',
             '=======preprocess verification=======',
             'viewMovie',
             'viewSubjectMovieFrames'
             'viewMovieCreateSideBySide',
             'viewMovieCreateSignalBasedStimTrig',
             'viewCreateObjmaps',
             'viewSignalStats',
             '=======discrete analysis: compute=======',
             'computeDiscreteAlignedSignal',
             'computeSpatioTemporalClustMetric',
             'computeDiscreteDimReduction',
             'computeDiscreteStimulusDecoder',
             'computeDiscreteRateStats',
             'computePopulationDistance',
             'computeTrialSpecificActivity',
             '=======across session analysis: compute/view=======',
             'computeMatchObjBtwnTrials',
             'computeAcrossTrialSignalStimMetric',
             'viewMatchObjBtwnSessions',
             '=======continuous analysis: compute=======',
             'computeContinuousAlignedSignal',
             'viewContinuousSignalVideo',
             '=======discrete analysis: save=======',
             'modelSaveSummaryStats',
             'modelSaveDetailedStats'
             '=======discrete analysis: view=======',
             'viewMovieCreateSignalBasedStimTrig',
             'viewCreateObjmaps',
             'viewStimTrigTraces',
             'viewObjmapStimTrig',
             'viewStimTrig',
             'viewCorr',
             'viewChartsPieStimTrig',
             'viewObjmapSignificant',
             'viewSpatioTemporalMetric',
             'viewPlotSignificantPairwise',
             'viewObjmapSignificantPairwise',
             'viewObjmapSignificantAllStims'
             };
             scnsize = get(0,'ScreenSize');
             [idNumIdxArray, ok] = listdlg('ListString',fxnsToRun,'ListSize',[scnsize(3)*0.3 scnsize(4)*0.8],'Name','functions to run?');
             if ok==0
                 return
             end

             fxnsToRun = {fxnsToRun{idNumIdxArray}};

             usrIdxChoiceStr = {'PCAICA','EM'};
             [sel, ok] = listdlg('ListString',usrIdxChoiceStr);
             usrIdxChoiceList = {2,1};
             obj.signalExtractionMethod = usrIdxChoiceStr{sel};

             excludeList = {'setMainSettings','modelAddNewFolders','saveObj','setStimulusSettings','modelDownsampleRawMovies','viewSubjectMovieFrames'};
             if ~isempty(obj.inputFolders)&isempty(intersect(fxnsToRun,excludeList))
                if isempty(obj.protocol)
                    obj.modelGetFileInfo();
                end
                scnsize = get(0,'ScreenSize');
                folderNumList = strsplit(num2str(1:length(obj.inputFolders)),' ');
                selectList = strcat(folderNumList(:),'/',num2str(length(obj.inputFolders)),' | ',obj.date(:),' _ ',obj.protocol(:),' _ ',obj.fileIDArray(:),' | ',obj.inputFolders(:));
                % set(0, 'DefaultUICOntrolFontSize', 16)

                % select subjects to analyze
                subjectStrUnique = unique(obj.subjectStr);
                [subjIdxArray, ok] = listdlg('ListString',subjectStrUnique,'ListSize',[scnsize(3)*0.3 scnsize(4)*0.8],'Name','which subjects to analyze?');
                subjToAnalyze = subjectStrUnique(subjIdxArray);
                subjToAnalyze = find(ismember(obj.subjectStr,subjToAnalyze));
                % get assays to analyze
                assayStrUnique = unique(obj.assay(subjToAnalyze));
                [assayIdxArray, ok] = listdlg('ListString',assayStrUnique,'ListSize',[scnsize(3)*0.3 scnsize(4)*0.8],'Name','which assays to analyze?');
                assayToAnalyze = assayStrUnique(assayIdxArray);
                assayToAnalyze = find(ismember(obj.assay,assayToAnalyze));
                % filter for folders chosen by the user
                validFoldersIdx = intersect(subjToAnalyze,assayToAnalyze);
                % if isempty(validFoldersIdx)
                %     continue;
                % end

                useAltValid = 0;
                switch useAltValid
                    case 1
                        validFoldersIdx2 = [];
                        for folderNo = 1:length(obj.dataPath)
                            filesToLoad = getFileList(obj.dataPath{folderNo},'_ICfilters.mat');
                            if isempty(filesToLoad)
                                display(['missing ICs: ' obj.dataPath{folderNo}])
                                validFoldersIdx2(end+1) = folderNo;
                            end
                        end
                        validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2)
                    case 2
                        validFoldersIdx2 = [];
                        for folderNo = 1:length(obj.dataPath)
                            filesToLoad = getFileList(obj.dataPath{folderNo},'crop');
                            if isempty(filesToLoad)
                                validFoldersIdx2(end+1) = folderNo;
                                display(['missing dfof: ' obj.dataPath{folderNo}])
                            end
                        end
                        validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2)
                    case 3
                        validFoldersIdx = find(cell2mat(cellfun(@isempty,obj.validAuto,'UniformOutput',0)));
                    otherwise
                        % body
                end

                [fileIdxArray, ok] = listdlg('ListString',selectList,'ListSize',[scnsize(3)*0.9 scnsize(4)*0.8],'Name','which folders to analyze?','InitialValue',validFoldersIdx);
                if ok==0
                    return
                end
                obj.foldersToAnalyze = fileIdxArray;

                if isempty(obj.stimulusNameArray)
                    obj.discreteStimuliToAnalyze = [];
                else
                    [idNumIdxArray, ok] = listdlg('ListString',obj.stimulusNameArray,'ListSize',[scnsize(3)*0.3 scnsize(4)*0.8],'Name','which stimuli to analyze?');
                    if ok==0
                        return
                    end
                    obj.discreteStimuliToAnalyze = idNumIdxArray;
                end

                % set(0, 'DefaultUICOntrolFontSize', 12)
             end

             close all;clc
             for thisFxn=fxnsToRun
                try
                     display(repmat('!',1,21))
                     thisFxn{1}
                     obj.(thisFxn{1});
                 catch err
                    display(repmat('@',1,7))
                    disp(getReport(err,'extended','hyperlinks','on'));
                    display(repmat('@',1,7))
                    restoredefaultpath;
                    loadBatchFxns();
                    cd(obj.defaultObjDir);
                 end
             end
             obj.guiEnabled = 1;
             obj.foldersToAnalyze = [];

             % set back to initial directory in case exited early
             % restoredefaultpath;
             % loadBatchFxns();
             cd(obj.defaultObjDir);

        end

        function GetSize(obj)
            props = properties(obj);
            totSize = 0;
            for ii=1:length(props)
                currentProperty = getfield(obj, char(props(ii)));
                s = whos('currentProperty');
                totSize = totSize + s.bytes;
            end
            fprintf(1, '%d bytes\n', totSize);
        end
       % save the current object instance
        function obj = saveObj(obj)

            if isempty(obj.objSaveLocation)
                [filePath,folderPath,~] = uiputfile('*.*','select text file that points to analysis folders','behaviorAnalysis_properties.mat');
                % exit if user picks nothing
                % if folderListInfo==0; return; end
                savePath = [folderPath filesep filePath];
                % tmpObj = obj;
                % obj = struct(obj);
                obj.objSaveLocation = savePath;
            else
                savePath = obj.objSaveLocation;
            end
            display(['saving to: ' savePath])
            save(savePath,'obj','-v7.3');
            % obj = tmpObj;
        end

        function obj = initializeObj(obj)
            % load dependencies.
            loadBatchFxns();
            % if use puts in a single folder or a path to a txt file with folders
            if ~isempty(obj.rawSignals)&strcmp(class(obj.rawSignals),'char')
                if isempty(regexp(obj.rawSignals,'.txt'))&exist(obj.rawSignals,'dir')==7
                    % user just inputs a single directory
                    obj.rawSignals = {obj.rawSignals};
                else
                    % user input a file linking to directories
                    fid = fopen(obj.rawSignals, 'r');
                    tmpData = textscan(fid,'%s','Delimiter','\n');
                    obj.rawSignals = tmpData{1,1};
                    fclose(fid);
                end
                obj.inputFolders = obj.rawSignals;
                obj.dataPath = obj.rawSignals;
            end
            % add subject information to object given datapath
            if ~isempty(obj.dataPath)
                obj.modelGetFileInfo();
            else
                warning('Input data paths for all files!!! option: dataPath')
            end
            if ~isempty(obj.discreteStimulusTable)&~strcmp(class(obj.discreteStimulusTable),'table')
                obj.modelReadTable('table','discreteStimulusTable');
                obj.modelTableToStimArray('table','discreteStimulusTable','tableArray','discreteStimulusArray','nameArray','stimulusNameArray','idArray','stimulusIdArray','valueName',obj.stimulusTableValueName,'frameName',obj.stimulusTableFrameName);
            end
            if ~isempty(obj.continuousStimulusTable)&~strcmp(class(obj.continuousStimulusTable),'table')
                obj.delimiter = ',';
                obj.modelReadTable('table','continuousStimulusTable','addFileInfoToTable',1);
                obj.delimiter = ',';
                obj.modelTableToStimArray('table','continuousStimulusTable','tableArray','continuousStimulusArray','nameArray','continuousStimulusNameArray','idArray','continuousStimulusIdArray','valueName',obj.stimulusTableValueName,'frameName',obj.stimulusTableFrameName,'grabStimulusColumnFromTable',1);
            end
            % load behavior tables
            if ~isempty(obj.behaviorMetricTable)&~strcmp(class(obj.behaviorMetricTable),'table')
                obj.modelReadTable('table','behaviorMetricTable');
                obj.modelTableToStimArray('table','behaviorMetricTable','tableArray','behaviorMetricArray','nameArray','behaviorMetricNameArray','idArray','behaviorMetricIdArray','valueName','value');
            end
            % modify stimulus naming scheme
            if ~isempty(obj.stimulusNameArray)
                obj.stimulusSaveNameArray = obj.stimulusNameArray;
                obj.stimulusNameArray = strrep(obj.stimulusNameArray,'_',' ');
            end
            % load all the data
            if ~isempty(obj.rawSignals)&strcmp(class(obj.rawSignals{1}),'char')
                display('paths input, going to load files')
                obj.guiEnabled = 0;
                obj = modelVarsFromFiles(obj);
                obj.guiEnabled = 1;
            end
            % check if signal peaks have already been calculated
            if isempty(obj.signalPeaks)&~isempty(obj.rawSignals)
                % obj.computeSignalPeaksFxn();
            else
                warning('no signal data input!!!')
            end
            % load stimulus tables
        end
    end
end