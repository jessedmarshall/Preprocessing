function [IcaFilters, IcaTraces, valid] = filterICs(IcaFilters, IcaTraces, varargin)
    % biafra ahanonu
    % 2013.10.31
    % based on SpikeE code
    %
    % Removes small and very large ICs
    %
    % changelog
        % updated: 2013.11.08 [09:24:12] removeSmallICs now calls a filterICs, name-change due to alteration in function, can slowly replace in codes

    % get options
    options.minNumPixels=25;
    options.maxNumPixels=600;
    options.makePlots=1;
    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end

    lenICList = size(IcaFilters,1);
    waitbarHandle = waitbar(0, ['removing ICs outside: (' num2str(minNumPixels) ' ' num2str(maxNumPixels)]);

    ic_count = 1;
    valid = zeros(1,lenICList);
    for i = 1:lenICList
        if(mod(i,3)==0)
            waitbar(i/lenICList,waitbarHandle)
        end

        thisFilt = squeeze(IcaFilters(i,:,:));
        thisFiltThresholded = thresholdICs(thisFilt);
        sizeICFilt(i) = sum(thisFiltThresholded(:)>0);

        % display([num2str(sizeICFilt) ' ' num2str(sizeICFilt>minNumPixels)]);

        if (sizeICFilt(i)>minNumPixels)&(sizeICFilt(i)<maxNumPixels)
            valid(i) = 1;
           % IcaFilters_new(ic_count,:,:) = thisFilt;
           % IcaTraces_new(ic_count,:) = IcaTraces(i,:);
           % ic_count = ic_count + 1;
        end
    end
    close(waitbarHandle);

    % only keep valid ICs
    IcaFilters = IcaFilters(logical(valid),:,:);
    IcaTraces = IcaTraces(logical(valid),:);

    if makePlots==1
        openFigure(20390122,'half');
        %
        subplot(2,1,1)
        hist(sizeICFilt,round(logspace(0,log10(max(sizeICFilt)))));
        box off;title('distribution of IC sizes');xlabel('area (px^2)');ylabel('count');
        set(gca,'xscale','log')
        %
        subplot(2,1,2)
        hist(find(valid==0),round(logspace(0,log10(max(find(valid==0))))));
        box off;title('rank of removed ICs');xlabel('rank');ylabel('count');
        set(gca,'xscale','log')
    end