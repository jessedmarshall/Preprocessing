function outMatrix = cellTo3Dmat(inputCell)
    % updated: 2013.10.08 [11:11:17]
    % inputs:
    % outputs:
    % get length
    lengthCell = length(inputCell);
    %Convert cell array back to 3D matrix
    tempCell = cell2mat(inputCell);
    [r,c]=size(tempCell)
    outMatrix = permute(reshape(tempCell',[r,c/lengthCell,lengthCell]),[2,1,3]);