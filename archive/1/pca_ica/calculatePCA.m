function [CovEvals PcaTraces PcaFilters nPCs] = calculatePCA(inputMovie,nPCs)
    % created by Jerome Lecoq in 2011
    %
    % Runs PCA on inputMovie and looks for a specific number of ICs
    %
    % biafra ahanonu
    % started updating: 2013.10.31
    % changelog
        % updated: 2013.10.31 [13:26:17] added PcaFilter variance correction into function

    OldClass=class(inputMovie);

    % convert to double for calculation
    inputMovie = double(inputMovie);

    % get movie dimensions
    inputMovieSize = size(inputMovie);
    Npixels = inputMovieSize(1)*inputMovieSize(2);
    Ntime = inputMovieSize(3);

    %Create covariance matrix in the time domain as it is computationally more advantageous than in space and mathematically equivalent.
    inputMovie = reshape(inputMovie, Npixels, Ntime);
    covmat=double(cov(inputMovie));

    % Options for the Eigenvectors extraction
    opts.issym = 'true'; %Options for the Eigenvectors extraction

    if nPCs<size(covmat,1)
        [PcaTraces, CovEvals] = eigs(covmat, nPCs, 'LM', opts);
    else
        [PcaTraces, CovEvals] = eig(covmat);
        nPCs = size(CovEvals,1);
    end

    %At this stage PcaTraces is Ntime x nPCs, ie each column is an eigenvector
    %CovEvals is a square diagonal matrix with the eigenvalues on the diagonal
    %We only keep the diagonal values, ie we no longer have a diagonal matrix

    % Throw out negative eigenvalues
    CovEvals=diag(CovEvals);
    if nnz(CovEvals<=0)
        nPCs = nPCs - nnz(CovEvals<=0);
        PcaTraces = PcaTraces(:,CovEvals>0);
        CovEvals = CovEvals(CovEvals>0);
    end
    [CovEvals, indices]=sort(CovEvals, 'descend');
    PcaTraces=PcaTraces(:,indices);

    %Ensure that PcaFilters has variance 1
    CovEvals = diag(CovEvals);
    CovEvals = CovEvals*Npixels;

    %Calculate the PcaFilters.
    %We need to get the eigenvalues of the Movie, not of the covariance
    %matrix. This is the reason for 1/2 power.
    Sinv = inv(CovEvals.^(1/2));

    %Calculate the corresponding space filters
    PcaFilters = double(inputMovie*PcaTraces*Sinv);

    %Now because the Filters are not an EXACT calculation, their variance can be slightly off 1. We make sure it is 1, as this can slightly affect the spatio-temporal ICA that expect normalize eigenvectors.
    for i=1:nPCs
        PcaFilters(:,i)=PcaFilters(:,i)/norm(PcaFilters(:,i));
    end