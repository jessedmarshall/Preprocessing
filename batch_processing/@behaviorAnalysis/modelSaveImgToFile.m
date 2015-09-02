function obj = modelSaveImgToFile(obj,saveFile,thisFigName,thisFigNo,thisFileID)
	% saves the current open figure to a file
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
	try
		if ~isempty(thisFigName)
			% thisFigName = 'stimTriggeredPerCell_'
			if obj.dfofAnalysis==1
				% signalPeaks = IcaTraces;
				tmpDirPath = strcat(obj.picsSavePath,filesep,thisFigName,'_dfof_',filesep);
			else
				tmpDirPath = strcat(obj.picsSavePath,filesep,thisFigName,filesep);
			end
			if (~exist(tmpDirPath,'dir')) mkdir(tmpDirPath); end;
			if isempty(thisFileID)
				thisFileID = obj.fileIDArray{obj.fileNum};
			end
			saveFile = strcat(tmpDirPath,filesep,thisFileID);
			% saveFile = char(strrep(strcat(tmpDirPath,thisFileID),filesep,''));
			% saveFile
			if strcmp(class(thisFigNo),'char')&strcmp(thisFigNo,'current')

			else
				set(thisFigNo,'PaperUnits','inches','PaperPosition',[0 0 20 20])
				figure(thisFigNo)
			end
		end

		if strcmp(class(obj.imgSaveTypes),'char')
			obj.imgSaveTypes = {obj.imgSaveTypes};
		end
		% export_fig(sprintf('%s', saveFile), '-eps');
		% export_fig(saveFile '-eps'
		display(['saving img: ' saveFile])
		for imgType = 1:length(obj.imgSaveTypes)
			print(obj.imgSaveTypes{imgType},'-r100',saveFile)
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end