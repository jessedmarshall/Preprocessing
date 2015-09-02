function obj = modelSaveViewFigures(obj)
	% DESCRIPTION
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

	for i=1:length(figNames)
		tmpDirPath = strcat(options.picsSavePath,filesep,figNames{i},filesep);
		if (~exist(tmpDirPath,'dir')) mkdir(tmpDirPath); end;
		saveFile = char(strrep(strcat(tmpDirPath,thisFileID,''),'/',''));
		saveFile
		set(figNo{i},'PaperUnits','inches','PaperPosition',[0 0 15 15])
		figure(figNo{i})
		print('-dpng','-r200',saveFile)
		print('-dmeta','-r200',saveFile)
		close(figNo{i})
	end

end