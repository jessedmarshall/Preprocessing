function [obj] = modelTableToStimArray(obj,varargin)
	% converts table to a stimulus array to reduce memory footprint
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2015.02.12 - facet by subject, then use the same table for each stimuli to make it faster.
	% TODO
		%
	%========================
	% which
	options.table = 'discreteStimulusTable';
	% where to store the array
	options.tableArray = 'discreteStimulusArray';
	% property names of name-id pairs
	options.nameArray = 'stimulusNameArray';
	options.idArray = 'stimulusIdArray';
	% table name to use as final value in array
	options.valueName = 'frame';
	%
	options.timeName = 'time';
	options.frameName = 'frameSession';
	options.trialName = 'trial';
	% should stimulus name be grabbed from column instead of options.valueName?
	options.grabStimulusColumnFromTable = 0;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if strcmp(obj.analysisType,'group')
		nFiles = length(obj.rawSignals);
	else
		nFiles = 1;
	end

	nameArray = obj.(options.nameArray);
	idArray = obj.(options.idArray);
	assayTable = obj.(options.table);

	% constants for table organization
	timeName = options.timeName;
	frameName = options.frameName;
	trialName = options.trialName;

	subjectName = 'subject';
	usTimeAfterCS = 10;
	framesPerSecond = obj.FRAMES_PER_SECOND;

	display('converting table to array...')
	for thisFileNum = 1:nFiles
		% display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.dataPath{thisFileNum}]);
		obj.fileNum = thisFileNum;

		if strmatch('#',obj.dataPath{obj.fileNum})
			display([num2str(obj.fileNum) '/' num2str(nFiles) ' | skipping: ' obj.dataPath{obj.fileNum}]);
			continue;
		else
			display([num2str(obj.fileNum) '/' num2str(nFiles) ': ' obj.dataPath{obj.fileNum}]);
		end


		subjectNum = obj.subjectNum{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		assayNum = obj.assayNum{obj.fileNum};
		nIDs = length(idArray);

		% =============
		% fix for assay notation differences, remove leading 0 from all strings
		% if strfind(assay,'10')
		% case invariant
		if assayNum>=10
			assayIdx = strcmpi(assay,assayTable.(trialName));
		else
			assayIdx = strcmpi(strrep(assay,'0',''),strrep(assayTable.(trialName),'0',''));
		end
		subjIdx = assayTable.(subjectName)==subjectNum;
		filterIdx = find(assayIdx&subjIdx);
		subjectTable = assayTable(filterIdx,:);
		% subjectTable(1:10,:)
		% =============
		for idNum = 1:nIDs
			try
				%
				if strcmp(class(idArray),'cell')
					thisID = idArray{idNum};
				else
					thisID = idArray(idNum);
				end
				% obtain the table containing information about the subject and trial
				if options.grabStimulusColumnFromTable==1
					% Used to grab an entire stimulus from column, e.g. in the case of tracking.
					obj.(options.tableArray){obj.fileNum}.(strrep(['s' num2str(thisID)],' ','_')) = subjectTable.(nameArray{idNum});
				else
					eventsIdx = ismember(subjectTable.events,thisID);
					% filterIdx = find(eventsIdx&assayIdx&subjIdx);
					subjectTableID = subjectTable(eventsIdx,:);
					if ~any(strcmp(frameName,fieldnames(subjectTableID)))&any(strcmp(timeName,fieldnames(subjectTableID)))
					    subjectTableID.(frameName) = round(subjectTableID.(timeName)*framesPerSecond);
					end
					obj.(options.tableArray){obj.fileNum}.(strrep(['s' num2str(thisID)],' ','_')) = subjectTableID.(options.valueName);
				end

				if isempty(filterIdx)
					display(['no stimuli: ' nameArray{idNum}])
				else
					if options.grabStimulusColumnFromTable==1
						display(['table->array for stimuli: ' nameArray{idNum}])
					else
						display(['table->array for stimuli: ' nameArray{idNum} ', ' num2str(length(subjectTableID.(options.valueName)))])
					end
				end
			catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
			end
		end
	end
	% reset file counter
	obj.fileNum = 1;
	% remove table to save space
	display('removing stimulus table to save space...')
	obj.(options.table) = {};
end