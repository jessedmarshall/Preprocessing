function cellImgsByParam = calcCellImgsByParam(muXVals, muYVals, sigXVals, sigYVals, thetaVals, nCells, imgSize)

% Written by Lacey Kitch in 2013

numMuVals=size(muXVals,2);
numSigVals=size(sigXVals,2);
numThetaVals=size(thetaVals,2);
paramSizeCumProd=[1 cumprod([numMuVals, numMuVals, numSigVals, numSigVals])];
cellImgsByParam=zeros([imgSize, nCells, numMuVals^2*numSigVals^2*numThetaVals]);
for cInd=1:nCells
    for muInd1=1:numMuVals
        for muInd2=1:numMuVals
            for sigInd1=1:numSigVals
                for sigInd2=1:numSigVals
                    for thetaInd=1:numThetaVals
                        linInd=sum(([muInd1 muInd2 sigInd1 sigInd2 thetaInd]-1).*paramSizeCumProd)+1;
                        cellImgsByParam(:,:,cInd,linInd)=calcCellImgs([muXVals(cInd,muInd1),...
                            muYVals(cInd,muInd2), sigXVals(cInd,sigInd1), sigYVals(cInd,sigInd2),...
                            thetaVals(cInd,thetaInd)], imgSize);
                    end
                end
            end
        end
    end
end

% from file calcCellImgsByParam on 12/12/13 at 11:38am