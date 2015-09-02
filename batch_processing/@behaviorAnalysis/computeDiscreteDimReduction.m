function obj = computeDiscreteDimReduction(obj)
	% computes PCA and other population vectors
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


	nameArray = obj.stimulusNameArray;
	saveNameArray = obj.stimulusSaveNameArray;
	idArray = obj.stimulusIdArray;

	scnsize = get(0,'ScreenSize');
	[showNoStimuliIdx, ok] = listdlg('ListString',{'yes','no'},'ListSize',[scnsize(3)*0.2 scnsize(4)*0.2],'Name','show no stimuli trials?');

	[fileIdxArray idNumIdxArray nFilesToAnalyze nFiles] = obj.getAnalysisSubsetsToAnalyze();
	for thisFileNumIdx = 1:length(fileIdxArray)
		try
			thisFileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = thisFileNum;
			display(repmat('=',1,21))
			display([num2str(thisFileNumIdx) '/' num2str(nFilesToAnalyze) ' (' num2str(thisFileNum) '/' num2str(nFiles) '): ' obj.fileIDNameArray{obj.fileNum}]);

			[IcaTraces IcaFilters signalPeaks signalPeaksArray valid] = modelGetSignalsImages(obj);
			if obj.dfofAnalysis==1
				signalPeaks = IcaTraces;
			end
			signalPeaks = spreadSignal(signalPeaks,'timeSeq',[-2:2]);
			% sum(signalPeaks(:))

			idNumCounter = 1;
			pcaInputMatrix = {};
			groupingVector = {};
			groupingVectorColors = [];
			nIDs = length(idNumIdxArray);
			stimVectorAll = zeros([1 size(IcaTraces,2)]);
			if showNoStimuliIdx==2
				stimColorName = hsv(nIDs);
			else
				stimColorName = hsv(nIDs+1);
			end
			for idNumIdx = 1:(nIDs+1)
				if idNumIdx<=nIDs
					idNum = idNumIdxArray(idNumIdx);
					obj.stimNum = idNum;
					stimName = nameArray{idNum};
					stimTimeSeq = obj.stimulusTimeSeq{idNum};
					% stimTimeSeq = -10;
					stimVector = obj.modelGetStim(idArray(idNum));
					if isempty(stimVector); continue; end;
					nStimsTrue = length(find(stimVector));
					stimVector = spreadSignal(stimVector,'timeSeq',stimTimeSeq);
					stimVectorAll = stimVectorAll|stimVector;
					nStims = length(find(stimVector))

					thisColor = customColormap({stimColorName(idNumIdx,:),stimColorName(idNumIdx,:)/5},'nPoints',length(stimTimeSeq),'discreteCutoff',1);
					thisColor = repmat(thisColor,[nStimsTrue 1]);
				else
					if showNoStimuliIdx==2
						continue
					end
					display('calculating no stimuli values...')
					nStimPts = length(find(stimVectorAll));
					noStimuliIdx = find(~stimVectorAll);
					stimVector = zeros([1 nStimPts]);
					stimVector(noStimuliIdx(randperm(length(noStimuliIdx),nStimPts))) = 1;

					stimName = 'no stimuli';
					stimTimeSeq = 0;
					nStims = length(find(stimVector));
					nStimsTrue = nStims;
					thisColor = repmat(stimColorName(idNumIdx,:),[nStimsTrue 1]);
				end

				pcaInputMatrix{idNumIdx} = signalPeaks(:,logical(stimVector));

				tmpGroupingVector = repmat({stimName},[1 nStims]);
				groupingVector = {groupingVector{:} tmpGroupingVector{:}};
				% thisColor = customColormap({[0 0 0],stimColorName(idNumIdx,:),[1 1 1]},'nPoints',nStims);
				% thisColor = customColormap({stimColorName(idNumIdx,:),[0 0 0]},'nPoints',length(stimTimeSeq),'discreteCutoff',1);

				% thisColor = repmat(stimColorName(idNumIdx,:),[nStims 1]);
				groupingVectorColors = [groupingVectorColors; thisColor];

				%  n-by-p data matrix X. Rows of X correspond to observations and columns correspond to variables. The coefficient matrix is p-by-p. Each column of coeff contains coefficients for one principal component, and the columns are in descending order of component variance.
				% input | rows = neural activity around stimulus, column = stimulus trial
				% output | row = stimulus trial, column = principal component
			end
			if isempty(pcaInputMatrix); display('empty PCA input matrix');continue; end;
			if sum(stimVectorAll(:))==0; display('empty PCA input matrix');continue; end;

			% size(pcaInputMatrix{1})
			% pcaInputMatrix{:}
			cellfun(@(x) size(x),pcaInputMatrix,'UniformOutput',false)
			pcaInputMatrix = cat(2,pcaInputMatrix{:});
			size(pcaInputMatrix)
			% figure(29229)
			% imagesc(pcaInputMatrix)
			% pause
			% [coeffMatrix,score,eigenvalues] = pca(pcaInputMatrix);
			% [lambdaOut,psiOut,TOut,statsOut] = factoran(pcaInputMatrix,15,'scores','regression');
			[lambdaOut,psiOut,TOut,statsOut] = factoran(pcaInputMatrix,15);
			coeffMatrix = lambdaOut;
			eigenvalues = psiOut;
			size(coeffMatrix)
			% coeffMatrix(1:5,:)
			% size(groupingVector)
			[~, ~] = openFigure(obj.figNoAll, '');
				clf
				% flip dimensions so that ordering of no stimuli will be the same across all conditions.
				coeffMatrix = flipdim(coeffMatrix,1);
				groupingVector = flipdim(groupingVector(:),1);
				groupingVectorColors = flipdim(groupingVectorColors,1);
				coeffMatrix(length(stimTimeSeq):length(stimTimeSeq):end,:) = NaN;
				PC1 = coeffMatrix(:,1);
				PC2 = coeffMatrix(:,2);
				PC3 = coeffMatrix(:,3);
				[stimNamesToDisplay psuedoStim] = plotPsuedoStim()
				subplotX = 2;
				subplotY = 2;
			subplot(subplotX,subplotY,1)
				% gscatter(PC1,PC2,groupingVector)
				% size(PC1)
				% size(groupingVectorColors)
				viewColorLinePlot(PC1,PC2,'colors',groupingVectorColors,'v3',PC3,'lineWidth',3);
				rotate3d on; grid on;
				xlabel('PC1');ylabel('PC2');zlabel('PC3');
				legend off;
				axis tight;
				view([-1 -1 1])

				% hold on
				% axes('Position',[.5 .5 .1 .1])
				% box on
				% bar(eigenvalues(1:10))
				% continue
			subplot(subplotX,subplotY,3)
				viewColorLinePlot(PC1,PC2,'colors',groupingVectorColors,'v3',PC3,'lineWidth',3);
				rotate3d on; grid on;
				xlabel('PC1');ylabel('PC2');zlabel('PC3');
				legend off;
				axis tight;
				view([1 1 1])
			subplot(subplotX,subplotY,2)
				gscatter(PC1,PC2,groupingVector)
				xlabel('PC1');ylabel('PC2');
				%
				% gscatter(PC1,PC3,groupingVector)
				% xlabel('PC1');ylabel('PC3');
				% legend off;
				axis tight;
				legend('Location','northeast');
				% return
			suptitle([obj.fileIDNameArray{obj.fileNum} ' | PCA all cells, input = stimulus trials'])
			% subplot(subplotX,subplotY,3)
			% 	%
			% 	% call GSCATTER and capture output argument (handles to lines)
			% 	% h = gscatter(PC1, PC2, groupingVector);
			% 	% % for each unique group in 'g', set the ZData property appropriately
			% 	% gu = unique(groupingVector);
			% 	% gu = 1:length(gu);
			% 	% for k = 1:numel(gu)
			% 	% 	set(h(k), 'ZData', PC3(find(strcmp(gu(k),groupingVector))));
			%  %      	% set(h(k), 'ZData', PC3( groupingVector == gu(k) ));
			% 	% end
			% 	% view(3)
			% 	s = repmat([10],numel(PC1),1);
			% 	size(PC1)
			% 	size(groupingVectorColors)
			% 	% scatter3(PC1,PC2,PC3,s,groupingVectorColors,'filled');
			% 	xlabel('PC1');ylabel('PC2');zlabel('PC3');
			% 	rotate3d on; grid on;
			% 	%
			% 	% gscatter(PC2,PC3,groupingVector)
			% 	% xlabel('PC2');ylabel('PC3');
			% 	legend off; axis tight;
			subplot(subplotX,subplotY,4)
				% gscatter(PC1,PC2,groupingVector)
				gscatter(psuedoStim,psuedoStim,stimNamesToDisplay')
				% legend('Location','best');axis off;legend('boxoff');
				legend('Location','northeast');
				hold on
				bar(eigenvalues(1:10)');axis tight
				xlabel('eigenvalues');ylabel('power')
				% title('eigenvalues')
				% eigenvalues
				% sum(eigenvalues)
				% axes('Position',[.6 .15 .2 .1])
				% bar(eigenvalues(1:10)');axis tight
				% return;

			thisFileID = obj.fileIDArray{obj.fileNum};
		    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 10])
		    obj.modelSaveImgToFile([],'pcaStimBased_','current',strcat(thisFileID));

			% figure(292930)
			% scatter3(PC1,PC2,PC3,'g.')
			% % title(['principal components for '])
	  % %       xlabel('PC1');ylabel('PC1');zlabel('PC3');
			% rotate3d on;

			% pause

		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
	function [stimNamesToDisplay psuedoStim] = plotPsuedoStim()
		% hold on
		% stimNamesToDisplay = unique(groupingVector);
		stimNamesToDisplay = nameArray(idNumIdxArray);
		nStimIds = length(stimNamesToDisplay);
		if showNoStimuliIdx==1
			nStimIds = nStimIds+1;
		end
		psuedoStim = zeros([1 nStimIds]);
		if showNoStimuliIdx==1
			stimNamesToDisplay = {'no stimuli' stimNamesToDisplay{:}};
			% stimNamesToDisplay{end+1} = 'no stimuli';
		end
		% size(groupingVector)
		groupingVector = {stimNamesToDisplay{:} groupingVector{:}};
		groupingVector = groupingVector';
		groupingVectorColors = [stimColorName; groupingVectorColors];
		% PC1(end+1:end+nStimIds) = psuedoStim;
		% PC2(end+1:end+nStimIds) = psuedoStim;
		% PC3(end+1:end+nStimIds) = psuedoStim;
		PC1 = [psuedoStim(:); PC1(:)]';
		PC2 = [psuedoStim(:); PC2(:)]';
		PC3 = [psuedoStim(:); PC3(:)]';
		% size(groupingVector)
		% size(PC1)
		% psuedoStim
		% stimNamesToDisplay
		% size(psuedoStim)
		% size(stimNamesToDisplay)
		% gscatter(psuedoStim,psuedoStim,stimNamesToDisplay')
		% pause
		% hold on
	end
end