function [stimVector] = modelGetStim(obj,inputID,varargin)
	% compute peaks for all signals if not already input
	% biafra ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	% which table to read in
	options.array = 'discreteStimulusArray';
	options.nameArray = 'stimulusNameArray';
	options.idArray = 'stimulusIdArray';
	options.stimFramesOnly = 0;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		if strcmp(class(inputID),'cell')
			inputID = cell2mat(inputID);
		end
		if any(strcmp(strrep(['s' num2str(inputID)],' ','_'),fieldnames(obj.(options.array){obj.fileNum})))
			stimFrames = obj.(options.array){obj.fileNum}.(strrep(['s' num2str(inputID)],' ','_'));
		else
			stimVector = [];
		end

		if options.stimFramesOnly==1
			stimVector = stimFrames;
			return;
		end

		% stimIdNum = find(obj.(options.idArray)==inputID);
		stimIdNum = obj.stimNum;
		currentStimulusName = obj.(options.nameArray){stimIdNum};
		% check values
		if isempty(stimFrames)
			display(['no stimuli in trial, skipping...'  currentStimulusName]);
			stimVector = [];
			return;
		else
		end
		% nTrialPts = size(obj.rawSignals{obj.fileNum},2);
		nTrialPts = obj.nFrames{obj.fileNum};
		stimVector = zeros(1,nTrialPts);
		stimVector(stimFrames) = 1;

		if ~isempty(obj.stimTriggerOnset)&strcmp(class(obj.stimTriggerOnset),'cell')
			stimTriggerOnset = obj.stimTriggerOnset{stimIdNum};
			switch stimTriggerOnset
				case 1
					display('getting stim onset')
					stimVectorSpread = spreadSignal(stimVector,'timeSeq',obj.stimulusTimeSeq{stimIdNum});
					stimVectorSpread = diff(stimVectorSpread);
					stimVectorSpread(stimVectorSpread<0) = 0;
					stimVector = [0; stimVectorSpread(:)]';
					% find(ismember(unique(stimFrames),find(stimVector)))
					% find(stimVector)
					figure(stimIdNum)
					plot(unique(stimFrames));hold on;
					plot(find(ismember(unique(stimFrames),find(stimVector))),find(stimVector),'r+');hold off;
					% stimVectorIdx = find()
					% stimVectorIdxCorrected = find(stimVector)+length(obj.stimulusTimeSeq{stimIdNum});
					% stimVector(find(stimVector)) = 0;
					% stimVector(stimVectorIdxCorrected) = 1;
				case -1
					display('getting stim offset')
					stimVectorSpread = spreadSignal(stimVector,'timeSeq',obj.stimulusTimeSeq{stimIdNum});
					stimVectorSpread = diff(stimVectorSpread);
					stimVectorSpread(stimVectorSpread>0) = 0;
					stimVectorSpread(stimVectorSpread<0) = 1;
					stimVector = [0; stimVectorSpread(:)]';
				case -2
					display('getting stim between onset and offset')
					stimVectorIdx = find(stimVector);
					stimVector(stimVectorIdx(2:2:length(stimVectorIdx))) = -1;
					% set all time points between onset and offset to 1
					stimVector = cumsum(stimVector);
				otherwise
					% body
			end
		end
		% find(stimVector)
		% display('created stimulus vector')
		display(['loaded stimulus data: ' currentStimulusName ' | num stim pts: ' num2str(length(find(stimVector)))])
		pause(0.001)
	catch err
		stimVector = [];
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end