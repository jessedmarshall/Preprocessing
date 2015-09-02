function [miShuffleMeanStd] = mutualInformationShuffle(inputSignal,inputResponse,varargin)
	% example function with outline for necessary components
	% biafra ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% inputSignal - binary vector of an input signal (e.g. stimulus) to do MI against
		% inputResponse - the response vector (e.g. neuronal traces)
	% outputs
		%

	% changelog
		% 2014.10.21 - made loop parallel to speed things up
	% TODO
		%
	% OLD
		% thanks to Scott Teuscher for the super useful vectorized circshift (http://www.mathworks.com/matlabcentral/fileexchange/41051-vectorized-circshift)

	%========================
	% number of resampling from shifted MI
	options.nSamples = 20;
	% use parallel registration (using matlab pool)
	options.parallel = 1;
	% close the matlab pool after running?
	options.closeMatlabPool = 0;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% display('shuffling MI scores')
	try
		% ========================
		% check maximum number of cores available
		maxCores = feature('numCores')*2-2;
		if maxCores>6
			maxCores = 6;
		end
		% check that local matlabpool configuration is correct
		myCluster = parcluster('local');
		if myCluster.NumWorkers<maxCores
			myCluster.NumWorkers = maxCores; % 'Modified' property now TRUE
			saveProfile(myCluster);   % 'local' profile now updated
		end
		% open works = max core #, probably should do maxCores-1 for stability...
		% check whether matlabpool is already open
		if matlabpool('size') | ~options.parallel
		else
			matlabpool('open',maxCores);
		end
		% ========================
		tic
		nPoints = length(inputSignal);
		nResponses = size(inputResponse,1);
		reverseStr = '';
        nSamples = options.nSamples;
		% sum(inputResponse,2)
		% nResponses = 10;
        % parfor_progress(nResponses); % Initialize
        disp('calculating mutual information shuffle...')
        miShuffleMeanStd = NaN([nResponses 4]);
		parfor responseNo=1:nResponses
			iResponse = inputResponse(responseNo,:);
			% sum(inputSignal)
			% sum(iResponse)
			miScoreBase = MutualInformation(inputSignal,iResponse);

			% replicate vector then shuffle
			iResponse = repmat(iResponse,[nSamples 1]);
			[iResponseShuffle] = shuffleMatrix(iResponse,'waitbarOn',0);

			% iResponseShuffle = vectCircShift(iResponse,randsample(length(iResponse),options.nSamples,true));

			miScoresShuffle = MutualInformation(inputSignal,iResponseShuffle);
			zscore = (miScoreBase-nanmean(miScoresShuffle))./nanstd(miScoresShuffle);
			miShuffleMeanStd(responseNo,:) = [miScoreBase nanmean(miScoresShuffle) nanstd(miScoresShuffle) zscore];

            % parfor_progress
			%reverseStr = cmdWaitbar(responseNo,nResponses,reverseStr,'inputStr','calculating mutual information shuffle','waitbarOn',1,'displayEvery',5);
        end
        % parfor_progress(0); % Clean up
		toc
		viewHists(miShuffleMeanStd,options)
		% ========================
		%Close the workers
		if matlabpool('size')&options.closeMatlabPool
			matlabpool close
		end
		% ========================
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end

function viewHists(miShuffleMeanStd,options)
	% miShuffleMeanStd
	[figHandle figNo] = openFigure(21, '');
	% subplot(2,1,1)
	% hist(miShuffleMeanStd(:,2),100);
	% xlim([0 1e-3]);
	% % hold on;
	% subplot(2,1,2)
	% hist(miShuffleMeanStd(:,1),100);
	% xlim([0 1e-3]);
	% h = findobj(gca,'Type','patch');
	% display(h)
	% set(h(1),'FaceColor','k','EdgeColor','k');
	% set(h(2),'FaceColor','g','EdgeColor','k');
	% set(h(2),'FaceColor','b','EdgeColor','k');
	subplot(2,3,[1:2,4:5])
		nSignals =size(miShuffleMeanStd,1);
		nSignalsVector = 1:nSignals;
		% miShuffleMeanStd
		x = nSignalsVector;
		y = miShuffleMeanStd(:,2);
		dy = 1.96*miShuffleMeanStd(:,3);  % made-up error values
		fill([x(:);flipud(x(:))],[y(:)-dy(:);flipud(y(:)+dy(:))],[.8 .8 1],'linestyle','none');
		line(x,y)
		% errorbar(1:nSignals,miShuffleMeanStd(:,2),miShuffleMeanStd(:,3),'b.','MarkerSize',20)
		% plot(miShuffleMeanStd(:,1),1:nSignals,'b.','MarkerSize',20);
		hold on;
		% errorbar(1:nSignals,miShuffleMeanStd(:,1),E,'r.','MarkerSize',20)
		plot(nSignalsVector,miShuffleMeanStd(:,1),'r.','MarkerSize',20);
		sigModSignals = miShuffleMeanStd(:,1)>miShuffleMeanStd(:,2)+1.96*miShuffleMeanStd(:,3);
		plot(nSignalsVector(sigModSignals),miShuffleMeanStd(sigModSignals,1),'g.','MarkerSize',20);

		legend({'shuffled std','shuffled mean','actual, not-significant','actual, significant'})
		box off;
		title(['mutual information: actual vs. n=' num2str(options.nSamples) ' shuffles',10])
		xlabel('signal #');ylabel('MI score');
		hold off;
		% pause
	subplot(2,3,3)
		pieNums = [sum(sigModSignals)/nSignals sum(~sigModSignals)/nSignals];
		% pieLabels = strcat({'not-significant','significant'},' : ',num2str(pieNums));
		pieLabels = {'significant','not-significant'};
		h = pie(pieNums,pieLabels);
		% adjPieLabels(h);
		title('2\sigma significance threshold');

	subplot(2,3,6)
		sigModSignals = miShuffleMeanStd(:,1)>miShuffleMeanStd(:,2)+3*miShuffleMeanStd(:,3);
		pieNums = [sum(sigModSignals)/nSignals sum(~sigModSignals)/nSignals];
		% pieLabels = strcat({'not-significant','significant'},' : ',num2str(pieNums));
		pieLabels = {'significant','not-significant'};
		h = pie(pieNums,pieLabels);
		% adjPieLabels(h);
		title('3\sigma significance threshold');
function adjPieLabels(h)
	hText = findobj(h,'Type','text'); % text handles
	oldExtents_cell = get(hText,'Extent'); % cell array
	oldExtents = cell2mat(oldExtents_cell); % numeric array
	newExtents_cell = get(hText,'Extent'); % cell array
	newExtents = cell2mat(newExtents_cell); % numeric array
	width_change = newExtents(:,3)-oldExtents(:,3);
	signValues = sign(oldExtents(:,1));
	offset = signValues.*(width_change/2);
	textPositions_cell = get(hText,{'Position'}); % cell array
	textPositions = cell2mat(textPositions_cell); % numeric array
	textPositions(:,1) = textPositions(:,1) + offset; % add offset
	set(hText,{'Position'},num2cell(textPositions,[3,2])) % set new position

function viewPlots()
	figure(56544)
	plot(miScoresShuffle,'k.');hold on;
	plot(miScoreBase,'r+');
	hold off;
	figure(56545)
	normMI = normalizeVector([miScoreBase miScoresShuffle(:)'],'normRange','oneToOne');
	counts = hist(normMI(2:end),10)
	hist(normMI(2:end),10);
	hold on;
	xlim([0 1]);
	h = findobj(gca,'Type','patch');
	% display(h)
	set(h,'FaceColor','k','EdgeColor','k');
	% set(h(2),'FaceColor','g','EdgeColor','k');
	% set(h(2),'FaceColor','b','EdgeColor','k');
	xval = 0;
	x=[normMI(1),normMI(1)];
	y=[0 max(counts)];
	plot(x,y,'r')
	hold off;