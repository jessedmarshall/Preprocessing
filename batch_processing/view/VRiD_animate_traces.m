function VRiD_animate_traces()
	% animate a 2D trace of the flies path, could potential be used to make a movie of the flies movement while showing stimulus and the fly
	% biafra ahanonu
	% started: 2011.05.08 - @janelia
	% inputs
		%
	% outputs
		%
	% changelog
		%
	% TODO
		%

	v=find(v_rotation_fly);
	g(1:length(v))=v_rotation_fly(v');
	h=cumsum(g);
	figure(7);
	comet(cumsum(g));
	%The below stores each 'frame' of the plot as a matlab movie file, this
	%takes up a lot of memory, probably a better way
	for i=1:length(g)
	plot(h(1:i));
	%z(i)=getframe(figure(7));
	end