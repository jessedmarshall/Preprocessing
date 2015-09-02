function [obj] = modelEditStimTable(obj,varargin)
	% read in table, decides whether to do a single or multiple tables
	% if multiple tables, should have the same column names
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		% Add in the ability to say whether the animal had a behavioral response

	obj.behaviorMetricTable = 'D:\b\Dropbox\schnitzer\data\behavior\p330\2015_05_20_p330_m723_preSNI03__cleaned.csv';
	behaviorMetricTablePath = obj.behaviorMetricTable;
	tableInfo = getFileInfo(behaviorMetricTablePath);
	videoTrialRegExp = [tableInfo.date '_' tableInfo.protocol '_' tableInfo.subject '_' tableInfo.assay];
	usrIdxChoice = inputdlg('enter video directory (use comma to split multiple)','video dir',1,{'D:\'});
	obj.videoDir = strsplit(usrIdxChoice{1},',');
	videoDir = obj.videoDir;

	obj.modelReadTable('table','behaviorMetricTable');
	behaviorMetricTable = obj.behaviorMetricTable;

	vidList = getFileList(videoDir,videoTrialRegExp);
	cellfun(@display,vidList)
	if ~isempty(vidList)
		Miji;
		% MIJ.start;
		% if strcmp(options.videoPlayer,'imagej')
		% 	% MIJ.exit;
		% end

		numStims = size(behaviorMetricTable,1);
		stimRange = [-20:20];
		midStimRange = ceil(length(stimRange)/2);
		stimulusRemoveNo = [];
		% behaviorMetricTable
		for stimNo = 1:numStims
			thisStimFrame = behaviorMetricTable(stimNo,:).frameSession;
			thisStimFrameIdx = stimRange+thisStimFrame;
			% get the movie
			primaryMovie = loadMovieList(vidList,'convertToDouble',0,'frameList',thisStimFrameIdx,'treatMoviesAsContinuous',1);

			MIJ.createImage('result', primaryMovie, true);
			MIJ.setSlice(midStimRange);
			clear primaryMovie;

			userResponse = questdlg([num2str(stimNo) '/' num2str(numStims) ': press OK to move onto next step'],'Boundary Condition','Yes','No','Delete Stimulus','Yes');

			% grab frame number where stimulus is
			MIJ.run('Measure');
			resultTable = MIJ.getResultsTable;
			stimFrame = resultTable(end);
			MIJ.run('Clear Results');MIJ.run('Close');
			MIJ.run('Close');
			% usrIdxChoice = inputdlg([num2str(stimNo) '/' num2str(numStims) ': enter frame in movie with stimulus (blank for default, -1 to exit)']);

			if strcmp(userResponse,'Delete Stimulus')
				stimulusRemoveNo(end+1) = stimNo;
			end

			behaviorMetricTable(stimNo,:)
			% stimFrame = str2num(usrIdxChoice{1});
			if stimFrame==-1|strcmp(userResponse,'No')
				% MIJ.run('Close');
			    break
				% return
			end
			frameDiff = (stimFrame-midStimRange);
			behaviorMetricTable(stimNo,:).frameTrial = behaviorMetricTable(stimNo,:).frameTrial+frameDiff;
			behaviorMetricTable(stimNo,:).frameSession = behaviorMetricTable(stimNo,:).frameSession+frameDiff;
			behaviorMetricTable(stimNo,:).frameSessionDownsampled = behaviorMetricTable(stimNo,:).frameSessionDownsampled+round(frameDiff/4);

			behaviorMetricTable(stimNo,:)
		end

		% remove stimuli user requests to delete
		if ~isempty(stimulusRemoveNo)
			behaviorMetricTable(stimulusRemoveNo,:) = [];
		end

	    savePath = behaviorMetricTablePath;
	    [PATHSTR,NAME,EXT] = fileparts(savePath);
	    PATHSTR = [PATHSTR filesep 'userCleaned' filesep];
	    mkdir(PATHSTR);
	    savePath = [PATHSTR NAME '.' EXT];
	    display(['saving data to: ' savePath])
		writetable(behaviorMetricTable,savePath,'FileType','text','Delimiter',',');

		MIJ.exit;
	else
		% [primaryMovie] = loadMovieList(movieList{movieMontageIdx(movieNo)},'convertToDouble',0,'frameList',frameList(:));
	end

end