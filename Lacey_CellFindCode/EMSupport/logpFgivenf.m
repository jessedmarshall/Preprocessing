function logp = logpFgivenf(F, allfvals, cellImgs, noiseSigma, bg)

% Written by Lacey Kitch in 2013

% F : frame (data) - nxpix*nypix x 1
% allfvals : nCells x numfvecs, f values at all combos
% noiseSigma : scalar, std dev of noise
% bg : size of F, mean of background
% cellImgs : nxpix*nypix x nCells, gaussian images of all cells

if size(allfvals,1)~=size(cellImgs,2)
    error('Problem with log lik calc input')
end
numfvecs=size(allfvals,2);
logp=zeros(1,numfvecs);

logSigmaTerm=-log(sqrt(2*pi)*noiseSigma)+log(0.01);

for fVecInd=1:numfvecs

    thisBG=bg+cellImgs*allfvals(:,fVecInd);

    partialLogp=-0.5*(((F - thisBG)./noiseSigma).^2)+logSigmaTerm;

    logp(fVecInd)=sum(sum(partialLogp));
end

logp=logp/numel(F);

% from file logpFgivenfwithCellImgs_allfvals_diffVals_nomex_reshape on
% 12/12/13 at 12:07pm