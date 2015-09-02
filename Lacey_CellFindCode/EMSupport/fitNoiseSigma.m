function noiseSigma = fitNoiseSigma(imgs,varargin)

% Written by Lacey Kitch in 2013
% Updated by Maggie Carr Larkin to ignore pixels with zero variation in time (black edges, dead pixels) in miniscope data

vlm=0;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'vlm')
        vlm=1;
    end
end


nFrames=size(imgs,3);
if nFrames>1000
    framesForEst=randperm(nFrames,1000);
else
    framesForEst=1:nFrames;
end

if ~vlm
    fInc=0.0001;
    fVals=0.95:fInc:1.2;
    variation_in_time = std(imgs(:,:,framesForEst),[],3);
    valid_xy = variation_in_time~=0; %Real data has some variation in time, black edges do not
else
    fInc=0.001;
    fVals=-0.2:fInc:0.2;
end
dist=zeros(size(fVals));
for fr=framesForEst
    thisFrame=imgs(:,:,fr);
    if ~vlm
        dist=dist+hist(thisFrame(valid_xy),fVals);
    else
        dist=dist+hist(thisFrame(:),fVals);
    end
end

if ~vlm
    % then only take the bottom part of the distribution and reflect it
    % this gets rid of the heavy tail at the top, but it does tend to
    % underestimate the noise std dev
    [~,zeroInd]=min(abs(fVals-1));
    dist=[dist(1:zeroInd), fliplr(dist(1:zeroInd-1))];
    fVals=fVals(1:length(dist));
else
    [~,zeroInd]=min(abs(fVals));
    dist(zeroInd)=0;
    dist=dist(2:end-1);
    fVals=fVals(2:end-1);
end

dist=dist/(sum(dist(:))*fInc);

if ~vlm
    startMu=1;
    startSigma=0.004;
else
    startMu=0;
    startSigma=0.05;
end
[noiseSigma,~]=gaussfit(fVals,dist,startSigma,startMu);


% from file fitNoiseSigma on 12/11/13 at 5:59pm
