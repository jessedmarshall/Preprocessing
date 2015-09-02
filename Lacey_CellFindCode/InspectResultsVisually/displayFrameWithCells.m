function hAx=displayFrameWithCells(h, dsImgs,currentFrame,cellROIs,currentCellInd,xLims,yLims,clims,varargin)

options.noTitle=0;
if ~isempty(varargin)
    options=varargin{1};
end

figure(h)
hold off
imagesc(dsImgs(:,:,currentFrame))
set(gca, 'Fontsize', 14)
if ~options.noTitle
    title('L/K fwd/back | O/I fwd/back 20 | P play 20 | D delete | C compare prev. | S mark unsure | M max mode | Q quit')
else
    title('')
end
xlabel(['Frame ' num2str(currentFrame)])
xlim(xLims)
ylim(yLims)
hAx=gca;
set(gca, 'CLim', clims)
hold on
for cInd=1:currentCellInd
    thisBorder=cellROIs{cInd}.border;
    if cellROIs{cInd}.unsure
        plot(thisBorder(:,1), thisBorder(:,2), 'w')
    else
        plot(thisBorder(:,1), thisBorder(:,2), 'k')
    end
end