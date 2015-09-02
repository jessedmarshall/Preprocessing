function [cellmap] = createCellMap(IcaFilters)
    % biafra ahanonu
    % started: 2013.10.12
    % creates a cellmap from a ZxXxY input matrix IcaFilters

    %Create the cellmap
    cellmap = [];
    icstocheck = size(IcaFilters,1);
    for i = 1:icstocheck
        if ~isempty(IcaFilters(i,:,:))
            if isempty(cellmap)
                cellmap = squeeze(IcaFilters(i,:,:));;
            else
                cellmap = max(cellmap,squeeze(IcaFilters(i,:,:)));
            end
        end
    end

% function [IC_filter_new] = removeSmallICs(IC_filter)
%     minNumPixels=25;
%     maxNumPixels=100;

%     lenICList = length(IC_filter{1,1}.Image);
%     waitbarHandle = waitbar(0, 'removing small area ICs...');
%     ic_count = 1;

%     IC_filter_new = IC_filter;
%     IC_filter_new{1,1}.Image={};
%     IC_filter_new{1,1}.centroid={};

%     for i = 1:lenICList
%         if(mod(i,3)==0)
%             waitbar(i/lenICList,waitbarHandle)
%         end

%         thisFilt = IC_filter{1,1}.Image{1,i};
%         thisFiltThresholded = thresholdICs(thisFilt);
%         sizeICFilt = sum(thisFiltThresholded(:)>0);

%         % display([num2str(sizeICFilt) ' ' num2str(sizeICFilt>minNumPixels)]);

%         if sizeICFilt>minNumPixels && sizeICFilt<maxNumPixels
%            IC_filter_new{1,1}.Image{1,ic_count} = thisFilt;
%            ic_count = ic_count + 1;
%         end
%     end
%     close(waitbarHandle);