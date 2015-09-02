# biafra ahanonu
# updated: 2013.11.30 [18:28:03]
# display plots for lick for light
# view.pav.liquid(animalData, rawMouseData, analysis_dir)
view.pav.liquid_light <- function(animalData, rawMouseData, analysis_dir){
	# animalData$pavType = str_extract(animalData$pav, "[[:upper:]]+")
	# animalData$pavNum = str_extract(animalData$pav, "[[:digit:]]+")
	animalData$pavNum = gsub("L4LL","",animalData$pav)
	rawMouseData$pavNum = gsub("L4LL","",rawMouseData$pav)

	positions <- data.frame(
	  id = c(1,1,1,1),
	  x = c(0,0,15,15),
	  y = c(0,150,150,0)
	)

	newPlot = ggplot(rawMouseData[rawMouseData$CStime!=0&(rawMouseData$events==24|rawMouseData$events==25),],aes(CStime,color=lightON))+
		geom_freqpoly(binwidth = 1, size=1)+
		theme(line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
		# geom_vline(xintercept = 0, color='black', alpha=0.3)+
		# geom_vline(xintercept = 15, color='red', alpha=0.3)+
		geom_polygon(data=positions,inherit.aes=FALSE,aes(x=x,y=y),alpha=0.3)+
		geom_vline(xintercept = 30, color='red')+
		xlab('time relative to first rewarded lick (seconds)')+
		ylab('licks')+
		facet_grid(pavNum~mouse)
		# makeFootnote("CStime = aligned to first rewarded lick")
	pngSave(newPlot,paste(analysis_dir,"L4LL_licks_trials.png",sep=""), width=2000, height=1000,footnote='shaded area = duration of light pulse')

	# get licks per trial
	getLicksInterval <- function(x){
		# print(head(x))
		# nTrials = max(x$CSnum)
		thisFilter = (x$events==24|x$events==25)&(x$CStime<=15&x$CStime>=0)
		nLicks = length(x[thisFilter,]$events)
		return(data.frame(licks=nLicks,x[1,]))
	}
	trialLicks = by(rawMouseData,list(rawMouseData$pav,rawMouseData$mouse,rawMouseData$lightON,rawMouseData$CSnum),FUN=getLicksInterval)
	trialLicks = do.call("rbind",trialLicks)
	# ggplot(trialLicks,aes(pav,licks,fill=lightON))+geom_bar(position="dodge")+facet_wrap(~mouse)

	# create functions to get the lower and upper bounds of the error bars
	stderr <- function(x){sqrt(var(x,na.rm=TRUE)/length(na.omit(x)))}
	lowsd <- function(x){return(mean(x)-stderr(x))}
	highsd <- function(x){return(mean(x)+stderr(x))}

	# create a ggplot
	newPlot = ggplot(trialLicks,aes(pavNum,licks,fill=lightON))+
		# first layer is barplot with means
		stat_summary(fun.y=mean, geom="bar", position=position_dodge(), color='white')+
		# second layer overlays the error bars using the functions defined above
		stat_summary(fun.y=mean, fun.ymin=lowsd, fun.ymax=highsd, geom="errorbar", position=position_dodge(.9),color = 'black', size=1.5, width=0.2)+
		theme(line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
		xlab('trial')+
		ylab('licks/trial')+
		facet_wrap(~mouse)+
		ggtitle('Per trial licks, 15 seconds post reward')
		# makeFootnote("number of licks for 15 seconds after first rewarded lick")
	pngSave(newPlot,paste(analysis_dir,"L4LL_barplot.png",sep=""), width=1500, height=800, footnote='number of licks for 15 seconds after first rewarded lick')

	newPlot = ggplot(rawMouseData[rawMouseData$CStime!=0&(rawMouseData$events==24|rawMouseData$events==25),],aes(CStime,fill=CStype))+
	geom_histogram(binwidth=1)+
	geom_polygon(data=positions,inherit.aes=FALSE,aes(x=x,y=y),alpha=0.3)+
	theme(line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
	geom_vline(xintercept = 30, color='red')+
	xlab('time relative to first rewarded lick (seconds)')+
	ylab('licks')+
	facet_grid(mouse~pavNum)
	pngSave(newPlot,paste(analysis_dir,"L4LL_lick_count_facet.png",sep=""), width=2000, height=1000)

	removeTrials = (rawMouseData$events==24|rawMouseData$events==25)
	rawMouseData$lightONBinary = as.numeric(rawMouseData$lightON=="yes")
	rawMouseData$lightONBinary[rawMouseData$lightONBinary==0] = -1
	newPlot = ggplot(rawMouseData[removeTrials,], aes(x=CStime, y=CSnum, z=lightONBinary))+
	# stat_summary2d()+
	stat_summary2d(fun=function(z){return(sum(z))}, bin=30)+
	scale_fill_gradient2(low="red", mid = "white", high="blue")+
	theme(line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
	geom_vline(xintercept = 0, color='black')+
	geom_vline(xintercept = 30, color='red')+
	xlab('time relative to first rewarded lick (seconds)')+
	ylab('trial')+
	facet_grid(mouse~pavNum)
	pngSave(newPlot,paste(analysis_dir,"L4LL_lick_count_facet_trials.png",sep=""), width=3000, height=1500,footnote='blue = laser is on, red = laser is off')
}