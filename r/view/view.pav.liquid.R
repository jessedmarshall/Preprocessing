# biafra ahanonu
# 2013.11.23 [14:06:45]
#
srcFileList = c("view/view.footnote.R", "helper/helper.io.image.save.R", "helper/helper.getDir.R")
lapply(srcFileList,FUN=function(file){source(file)})

# load packages
packagesFileList = c("reshape2", "ggplot2", "parallel", "stringr","lattice")
lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})

view.pav.liquid <- function(animalData, rawMouseData, analysis_dir){
# _________________________________________________
# save plots

	animalData$pavType = str_extract(animalData$pav, "[[:upper:]]+")
	animalData$pavNum = str_extract(animalData$pav, "[[:digit:]]+")
	pavIdx = grep("(MAG|PAV(|Q)|(Q|)EXT|REN|SCH|SUL|TROP|D|HAL)", animalData$pav)
	# pavIdx = (animalData$mouse==961|animalData$mouse==652)&animalData$lickMetricType=="difference"&(str_extract(animalData$pav, "[[:upper:]]+") %in% c("PAV","QEXT","REN","SCH","SUL","TROP"))

	newPlot =
	ggplot(animalData[pavIdx,],aes(pavNum,lickMetric))+
	geom_boxplot(aes(group=pavNum),alpha=0.3,colour="grey")+
	geom_hline(aes(yintercept=0), color="red")+
	geom_line(aes(group=mouse,colour=mouse))+
	# stat_summary(aes(group=mouse,colour=mouse), fun.y=mean, geom="line", alpha=0.8)+
	# stat_summary(aes(group=lickMetricType), fun.data = "mean_cl_boot",geom = "errorbar", color="black", size=2, alpha=0.8)+
	# stat_summary(aes(group=lickMetricType), fun.data = "mean_cl_boot",geom = "line", color="black", size=2, alpha=0.8)+
	# geom_smooth(aes(group=lickMetricType),fill="black",size=1,alpha=0.8)+
	# stat_summary(aes(group=mouse), fun.y=mean, geom="point", alpha=0.8)+
	# stat_summary(aes(group=lickMetricType), fun.y=mean, geom="line", color="black", size=2, alpha=0.8)+
	theme(line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
	# scale_colour_discrete(color = sample(colors(10),length(unique(animalData$pav))))+
	# scale_colour_gradientn(colours = rainbow(length(unique(animalData$pav))))+
	scale_colour_discrete(l=50, c=150)+
	# scale_colour_brewer(palette="Set3")+
	# geom_smooth(aes(group=lickMetricType), size=0.5, fill="grey", color="black")+
	facet_grid(lickMetricType~pavType,scale="free", space = "free_x")
	pngSave(newPlot,paste(analysis_dir,"pav_condition_licks.png",sep=""), title="Pav Conditioning Lick Metric", width=6000, height=3000)

	# # =================================
	newPlot =
	ggplot(animalData,aes(pav,lickRate,color=mouse,group=mouse))+
	geom_point()+
	geom_line()+
	ylab('licks/second')+
	xlab('')+
	theme(line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))
	pngSave(newPlot,paste(analysis_dir,"pav_condition_lickRate.png",sep=""), title="pav conditioning, whole trial lick rate", width=1200, height=700,rotX=TRUE)

	# # =================================
	newPlot = ggplot(rawMouseData[rawMouseData$CStime!=0&rawMouseData$events==24,],aes(CStime,fill=CStype))+
	geom_histogram(binwidth=1)+
	theme(line = element_blank(), axis.text.x=element_blank(), strip.background = element_rect(fill = '#005FAD'), panel.background = element_rect(fill = "white", colour = NA),strip.text.x = element_text(size = 8, angle = 90, colour = "white"),strip.text.y = element_text(size = 8, colour = "white"))+
	facet_grid(mouse~pav)
	pngSave(newPlot,paste(analysis_dir,"pav_lick_count_facet.png",sep=""), width=1600, height=900)

	# # =================================
	removeTrials = rawMouseData$events==24&!(round(rawMouseData$CStime,2) %in% c(10.96, 10.95))
	newPlot = ggplot(rawMouseData[removeTrials,], aes(x=CStime, y=CSnum, z=events))+
	stat_summary2d(fun=function(z){return(log(sum(z>0)+1))}, bin=30)+
	geom_vline(xintercept = 0, color='red')+
	geom_vline(xintercept = 10, color='red')+
	scale_fill_gradient2(low="white", mid = "black", high="red")+
	# scale_fill_continuous(low="white", high="black")+
	theme(line = element_blank(), axis.text.x=element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
	facet_grid(mouse~pav)
	pngSave(newPlot,paste(analysis_dir,"pav_lick_count_facet_trials.png",sep=""), width=6000, height=3000)


	for (lickMetricTypes in c("difference","normRatio")) {
		# tTestValues = !(str_extract(animalData$pav, "[[:upper:]]+") %in% c("MAG","PAV","PAVQ","NA"))&animalData$lickMetricType==lickMetricTypes
		tTestValues = (str_extract(animalData$pav, "[[:upper:]]+") %in% c("MAG","PAV","PAVQ","NA"))&animalData$lickMetricType==lickMetricTypes
		tTestValues = tTestValues&!(animalData$pav %in% c("SCH04","SCH03"))
		tTestValues = tTestValues|(str_extract(animalData$pav, "[[:upper:]]+[[:digit:]]+") %in% c("PAV01","PAV1","PAV7","PAV07"))&animalData$lickMetricType==lickMetricTypes
		sink(paste(analysis_dir,"pav_lick_t_tests_",lickMetricTypes,".txt",sep=""), append=TRUE, split=TRUE)
		print(with(animalData[tTestValues,], pairwise.t.test(lickMetric,pav, p.adjust.method="none", paired=FALSE, pool.sd=FALSE)))
		sink(NULL)

		zzz = with(animalData[tTestValues,], pairwise.t.test(lickMetric,pav, p.adjust.method="none", paired=FALSE, pool.sd=FALSE))
		# -log10(zzz[['p.value']])
		newPlot = levelplot(10/zzz[['p.value']],main = 't-test for pav trials | values are 10/p-value, so p<0.05 is p>200',xlab='',ylab='',col.regions = colorRampPalette(c("white",
		"red")),
			panel=function(...) {
			arg <- list(...)
			panel.levelplot(...)
			panel.text(arg$x, arg$y, ifelse(is.na(round(arg$z,1)), '', round(arg$z,1)))
					})
		pngSaveNormal(newPlot,paste(analysis_dir,"pav_lick_t_tests_",lickMetricTypes,".png",sep=""), title="Pav Conditioning Lick Metric")
	}
	# ggplot(mouseTemp,aes(x=date,y=operantScore,group=mouse,colour=type))+geom_point(aes(size=dayCycle), alpha=0.5)+stat_summary(aes(group=type), fun.y=mean, geom="line", size=2)

	# ggplot(rawMouseData[removeTrials,], aes(x=CStime, y=CSnum))+
	# stat_binhex(bins = 10)+
	# # theme(strip.background = element_rect(fill="red"))+
	# scale_fill_gradient(low="black", high="red")+
	# facet_grid(mouse~pav
}