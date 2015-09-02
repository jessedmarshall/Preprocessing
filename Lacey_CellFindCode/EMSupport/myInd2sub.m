function subIndices = myInd2sub(arraySize, linIndices)

% Written by Lacey Kitch in 2013

% my version of ind2sub, faster than matlab version and outputs subscript
% indices as an array rather than needing each output individually
% specified per dimension

subIndices=zeros(length(linIndices), length(arraySize));

for dim=length(arraySize):-1:1

    subIndices(:,dim)=ceil(linIndices/prod(arraySize(1:dim-1)));

    linIndices=linIndices-(subIndices(:,dim)-1)'*prod(arraySize(1:dim-1));
end

% from file myInd2sub on 12/12/13 at 12:03pm
