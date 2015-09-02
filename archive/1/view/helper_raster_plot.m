% biafra ahanonu
% 2013.02.28
% makes spike figures
%% helper_raster_plot: give a [M x N] matrix of [Spike Times x Cells] and outputs a raster plot of the data
function [data] = helper_raster_plot(data)
	m=length(data);
	% data=reshape(rand(m)*100,m*m,1)';
	% data=rand(m)*100;
	set(gcf,'color','w');
	plot(nan,nan);
	colors = hsv(100);
	colors = reshape(colors(randperm(numel(colors))),size(colors))
	hold on
	seq=(1:m)
	for i=seq(randperm(numel(seq)))
		quiver(data(:,i)',i*ones(1,length(data)),zeros(1,length(data)),ones(1,length(data)),0,'.','Color',colors(i,:),'LineWidth',2);
	end
	hold off
	xlim([-1 101]);
	ylim([0 m+1]);
	xlabel('time (msec)');
	ylabel('cell');
	title('Spike times in DMS');
	set(gca, 'box','off');
	set(gca,'ytick',[],'xtick',[]);
	% set(gca,'color','none')
end