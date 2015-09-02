function [icImgs,icTraces] = my_ica(imgs, pcImgs, pcTraces, nICs, muVal)

nPCs=size(pcTraces,1);
if nPCs<nICs
    nICs=nPCs;
end
Mu=muVal;
TermTolICs=10^(-3);
MaxRoundsICs=750;

PcaTraces=pcTraces;
PcaFilters=reshape(pcImgs, [size(pcImgs,1)*size(pcImgs,2) nPCs]);
PcaFilters=permute(PcaFilters, [2 1]);

% Seed for the ICs calculation
ica_A_guess = orth(randn(nPCs, nICs));

% % Center the data by removing the mean of each PC
meanTraces = mean(PcaTraces,2);
PcaTraces = PcaTraces - meanTraces * ones(1, size(PcaTraces,2));

meanFilters = mean(PcaFilters,2);
PcaFilters = PcaFilters - meanFilters * ones(1, size(PcaFilters,2));

% Create concatenated data for spatio-temporal ICA
if Mu == 1
    % Pure temporal ICA
    IcaMixed = PcaTraces;

elseif Mu == 0
    % Pure spatial ICA
    IcaMixed = PcaFilters;

else
    % Spatial-temporal ICA
    IcaMixed = [(1-Mu)*PcaFilters, Mu*PcaTraces];
    IcaMixed = IcaMixed / sqrt(1-2*Mu+2*Mu^2); % This normalization ensures that, if both PcaFilters and PcaTraces have unit covariance, then so will IcaTraces
end

% Perform ICA
numSamples = size(IcaMixed,2);
ica_A = ica_A_guess;
BOld = zeros(size(ica_A));
numiter = 0;
minAbsCos = 0;

while (numiter<MaxRoundsICs) && ((1-minAbsCos)>TermTolICs)
    numiter = numiter + 1;

    if numiter>1
        Interm=IcaMixed'*ica_A;
        Interm=Interm.^2;
        ica_A = IcaMixed*Interm/numSamples;
    end

    % Symmetric orthogonalization.
    ica_A = ica_A * real(inv(ica_A' * ica_A)^(1/2));

    % Test for termination condition.
    minAbsCos = min(abs(diag(ica_A' * BOld)));

    BOld = ica_A;


end

ica_W = ica_A';

% Add the mean back in.
IcaTraces = ica_W*PcaTraces+ica_W*(meanTraces*ones(1,size(PcaTraces,2)));
IcaFilters = ica_W*PcaFilters+ica_W*(meanFilters*ones(1,size(PcaFilters,2)));

% Sort ICs according to skewness of the temporal component
icskew = skewness(IcaTraces');
[~, ICCoord] = sort(icskew, 'descend');
IcaTraces = IcaTraces(ICCoord,:);
IcaFilters = IcaFilters(ICCoord,:);

% Note that with these definitions of IcaFilters and IcaTraces, we can decompose
% the sphered and original movie data matrices as:
%     mov_sphere ~ PcaFilters * PcaTraces = IcaFilters * IcaTraces = (PcaFilters*ica_A') * (ica_A*PcaTraces),
%     mov ~ PcaFilters * pca_D * PcaTraces.
% This gives:
%     IcaFilters = PcaFilters * ica_A' = mov * PcaTraces' * inv(diag(pca_D.^(1/2)) * ica_A'
%     IcaTraces = ica_A * PcaTraces = ica_A * inv(diag(pca_D.^(1/2))) * PcaFilters' * mov


% Reshape the filter to have a proper image
IcaFilters = reshape(IcaFilters,nICs,size(imgs,1),size(imgs,2));

icImgs=IcaFilters;
icTraces=IcaTraces;