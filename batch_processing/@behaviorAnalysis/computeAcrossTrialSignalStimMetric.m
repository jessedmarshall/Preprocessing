function obj = computeAcrossTrialSignalStimMetric(obj)
	% compute a metric for cross session alignment
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
	subjectList = unique({obj.subjectStr{fileIdxArray}});
	obj.detailStats = {};
	for thisSubjectStr=subjectList
		try
			display(repmat('=',1,21))
			thisSubjectStr = thisSubjectStr{1};

			% % thisSubjectStr = thisSubjectStr{1};
			% display([thisSubjectStr]);
			% validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
			% % filter for folders chosen by the user
			% validFoldersIdx = intersect(validFoldersIdx,fileIdxArray);
			% if isempty(validFoldersIdx)
			% 	continue;
			% end

			% [obj.globalIDFolders.(thisSubjectStr){:}]
			% validFoldersIdx
			% validFoldersIdx = validFoldersIdx([obj.globalIDFolders.(thisSubjectStr){:}]);
			% validFoldersIdx
			% globalAssayStr = obj.assay(validFoldersIdx);
			% obj.globalIDFolders.(thisSubjectStr) = globalAssayStr;

			% continue
			% for thisFileNum = 1:nFiles
			% obj.fileNum = thisFileNum;
			% ============================
			% [IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj);
			% IcaFilters = obj.rawImages{obj.fileNum};
			stimulusNameArray = obj.stimulusNameArray(idNumIdxArray);
			saveNameArray = obj.stimulusSaveNameArray;
			idArray = obj.stimulusIdArray;
			nStimIDs = length(stimulusNameArray);
			% nSignals = size(IcaTraces,1);
			% nIDs = length(obj.stimulusNameArray);
			% nSignals = obj.nSignals{obj.fileNum};
			%
			nameArray = obj.stimulusNameArray(idNumIdxArray);
			%
			% subject = obj.subjectStr{obj.fileNum};
			% assay = obj.assay{obj.fileNum};
			% assayType = obj.assayType{obj.fileNum};
			% assayNum = obj.assayNum{obj.fileNum};
			% subjAssayIDStr = obj.fileIDNameArray{obj.fileNum};
			%
			figNoAll = obj.figNoAll;
			figNo = obj.figNo;
			figNames = obj.figNames;
			% [globalIDNum trialNum]
			globalIDs = obj.globalIDs.(thisSubjectStr);
			globalIDFolders = obj.globalIDFolders.(thisSubjectStr);
			%
			sigModSignalsAllTrials = obj.sigModSignals;
			%
			validFoldersIdx = find(strcmp(thisSubjectStr,obj.subjectStr));
			% filter for folders chosen by the user
			validFoldersIdx = intersect(validFoldersIdx,fileIdxArray);
			if isempty(validFoldersIdx)
				continue;
			end
			%
			assayTypeList = unique(obj.assayType(validFoldersIdx));
			%
			assayTypes = obj.assayType;

			% ============================
			plotAllSessionStim();
			% colormap(obj.colormap);
			% pause
			% return
			continue
			% ============================
			% display the distribution
			clear cumProb;
			nGlobalSessions = size(globalIDs,2);
			nGIds = size(globalIDs,1);
			for gID = 1:nGlobalSessions
		        cumProb(gID) = sum(sum(~(globalIDs==0),2)==gID)/nGIds;
		    end
		    figure(1930)
		    plot(((1:nGlobalSessions)/nGlobalSessions)*100,cumProb);
		    title(['distribution of % trials aligned for global cells | ' thisSubjectStr])
		    xlabel('% of trials aligned');ylabel('fraction')
		    box off;
		    obj.modelSaveImgToFile([],'crossSessionAlignmentStat','current',[]);

			nAssayTypes = length(assayTypeList);
			[xPlot yPlot] = getSubplotDimensions(nAssayTypes+1);
			for assayTypeNo = 1:nAssayTypes
				% filter out signals only matched across a single session
				globalIDsIdx = logical(sum(globalIDs~=0,2)~=1);
				globalIDs = globalIDs(globalIDsIdx,:);
				nGlobalIDs = size(globalIDs,1);
				stimMetric = NaN([nGlobalIDs nStimIDs]);
				stimMetricNum = NaN([nGlobalIDs nStimIDs]);
				%
				validAssayIdx = find(strcmp(assayTypeList{assayTypeNo},obj.assayType));
				% filter for folders chosen by the user
				validAssayIdx = intersect(validFoldersIdx,validAssayIdx);
				%
				for globalIdNo = 1:nGlobalIDs
					% thisGlobalIDList = globalIDs(globalIdNo,:);
					idNumCounter = 1;
					for stimNo = idNumIdxArray
						for thisFileNumIdx = 1:length(validAssayIdx)
							thisFileNum = validAssayIdx(thisFileNumIdx);
							obj.fileNum = thisFileNum;
							% find the correct index for globalIDs from globalIDFolders
							% obj.assay(thisFileNum)
							% globalIDFolders
							folderGlobalIdx = find(strcmp(obj.assay(thisFileNum),globalIDFolders));
							% folderGlobalIdx
							% return
							% filter for folders chosen by the user
							% folderGlobalIdx = intersect(validFoldersIdx,folderGlobalIdx);
							% get significant signals and skip session if missing specific data
							if ~strcmp(assayTypeList{assayTypeNo},assayTypes{thisFileNum})
								continue
							end
							sigModSignals = sigModSignalsAllTrials{thisFileNum,stimNo};
							if isempty(sigModSignals)
								continue
							end
							% create a vector of 0s and 1s saying whether signal was significantly modulated by stimulus
							thisID = globalIDs(globalIdNo,folderGlobalIdx);
							if thisID==0
								tmpStimMetric(thisFileNumIdx) = NaN;
							else
								tmpStimMetric(thisFileNumIdx) = double(sigModSignals(thisID));
							end
						end
						% take the mean to get the % of trials signal present that significantly modulated
						if exist('tmpStimMetric','var')
							% tmpStimMetric
							stimMetric(globalIdNo,stimNo) = nanmean(tmpStimMetric);
							stimMetricNum(globalIdNo,stimNo) = nansum(tmpStimMetric);
							clear tmpStimMetric;
						end
					end
				end
				% stimMetric
				[~, ~] = openFigure(46564, '');
				subplot(xPlot,yPlot,assayTypeNo)
				[f,trialsSignificantPct] = hist(stimMetric);
				[f,trialsSignificantNum] = hist(stimMetricNum);
				f2 = f./repmat(sum(f,1),[size(f,1) 1]);
				bar(trialsSignificantPct,f2)
				% bar(trialsSignificantPct,f/trapz(trialsSignificantPct,f));
				title(assayTypeList{assayTypeNo})
				box off;
				xlabel('% of sessions significant')
				ylabel('fraction')
				% legend(stimulusNameArray)

				[~, ~] = openFigure(46564+1, '');
				subplot(xPlot,yPlot,assayTypeNo)
				fractionSignificantCumsum = cumsum(f2,1);
				plot(trialsSignificantPct,fractionSignificantCumsum)
				title(assayTypeList{assayTypeNo})
				box off;
				xlabel('% of sessions significant')
				ylabel('fraction')
				% legend(stimulusNameArray)

				if isempty(obj.detailStats)
					% obj.detailStats = {};
	        	    obj.detailStats.trialsSignificantPct = [];
	        	    obj.detailStats.trialsSignificantNum = [];
	        	    obj.detailStats.fractionSignificant = [];
	        	    obj.detailStats.varType = {};
	                obj.detailStats.varType2 = {};
	        	    obj.detailStats.subject = {};
	        	    % obj.detailStats.assay = {};
	        	    obj.detailStats.assayType = {};
	        	    % obj.detailStats.assayNum = {};
	        	end
        		varType = stimulusNameArray;
        	    valueArray = {f2,fractionSignificantCumsum};
        	    varType2Array = {'distribution','cumsum'};
        	    for varNo1 = 1:length(varType)
					for varNo2 = 1:length(varType2Array)
		            	numPtsToAdd = length(trialsSignificantPct(:));
		            	obj.detailStats.trialsSignificantPct(end+1:end+numPtsToAdd,1) = trialsSignificantPct(:);
		            	obj.detailStats.trialsSignificantNum(end+1:end+numPtsToAdd,1) = trialsSignificantNum(:);
		            	% obj.detailStats.value(end+1:end+numPtsToAdd,1) = value(:);
		                obj.detailStats.fractionSignificant(end+1:end+numPtsToAdd,1) = valueArray{varNo2}(:,varNo1);
		            	obj.detailStats.varType(end+1:end+numPtsToAdd,1) = {varType{varNo1}};
		                obj.detailStats.varType2(end+1:end+numPtsToAdd,1) = {varType2Array{varNo2}};
		            	obj.detailStats.subject(end+1:end+numPtsToAdd,1) = {thisSubjectStr};
		            	% obj.detailStats.assay(end+1:end+numPtsToAdd,1) = {assay};
		            	obj.detailStats.assayType(end+1:end+numPtsToAdd,1) = {assayTypeList{assayTypeNo}};
		            	% obj.detailStats.assayNum(end+1:end+numPtsToAdd,1) = {assayNum};
		            end
		        end
			end

			% MAKE LEGEND IN SEPARATE SUBPLOT
			[~, ~] = openFigure(46564, '');
			subplot(xPlot,yPlot,nAssayTypes+1)
			bar(trialsSignificantPct,f2);box off; axis off;
			h = legend(stimulusNameArray,'Location','north')
			legend('boxoff')
			set(h,'color','w')
			title('legend plot')
			[~, ~] = openFigure(46564+1, '');
			subplot(xPlot,yPlot,nAssayTypes+1)
			trialsSignificantPct(2:(end-1),:) = NaN;
			f2(2:(end-1),:) = NaN;
			plot(trialsSignificantPct,f2);box off; axis off;
			h = legend(stimulusNameArray,'Location','north')
			legend('boxoff')
			set(h,'color','w')
			title('legend plot')

			suptitle([obj.subjectStr{obj.fileNum} ' | ' num2str(nFiles) ' trials | ' num2str(nGlobalIDs) ' global cells, cells must be matched across >1 trials ' 10 '% of trials matched cells significantly modulated by stimuli'])

			obj.modelSaveImgToFile([],'reliability','current',[]);

			obj.globalStimMetric = stimMetric;
			% end
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end

		% write out summary statistics
		savePath = [obj.dataSavePath obj.protocol{obj.fileNum} '_acrossSessionReliability.tab'];
		display(['saving data to: ' savePath])
		writetable(struct2table(obj.detailStats),savePath,'FileType','text','Delimiter','\t');
		% pause
	end
	function plotAllSessionStim()
		% ============================
		% display all signals activity across sessions aligned
		% nStims = sum(stimVector);
		nGlobalSessions = size(globalIDs,2);
		nGlobalIDs = size(globalIDs,1);
		timeSeq = -20:20;
		lenTimeSeq = length(timeSeq);
		% get the aligned signal, sum over all input signals
		sortGlobalTrials = zeros([1 length(idNumIdxArray)]);
		%
		globalStimIdx = {};
		for globalFolderNo = 1:length(globalIDFolders)
			display('---')
			display(globalIDFolders{globalFolderNo})
			folderGlobalIdx = find(strcmp(globalIDFolders{globalFolderNo},obj.assay));
			validFoldersIdxTmp = intersect(validFoldersIdx,folderGlobalIdx);
			if isempty(validFoldersIdxTmp); continue; end;
			validFoldersIdxTmp
			obj.fileNum = validFoldersIdxTmp;
			options.regexPairs = {...
				% {'_ICfilters_sorted.mat','_ICtraces_sorted.mat'},...
				{'holding.mat','holding.mat'},...
				{obj.rawICfiltersSaveStr,obj.rawICtracesSaveStr},...
				{obj.rawEMStructSaveStr},...
			};
			[IcaTraces IcaFilters signalPeaks signalPeaksArray] = modelGetSignalsImages(obj,'returnType','filtered','regexPairs',{{'holding.mat','holding.mat'},
				{obj.rawICtracesSaveStr}});
			for stimNoIdx = 1:length(idNumIdxArray)
				stimNo = idNumIdxArray(stimNoIdx);
				globalStimIdx{stimNo}{globalFolderNo} = obj.fileNum;
				alignTmp = zeros([nGlobalIDs lenTimeSeq]);
				alignSignalStim{stimNo}{globalFolderNo} = alignTmp;
				obj.stimNum = stimNo;
				stimVector = obj.modelGetStim(idArray(stimNo));
				if isempty(stimVector); continue; end;
				% size(alignTmp)
				% size(alignSignal(signalPeaks,stimVector,timeSeq)')
				alignTmp(1:size(signalPeaks,1),1:lenTimeSeq) = alignSignal(signalPeaks,stimVector,timeSeq)';
				% alignTmp(:,:) = alignSignal(signalPeaks,stimVector,timeSeq)';
					localGlobalIDs = globalIDs(:,globalFolderNo);
					localGlobalIDsTmp = localGlobalIDs;
					localGlobalIDsTmp(localGlobalIDsTmp==0) = 1;
					alignTmp = alignTmp(localGlobalIDsTmp,:);
					localGlobalIDs = localGlobalIDs==0;
					% remove irrelevant rows
					alignTmp(localGlobalIDs,:) = 0;
				if sortGlobalTrials(stimNoIdx)==0&sum(alignTmp(:))>0&0
					% size(alignTmp)
					alignSignalAllSum = sum(alignTmp(:,(round(end/2)+7:end)),2);
					alignSignalAllSum2 = sum(alignTmp(:,(round(end/2):(round(end/2)+7))),2);
					% size(alignSignalAllSum)
					% size(alignSignalAllSum2)
					sortMetric = alignSignalAllSum-alignSignalAllSum2;
					% size(sortMetric)
					[responseN reponseScoreIdx{stimNo}] = sort(sortMetric,'ascend');
					% signalPeaksTwoSorted = signalPeaksTwo(reponseScoreIdx,:);
					sortGlobalTrials(stimNoIdx) = 1;
				end
				alignSignalStim{stimNo}{globalFolderNo} = alignTmp;
			end
		end
		alignSignalStimImages = {};
		% figure(2929292)
		% assayTypeList = unique(obj.assayType);
		sessionTypeIndicatorHeight = 10;
		sessionTypeColors = hsv(length(assayTypeList));
		alignImgTmpAll = zeros([size(cat(2,alignSignalStim{idNumIdxArray(1)}{:}))]);
		alignImgTmpAll = [zeros([2*sessionTypeIndicatorHeight size(alignImgTmpAll,2)]);alignImgTmpAll];
		nStimAnalyze = length(idNumIdxArray);
		for stimNoIdx = 1:nStimAnalyze
			stimNo = idNumIdxArray(stimNoIdx);
			display('**************')
			if stimNoIdx==1
				% sortMetricAll = cellfun(@(x) sum(x(:,(round(end/2)-5):round(end/2)),2)-sum(x(:,round(end/2):(round(end/2)+5)),2),alignSignalStim{stimNo},'UniformOutput',0);
				sortMetricAll = cellfun(@(x)...
				 sum(...
				 	x(:,(round(end/2)-15):round(end/2)),2)...
				 -sum(x(:,round(end/2):(round(end/2)+15)),2),...
				 alignSignalStim{stimNo},'UniformOutput',0);
				sortMetricAll = nansum(cat(2,sortMetricAll{:}),2);

				% alignSignalAllSum = sum(alignSignalAll(((round(end/2)-7)):round(end/2),:),1);
				% alignSignalAllSum2 = sum(alignSignalAll((round(end/2):(round(end/2)+7)),:),1);
				% sortMetric = alignSignalAllSum-alignSignalAllSum2;
			end
			[responseN reponseScoreIdx{stimNo}] = sort(sortMetricAll,'descend');
			% reponseScoreIdx{stimNo}'

			cellfun(@(x) num2str(size(x)),alignSignalStim{stimNo},'UniformOutput',0)'
			try
				cell2mat(globalStimIdx{stimNo})
				% alignSignalStim{stimNo} = addText(alignSignalStim{stimNo},saveNameArray(cell2mat(globalStimIdx{stimNo})));
				alignSignalStimImages{stimNo} = cat(2,alignSignalStim{stimNo}{:});
			catch err
				display(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				display(repmat('@',1,7))
				continue
			end
			alignImgTmp = alignSignalStimImages{stimNo};
			% reponseScoreIdx{stimNo}
			alignImgTmp = alignImgTmp(reponseScoreIdx{stimNo},:);
			alignImgTmp = [zeros([2*sessionTypeIndicatorHeight size(alignImgTmp,2)]);alignImgTmp];
			% subplot(length(idNumIdxArray),1,stimNoIdx);
			[figHandle ~] = openFigure(2929292+stimNoIdx, '');
				% size(alignImgTmp)
				imagesc(alignImgTmp==0)
				plotAcrossSessionStim()

			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 20 10])
			% obj.modelSaveImgToFile([],['crossSessionAlignmentActivity' filesep saveNameArray{idNumIdxArray(stimNoIdx)}],'current',thisSubjectStr);
			obj.modelSaveImgToFile([],['crossSessionAlignActivity'],'current',[thisSubjectStr '_' saveNameArray{idNumIdxArray(stimNoIdx)}]);

			% [figHandle ~] = openFigure(789, '');
			% 	subplot(length(idNumIdxArray),1,stimNoIdx)
			% 	plotAcrossSessionStim()
			% set(gcf,'PaperUnits','inches','PaperPosition',[0 0 20 10])
			% obj.modelSaveImgToFile([],['crossSessionAlignActivityAll'],'current',[thisSubjectStr]);
			alignImgTmp2 = alignImgTmp~=0;
			alignImgTmpAll = alignImgTmpAll+stimNoIdx*alignImgTmp2;
			if stimNoIdx==1
				Comb(:,:,1) = ~(alignImgTmp2==80);
				Comb(:,:,2) = ~(alignImgTmp2==80);
				Comb(:,:,3) = ~(alignImgTmp2==80);
				display(num2str([min(Comb(:)) max(Comb(:))]))
			end

			display(num2str([min(alignImgTmp2(:)) max(alignImgTmp2(:))]))
			switch stimNoIdx
				case 1
					%red
					Comb(:,:,2) = Comb(:,:,2)-1.0*alignImgTmp2;
					Comb(:,:,3) = Comb(:,:,3)-1.0*alignImgTmp2;
				case 2
					%blue
					Comb(:,:,1) = Comb(:,:,1)-1.0*alignImgTmp2;
					Comb(:,:,2) = Comb(:,:,2)-1.0*alignImgTmp2;
				case 3
					%green
					Comb(:,:,1) = Comb(:,:,2)-1.0*alignImgTmp2;
					Comb(:,:,3) = Comb(:,:,2)-1.0*alignImgTmp2;
				case 4
					Comb(:,:,1) = Comb(:,:,1)-1.0*alignImgTmp2; %red
					Comb(:,:,3) = Comb(:,:,3)-1.0*alignImgTmp2; %blue
				case 5
					Comb(:,:,2) = Comb(:,:,2)-1.0*alignImgTmp2; %green
					Comb(:,:,3) = Comb(:,:,3)-1.0*alignImgTmp2; %blue
				otherwise
					% body
			end
			display(num2str([min(Comb(:)) max(Comb(:))]))
		end
		display('**************')
		display(num2str([min(Comb(:)) max(Comb(:))]))
		[figHandle ~] = openFigure(789, '');
			alignImgTmp = alignImgTmpAll;
			% imagesc(alignImgTmp)
			imagesc(Comb)
			plotAcrossSessionStim();
			% colormap([1 1 1; lines(nStimAnalyze)])
			% cb = colorbar('location','southoutside'); ylabel(cb, 'Hz');
			% colormap([hsv(nStimAnalyze);1 1 1])
			set(gcf,'PaperUnits','inches','PaperPosition',[0 0 25 10])
			obj.modelSaveImgToFile([],['crossSessionAlignActivityAll'],'current',[thisSubjectStr]);
		function plotAcrossSessionStim()
			colormap gray
			xlabel('relative to stimulus (seconds)')
			ylabel('cells')
			% set(gca,'XTick',[],'YTick',[])

			M = size(alignImgTmp,1);
			N = size(alignImgTmp,2);
			set(gca,'TickLength',[ 0 0 ])
			set(gca,'XTick',[0:lenTimeSeq/2:N])
			set(gca,'XTickLabel',round([0:lenTimeSeq/2:N]/obj.FRAMES_PER_SECOND))

			% for k = 1:20:M
			%     x = [1 N];
			%     y = [k k];
			%     plot(x,y,'Color','w','LineStyle','-');
			%     plot(x,y,'Color','k','LineStyle',':');
			% end

			hold on
			for k = floor(lenTimeSeq/2):lenTimeSeq:N
			    x = [k k];
			    y = [1 M];
			    plot(x,y,'Color','r','LineStyle','-','LineWidth',1);
			    % plot(x,y,'Color','k','LineStyle',':');
			end
			thisIdx = 1;
			for k = 0:lenTimeSeq:N
				if k==N
					continue
				end

			    text(k+round(lenTimeSeq/2),-5,num2str(obj.assayNum{globalStimIdx{stimNo}{thisIdx}}),'FontSize',8);
			    sessionTypeIdx = find(strcmp(assayTypeList,obj.assayType{globalStimIdx{stimNo}{thisIdx}}));
			    rectangle('Position',[k,0,lenTimeSeq,sessionTypeIndicatorHeight],'EdgeColor',sessionTypeColors(sessionTypeIdx,:),'FaceColor',sessionTypeColors(sessionTypeIdx,:))
			    thisIdx = thisIdx+1;

			    x = [k k];
			    y = [1 M];
			    plot(x,y,'Color','k','LineStyle','-','LineWidth',3);
			    % plot(x,y,'Color','k','LineStyle',':');
			    % insertText(movieTmp(:,:,frameNo),[0 0],[fileInfo.subject '_' fileInfo.assay],...
			    % 'BoxColor','white',...
			    % 'AnchorPoint','LeftTop',...
			    % 'BoxOpacity',1)
			end
			hold off
			assayTypeStrAdd = '';
			for assayTypeIdx = 1:length(assayTypeList)
				assayTypeStrAdd = [assayTypeStrAdd ' {\color[rgb]{',num2str(sessionTypeColors(assayTypeIdx,:)),'}',assayTypeList{assayTypeIdx},'}'];
			end

			title([thisSubjectStr ' | ' obj.stimulusNameArray{idNumIdxArray(stimNoIdx)} ' | stimulus onset = red line | ' assayTypeStrAdd])

		end
	end
end
% function [inputCell] = addText(inputCell,inputText)
% 	nFrames = length(inputCell);
% 	for frameNo = 1:nFrames
% 		minVal = nanmin(inputCell{frameNo}(:));
% 		maxVal = nanmax(inputCell{frameNo}(:));
% 		inputText{frameNo}
% 		inputCell{frameNo} = squeeze(nanmean(...
% 			insertText(inputCell{frameNo},[0 0],inputText{frameNo},...
% 			'BoxColor',[maxVal maxVal maxVal],...
% 			'TextColor',[minVal minVal minVal],...
% 			'AnchorPoint','LeftTop',...
% 			'FontSize',72,...
% 			'BoxOpacity',1)...
% 		,3));
% 	end
% 	% maxVal = nanmax(movieTmp(:))
% 	% movieTmp(movieTmp==maxVal) = 1;
% 	% 'BoxColor','white'
% end