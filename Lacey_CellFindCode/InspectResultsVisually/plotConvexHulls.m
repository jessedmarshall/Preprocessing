function plotConvexHulls(cvxHulls, h, varargin)

plotBlack=0;
if ~isempty(varargin)
    options=varargin{1};
    if isfield(options, 'plotBlack')
        plotBlack=options.plotBlack;
    end
end

if mod(h,1)==0
    figure(h)
else
    subplot(h)
end
hold on
for hullInd=1:length(cvxHulls)
    if plotBlack
        plot(cvxHulls{hullInd}(:,1), cvxHulls{hullInd}(:,2), 'k', 'Linewidth', 1.6)
    else
        plot(cvxHulls{hullInd}(:,1), cvxHulls{hullInd}(:,2), 'w', 'Linewidth', 1.6)
    end
end