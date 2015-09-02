function matchICsAcrossDays()
% refactored to be a separate function...

if IC_iterations > 1
    display('matching ICs...')

    %Iterate through pairwise matching and assign global ICs
    matchingcells = zeros(size(IC_filters{1}.centroid,1),IC_iterations);
    matchingcells(:,1) = 1:size(IC_filters{1}.centroid,1);
    IC_filters{1}.global_ID = 1:size(IC_filters{1}.centroid,1);
    global_ID= max(IC_filters{1}.global_ID)+1;

    for run1 = 1:IC_iterations
        centroids1 = IC_filters{run1}.centroid;
        for run2 = 2:IC_iterations
            if run2 > run1
               centroids2 = IC_filters{run2}.centroid;

                %Determine the clustering based on distance
                N1 = size(centroids1,1); N2 = size(centroids2,1);
                dsq = squareform(pdist([centroids1; centroids2])); %find the distance between all pairs
                dsq(1:N1, 1:N1)=1000; %cells from the same day should not be matched
                dsq(N1+(1:N2), N1+(1:N2))=1000; %cells from the same day should not be matched
                for i=1:size(dsq,1)
                    dsq(i,i)=0; %cells should not be matched to themselves
                end

                dlin=squareform(dsq);
                h=linkage(dlin, 'complete');
                c=cluster(h, 'cutoff', maxDist, 'criterion', 'distance');

                cInds=1:max(c);
                if length(unique(c(1:N1)))~=N1 || length(unique(c(N1+(1:N2))))~=N2
                    warndlg('cells from same day assigned to same cluster!')
                end
                for cInd=cInds
                    if sum(c==cInd)>2
                        warndlg('more than 2 cells in a cluster!')
                    end
                end

                numClusts=max(c)-length(unique(c));
                sharedCellInds=zeros(numClusts,2);
                clustInd=0;
                for cInd=cInds
                    theseCells=find(c==cInd);
                    ind1=theseCells(theseCells<=N1);
                    ind2=theseCells(theseCells>N1)-N1;
                    if ~isempty(ind1) && ~isempty(ind2)
                        %Verify that the cells overlap
                        overlap = sum(sum(IC_filters{run1}.Image{ind1}>0 & IC_filters{run2}.Image{ind2}>0))./...
                            (sum(sum(IC_filters{run1}.Image{ind1}>0)) + sum(sum(IC_filters{run2}.Image{ind2}>0)));
                        if gt(overlap,0.25)
                            clustInd=clustInd+1;
                            sharedCellInds(clustInd,:)=[ind1, ind2];
                        end
                    end
                end
                clear numClusts clustInd cInd cInds theseCells c ind1 ind2 overlap dsq dlin h

                %Preallocate global_ID field
                if ~isfield(IC_filters{run2},'global_ID')
                    IC_filters{run2}.global_ID = nan(size(IC_filters{run2}.centroid,1),1);
                end

                % Go through repeat 2, assign matched cells to previously assigned
                % global IDs, assign unmatched cells new global IDs
                for i = 1:size(centroids2)
                    %Check to see if global ID has already been assigned to the cell
                    if ~isnan(IC_filters{run2}.global_ID(i))
                        matchingcells(IC_filters{run2}.global_ID(i),run2) = i;
                    else
                        %If a global ID has not already been assigned to this IC, determine whether this is a shared cell
                        sharedind = find(sharedCellInds(:,2)==i);
                        if ~isempty(sharedind)
                            gID = IC_filters{run1}.global_ID(sharedCellInds(sharedind,1));
                            IC_filters{run2}.global_ID(i) = gID;
                            matchingcells(gID,run2) = i;
                        %If a global ID has not already been assigned and it is not a shared cell,
                        %AND this is the last opportunity for this cell to be matched (i.e.
                        %act as day2), assign a new global ID to this neuron.
                        else
                            if run2 == run1+1
                                IC_filters{run2}.global_ID(i) = global_ID;
                                matchingcells(global_ID,:) = 0;
                                matchingcells(global_ID,run2) = i;
                                global_ID = global_ID+1;
                            end
                        end
                    end
                end
            end
        end
    end
    clear run1 run2 global_ID gID sharedind sharedCellInds centroids1 centroids2

    %Merge ICs across repeats
    IC_filter = cell(1,days(dayInd));
    ic_count = 1;
    cellmap = [];

    for appeared_nrepeats = IC_iterations:-1:1
        valid = find(sum(matchingcells>0,2) == appeared_nrepeats);
        for i = 1:length(valid)
            %Find IC that matches this global ID
            repeat = find(matchingcells(valid(i),:)>0);

            %Merge ICs
            for r = 1:length(repeat)
                if r == 1
                    thisIC = IC_filters{repeat(r)}.Image{valid(i)==IC_filters{repeat(r)}.global_ID};
                else
                    thisIC = cat(3,thisIC,IC_filters{repeat(r)}.Image{valid(i)==IC_filters{repeat(r)}.global_ID});
                end
            end
            if size(thisIC,3)>1
                valid_pixels = min(thisIC,[],3)>0;
                thisIC(~valid_pixels) = 0; clear valid_pixels
                thisIC = mean(thisIC,3);
                thisIC = thisIC./max(max(thisIC)); %Renormalize
            end

            %Determine whether this IC occupies an empty location in the
            %cellmap
            if isempty(cellmap)
                cellmap = thisIC;
            else
                if cellmap(max(max(thisIC))==thisIC) == 0
                    cellmap = max(cellmap,thisIC);
                    IC_filter{days(dayInd)}{ic_count}.IC = thisIC;
                    imagesum = sum(sum(thisIC));
                    IC_filter{days(dayInd)}{ic_count}.centroid = [sum(sum(thisIC.*xCoords))/imagesum ...
                        sum(sum(thisIC.*yCoords))/imagesum];
                    ic_count = ic_count+1;
                    clear imagesum thisIC
                end
            end
        end
    end
    clear IC_filters valid matchingcells

else
    %If ICA is run only once threshold, normalize, and organize
    IC_filter = cell(1,days(dayInd));
    IC_filter{days(dayInd)} = IC_filters{1};
    IcaFilters = IC_filter;
end