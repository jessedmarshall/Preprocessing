function foundCellInd = identifyFoundCell(h,cellROIs,currentCellInd)

figure(h); title('Select cell please')
[x,y]=ginput(1);
minDistFound=10000;
foundCellInd=0;
for cInd=1:currentCellInd
    thisDist=norm(cellROIs{cInd}.centroid - [x y]);
    if thisDist<minDistFound
        foundCellInd=cInd;
        minDistFound=thisDist;
    end
end