function cellFitParams = gridInitialize(imgs)

centroidSpacing=10;
defaultWidth=3.5;

xCoords=-(centroidSpacing/2):centroidSpacing:size(imgs,2)+(centroidSpacing/2);
yCoords=-(centroidSpacing/2):centroidSpacing:size(imgs,1)+(centroidSpacing/2);

[xCentroids, yCentroids]=meshgrid(xCoords,yCoords);

evenRows=2:2:size(xCentroids,1);

xCentroids(evenRows,:)=xCentroids(evenRows,:)+centroidSpacing/2;

nGaussians=numel(xCentroids);
cellFitParams=[xCentroids(:), yCentroids(:), defaultWidth*ones(nGaussians,2), zeros(nGaussians,1)]; 

