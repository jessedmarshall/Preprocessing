function allCellTraces = calculateTraces(cellImgs, imgs, varargin)

% Written by Lacey Kitch in 2013

haveBG=0;
if ~isempty(varargin)
	options=varargin{1};
    if isfield(options, 'suppressOutput')
        suppressOutput=options.suppressOutput;
    else
        suppressOutput=0;
    end
    if isfield(options, 'bg')
        haveBG=1;
        bg=options.bg;
    end
    if isfield(options, 'vlm')
        if options.vlm && ~haveBG
            disp('Waring: calculating traces without taking background into account')
        end
    end
else
	suppressOutput=0;
end

if numel(size(imgs))==3
    % if cellImgs and imgs are still 3D and have not been reshaped
    imgSize=size(imgs(:,:,1));
    nCells=size(cellImgs,3);
    nFrames=size(imgs,3);
    cellImgs=reshape(cellImgs,[imgSize(1)*imgSize(2),nCells]);
    reshapeImgs=1;
else
    % if cellImgs and imgs are 2D and so have been reshaped
    nCells=size(cellImgs,2);
    nFrames=size(imgs,2);
    reshapeImgs=0;
end

if haveBG
    if numel(size(bg))==2
        bg=reshape(bg, [imgSize(1)*imgSize(2) 1]);
    end
end

% check for repetitive cellImgs, which make cellImgs singular, and
% eliminate them from the computation
[~,s,v]=svd(cellImgs'*cellImgs);
s=diag(s);
lowSVs=find(s<(10*eps*max(s)))';
goodCellInds=1:nCells;
badCellInds=zeros(1,nCells);
for lowSVind=lowSVs
    [~,badCellInd]=max(v(:,lowSVind));
    badCellInds(badCellInd)=1;
    v(badCellInd,:)=-10000;
end
if ~isempty(lowSVs) && ~suppressOutput
    disp(['Found ' num2str(length(lowSVs)) ' redundant cell images']);
end
goodCellInds(logical(badCellInds))=[];
cellImgs(:,logical(badCellInds))=[];

% cycle through chunks of time and of cells (for RAM preservation) and calculate traces
allCellTraces=zeros(nCells, nFrames);
cImgPrefactor=(cellImgs'*cellImgs)\cellImgs';
clear cellImgs
for fr=1:200:nFrames
    tLims=fr:min(fr+199,nFrames);
    if reshapeImgs
        if haveBG
            thisImgs=reshape(imgs(:,:,tLims),[imgSize(1)*imgSize(2),length(tLims)])-...
                repmat(bg, [1 length(tLims)]);
        else
            thisImgs=reshape(imgs(:,:,tLims),[imgSize(1)*imgSize(2),length(tLims)])-1;
        end
    else
        if haveBG
            thisImgs=imgs(:,tLims)-repmat(bg, [1 length(tLims)]);
        else
            thisImgs=imgs(:,tLims)-1;
        end
    end
    allCellTraces(goodCellInds,tLims)=cImgPrefactor*thisImgs;
end
        
        
% from function calculateTraces on 12/11/13 at 5:58pm