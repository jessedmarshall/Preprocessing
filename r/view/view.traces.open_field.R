# biafra ahanonu
# updated: 2013.08.15 [14:01:50]
# compare movement in movie to changes in the trace
#

view.traces.openfield <-function(...){

	newplots=list()
	# plot the location in space and the amount of firing in that space
	ggplot(registeredCsData, aes(time, CSnum, z=PSTH))+stat_summary_hex(bins=26)

	ggplot(multiMouseData,aes(time,distance,color=type))+geom_smooth()+geom_point()+scale_y_log10()+stat_binhex(data=traceSum,mapping=aes(time*3,PSTH, fill=file), bins=100, inherit.aes=FALSE, alpha=0.5)+facet_wrap(~type)


	ggplot(rdata, aes(as.character(mouse), distance))+geom_boxplot(notch=TRUE)+scale_y_log10()

	m377 = getBinnedDistance(rawData[rawData$mouse==m377,], 3692)
	m348 = getBinnedDistance(rawData[rawData$mouse==348,], 3692)
	rdata = rbind(data.frame(distance=m377$mouseDistance,time=m377$timeMouseData[-1:0], mouse=377, diff=c(0,diff(m377$mouseDistance))),data.frame(distance=m348$mouseDistance,time=m348$timeMouseData[-1:0], mouse=348, diff=c(0,diff(m348$mouseDistance))))


	ggplot(rdata, aes(time, diff, color=as.factor(mouse)))+geom_point()
	ggplot(rdata, aes(diff, fill=as.factor(mouse)))+geom_histogram(binwidth=1,alpha=0.5)+scale_y_log10()+facet_wrap(~mouse)


	ggplot(multiMouseData, aes(abs(diff), fill=type))+geom_density(binwidth=1,alpha=0.5)+scale_x_log10()+facet_wrap(~mouse)
	ggplot(multiMouseData, aes(abs(diff), color=as.factor(type)))+geom_density(binwidth=1,alpha=0.5)+scale_x_log10()


	traceSum$diff = c(0, diff(traceSum$PSTH))
	newplots$a= ggplot(traceSum, aes(abs(diff), fill=file))+geom_density(alpha=0.5)+scale_x_log10()
	newplots$b= ggplot(traceSum, aes(abs(diff),y=..density.., fill=file))+geom_histogram(alpha=0.5, position="dodge")+scale_x_log10()

	# name new plots
	lapply(newplots, FUN=function(x){dev.new();print(x)})
}

if(plotGraphs==FALSE){
	newplots = list()

	newRawData = data.frame(first=rawData$Velocity[0:(length(rawData$Velocity)-1)], second=rawData$Velocity[-1:0], type=rawData$type[0:(length(rawData$type)-1)])

	newplots$a = ggplot(newRawData,aes(first,second,fill=type))+stat_smooth(n=30)+stat_binhex(alpha=0.4)
	#+scale_fill_gradient(name = "count", trans = "log")

	newplots$b = ggplot(rawData,aes(X.center,Y.center,group=type))+stat_binhex()+facet_grid(experiment~type)+scale_fill_gradient(low="black", high="red")

	newplots$c = ggplot(multiMouseData,aes(time,distance,color=type))+geom_smooth()+geom_point()+scale_y_log10()
	newplots$d = ggplot(multiMouseData,aes(time,distance,color=type))+geom_smooth()+geom_point()+scale_y_log10()+facet_grid(experiment~.)

	newplots$e = ggplot(rawData,aes(Trial.time,Velocity))+geom_line()

	newplots$f = ggplot(rawData,aes(X.center,Y.center))+
	stat_binhex()+
	facet_wrap(~mouse)+
	theme(strip.background = element_rect(fill="red"))+
	scale_fill_gradient(low="black", high="red", trans = 'log')+
	xlim(-2.5,2.5)+
	ylim(-2.5,2.5)

	lapply(newplots, FUN=function(x){dev.new();print(x)})
}