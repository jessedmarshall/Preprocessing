function k=displayFrameWithMarkedCells(F, cInd, thisMuX, thisMuY, cvxHulls, neighbors, pausetime, figHandle, neighborsActiveOk, meanNeighborRatio, thisRatioToMeanNeighbor)

figure(figHandle); hold off;

xCoord=max(thisMuX(cInd),1); xCoord=min(xCoord, size(F,2));
yCoord=max(thisMuY(cInd),1); yCoord=min(yCoord, size(F,1));

imagesc(F); hold on; plot(xCoord, yCoord, '*', 'Color', [1 0.2 1]);
plot(cvxHulls{cInd}(:,1), cvxHulls{cInd}(:,2), 'Linewidth', 1.5, 'Color', [1 0.2 1]); drawnow

for neighInd=1:length(neighbors{cInd})
    neighCellInd=neighbors{cInd}(neighInd);
    plot(thisMuX(neighCellInd), thisMuY(neighCellInd), '*', 'Color', [1 1 1]);
    plot(cvxHulls{neighCellInd}(:,1), cvxHulls{neighCellInd}(:,2), 'Linewidth', 1.5, 'Color', [1 1 1]);
end

if neighborsActiveOk
    title(['active times cell ' num2str(cInd) ' | Neighbors Active Ok!'] ); drawnow
else
    title(['active times cell ' num2str(cInd)]); drawnow
end
% if neighborsActiveOk
%     title(['active times cell ' num2str(cInd) ' | Neighbors Active Ok! | meanNeighRat=' num2str(meanNeighborRatio) ' | ratMeanNeigh=' num2str(thisRatioToMeanNeighbor) ] ); drawnow
% else
%     title(['active times cell ' num2str(cInd) ' | meanNeighRat=' num2str(meanNeighborRatio) ' | ratMeanNeigh=' num2str(thisRatioToMeanNeighbor)]); drawnow
% end
pause(pausetime)
% title('mouse click no, key press yes'); drawnow
% k=waitforbuttonpress();
k=1;