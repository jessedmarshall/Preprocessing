function obj = viewChartsPieStimTrig(obj)
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
	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();

	for thisFileNumIdx = 1:nFilesToAnalyze
		thisFileNum = fileIdxArray(thisFileNumIdx);
		obj.fileNum = thisFileNum;
		display(repmat('=',1,21))
		display([num2str(thisFileNum) '/' num2str(nFiles) ': ' obj.fileIDNameArray{obj.fileNum}]);
		% ============================
		[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
		nIDs = length(obj.stimulusNameArray);
		nSignals = size(IcaTraces,1);
		if isempty(IcaFilters);continue;end;
		%
		nameArray = obj.stimulusNameArray;
		%
		sigModSignals = obj.sigModSignals{obj.fileNum};
		%
		subject = obj.subjectNum{obj.fileNum};
		assay = obj.assay{obj.fileNum};
		subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
		%
		figNoAll = obj.figNoAll;
		figNo = obj.figNo;
		figNames = obj.figNames;
		% ============================
		idNumCounter = 1;
		for idNum = 1:nIDs
			try
				figNames{figNoAll} = 'stimTriggeredAvg_MIpiecharts_';
			 	[figNo{figNoAll}, ~] = openFigure(figNoAll, '');
			        if idNumCounter==1
						suptitle([subjAssayIDStr ' | % mutually informative cells',10,10])
					end
					[xPlot yPlot] = getSubplotDimensions(nIDs+1);
					pieNums = [sum(sigModSignals)/nSignals sum(~sigModSignals)/nSignals];
			        subplot(xPlot,yPlot,idNum)
			            pieLabels = {'significant','not-significant'};
			            h = pie(pieNums,pieLabels);
			            % adjPieLabels(h);
			            title([nameArray{idNum}]);
			            % title(['2\sigma significance threshold']);
            catch err
            	display(repmat('@',1,7))
            	disp(getReport(err,'extended','hyperlinks','on'));
            	display(repmat('@',1,7))
            end
		end
		obj.modelSaveImgToFile([],'stimTrigAvg_SigPiecharts_','current',[]);
		% close(figNoAll);

		% obj.figNoAll = obj.figNoAll + 1;
		obj.figNo = figNo;
		obj.figNames = figNames;
	end
end