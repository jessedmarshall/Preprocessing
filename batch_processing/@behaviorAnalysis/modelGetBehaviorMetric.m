function [behaviorMetric] = modelGetBehaviorMetric(obj,inputID)
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

	behaviorMetric = obj.discreteStimulusArray{obj.fileNum}.(['s' num2str(inputID)]);
	% % check values
	% if isempty(stimFrames)
	% 	display(['no stimuli in trial, skipping...'  obj.stimulusNameArray{obj.stimNum}]);
	% 	stimVector = [];
	% 	return;
	% else
	% 	display('loaded trial stimulus data')
	% end
	% nTrialPts = size(obj.rawSignals{obj.fileNum},2);
	% stimVector = zeros(1,nTrialPts);
	% stimVector(stimFrames) = 1;
	% display('created stimulus vector')