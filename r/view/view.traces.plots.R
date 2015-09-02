plotTraceData <- function(...){
	newplots = list()
	# plot traces
	newplots$a = ggplot(traceDataSpikes,aes(variable,value))+
	geom_point(aes(color=id))+
	geom_vline(data=eventData,aes(xintercept=timeCorrected), color="red")

	# plot PSTH
	newplots$b = ggplot(traceSum,aes(time,PSTH))+
	geom_line()+
	geom_vline(data=eventData,aes(xintercept=timeCorrected), color="green")+
	geom_vline(data=eventData,aes(xintercept=timeCorrected+50), color="red")

	# plot PSTH registered to CS
	newplots$c = ggplot(registeredCsData, aes(time,PSTH, color=eventType))+
	geom_dotplot(stackgroups = TRUE, binwidth = 1, method = "histodot")
	facet_wrap(~CSnum)

	# histogram of spiking during different times
	newplots$d = ggplot(registeredCsData, aes(eventType, fill=eventType))+geom_histogram(binwidth=15)+facet_wrap(~CSnum)

	# boxplot showing post-CS response
	newplots$e = ggplot(registeredCsData, aes(eventType, PSTH))+geom_boxplot(notch=TRUE)+scale_y_log10()

	# look at the pair-wise t.tests
	pairwise.t.test(registeredCsData$PSTH, registeredCsData$eventType)

	# look at pairwise t-test for aggregated data
	pairwise.t.test(rDataAggregated$PSTH, rDataAggregated$eventType)

	newplots$f = ggplot(registeredCsData, aes(PSTH, fill=eventType))+geom_density(alpha=0.3)+scale_x_log10()

	newplots$g = ggplot(thisEventData, aes(CStype, fill=CStype))+geom_histogram(alpha=0.5)+geom_histogram(data=registeredCsData, aes(eventType, fill=eventType), alpha=0.2, color="black")+scale_y_log10()+facet_wrap(~CSnum)

	# get the autocorrelation of each files data
	acfData = do.call('rbind',by(traceSum, traceSum$file, FUN=function(x){v=acf(x$PSTH);data.frame(acf=v$acf, lag=v$lag, pav=x$pav[1], file=x$file[1], type='normal')}))
	acfData = rbind(acfData, do.call('rbind',by(traceSum, traceSum$file, FUN=function(x){v=acf(sample(x$PSTH));data.frame(acf=v$acf, lag=v$lag, pav=x$pav[1], file=x$file[1],  type='shuffled')})))
	# plot the data
	newplots$h = ggplot(acfData, aes(lag,acf, color=pav))+geom_line()+scale_colour_brewer(palette="Set1")+facet_wrap(~type)+theme(legend.position="bottom")

	#
	newplots$i = ggplot(traceSum, aes(x=time, y=pav, z=PSTH))+stat_summary2d(fun=function(z){log(z)}, bins=200)
	newplots$j = ggplot(traceSum, aes(time, PSTH))+geom_line()+facet_grid(pav~.)

	# analyze the sum traces
	newplots$k = ggplot(registeredCsDataALL, aes(time, PSTH, color=eventType))+geom_line()+facet_grid(pav~., scale="free")

	# analyze all traces
	# match variable names between data.frames
	traceDataSpikes$pav = gsub("0", "", traceDataSpikes$pav)
	traceDataSpikes$pav = gsub("pav", "PAV_", traceDataSpikes$pav)
	newplots$l = ggplot(traceDataSpikes, aes(x=frame, y=id, z=spikes))+stat_summary2d(fun=function(z){z}, bin=400)+geom_vline(data=eventDataCSOnly[eventDataCSOnly$pav %in% unique(traceDataSpikes$pav),],aes(xintercept=framesCorrected), color="red")+facet_grid(pav~., scale="free")


	# m <- mtcars[1:20, ];
	lick$br <- cut(lick$time,hist(lick$time,10,plot=F)$breaks);
	mean.PSTH <- tapply(lick$PSTH,lick$br,mean);
	lick2 <- data.frame(time.bin=names(mean.PSTH),mean.PSTH);
	ggplot(lick2,aes(x=time.bin,y=mean.PSTH)) + geom_bar();

	# name new plots
	lapply(newplots, FUN=function(x){dev.new();print(x)})

	return(TRUE)
}
pngSave <- function(plotData,file,width=3200,height=1800,title="",rotX=FALSE,footnote="") {
	png(file,width=width,height=height,res=200,pointsize=10,antialias="cleartype")
		if(rotX==TRUE){
		plotData = plotData + theme(axis.text.x = element_text(angle = 90, hjust = 1))
		}
		plotData = plotData + ggtitle(title)
		print(plotData)
		makeFootnote(footnoteText=footnote)
	dev.off()
	print(file)
}

# plot the trace data
plotTraceData(traceDataSpikes, traceSum, registeredCsData, eventData, eventDataRaw, rDataAggregated)

# shuffle spikes and licks then and replot
# plotTraceData(traceDataSpikes, traceSum, registeredCsData, eventData, eventDataRaw)