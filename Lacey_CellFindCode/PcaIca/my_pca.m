function [pcImgs, pcTraces]=my_pca(imgs,nPCs)

% subtract mean from each frame
% matlab's pca code will do this for us, but we do it anyway
for t=1:size(imgs,3)
    thisFrame=imgs(:,:,t);
    imgs(:,:,t)=thisFrame-mean(thisFrame(:));
end

nypix=size(imgs,1);
nxpix=size(imgs,2);
nPixTot=nypix*nxpix;
nFrames=size(imgs,3);

imgs=reshape(imgs,nPixTot,nFrames);
covmat=double(cov(imgs));

opts.issym = 'true';
        
if nPCs<size(covmat,1)
    [pcTraces, covEvals] = eigs(covmat, nPCs, 'LM', opts); 
else
    nPCs=size(covmat,1);
    [pcTraces, covEvals] = eig(covmat);
end
pcTraces=pcTraces';
[covEvals, inds]=sort(diag(covEvals), 'descend');
pcTraces=pcTraces(inds,:);

% This is to ensure that PcaFilters has variance 1
covEvals=covEvals*nPixTot;

% We calculate the corresponding spatial filters. We need to get the eigenvalues of
% the Movie, not of the covariance matrix. This is the reason for 1/2
% power.
pcImgs=double(imgs*pcTraces'*diag(1./covEvals.^(1/2)));
pcImgs=reshape(pcImgs,nypix,nxpix,nPCs);