# biafra ahanonu
# updated: 2013.07.29
# read in training data and parse it out

# load packages
packagesFileList = c("reshape2", "ggplot2", "parallel", "stringr")
lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})

# get input files
srcFileList = c("view/view.footnote.R", "model/model.pav.liquid.parse.R", "helper/helper.getDir.R")
lapply(srcFileList,FUN=function(file){source(file)})

controlller.pav.liquid <- function(...){
	# run main function

	# cd to scripts if on correct computer
	if(length(dir('Z:/biafra/scripts'))!=0){setwd("Z:/biafra/scripts")}

	# Function to get directory info and create folders
	data_dir = "A:/biafra/data/behavior/pav/p92/licking"
	analysis_dir = "../../analysis/biafra/pav/"
	data_dir = "A:/jones/data/behavior/pav/p104"
	data_dir = "A:/jones/data/behavior/Ding_Operant"
	analysis_dir = "../../analysis/jones/operant/"

	data_dir = 'D:/b/Dropbox/schnitzer/data/assays/operant/p215/'
	analysis_dir = "../../analysis/team_bg/p215/"
	data_sub_dir=""
	c(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir=data_dir,dataSubDir=data_sub_dir,analysisDir=analysis_dir)
	# _________________________________________________
	# get files
	fileList = list.files(data_main_dir, full.names=TRUE, include.dirs = FALSE)
	# Extract only the files
	# fileList = matrix(unlist(strsplit(fileList,'/')),nrow=length(strsplit(fileList,'/')[[1]]))[length(strsplit(fileList,'/')[[1]]),]
	print(fileList); flush.console();
	# _________________________________________________
	# Loop over each file, extract data
	result = tryCatch({
		# load clusters, functions, and variables
		startTime = Sys.time()

		# open multiple R workers, leave one logical core available for system processes
		cl = model.cluster()

		# get data for each file in parallel
		pavData = parLapply(cl, fileList, fun=main.pav.fxn)

		# unpack the data and combine into one data.frame
		rawMouseData = lapply(pavData, FUN=function(x){x$rawMouseData})
		rawMouseData = do.call("rbind",rawMouseData)
		animalData = lapply(pavData, FUN=function(x){x$animalData})
		animalData = do.call("rbind",animalData)
	}, error = function(err) {
		print(err)
		print(traceback())
		return(data.frame())
	}, finally = {
		print(Sys.time()-startTime); flush.console();
		# stop the cluster
		stopCluster(cl)
		# return(data.frame())
	})

	# # add for miniscope analysis
	# rawMouseData$subject = rawMouseData$mouse
	# rawMouseData$trialSet = as.numeric(str_extract(rawMouseData$pav,"[[:digit:]]+"))
	# rawMouseData$type = str_extract(rawMouseData$pav, "[[:alpha:]]+")
	# # rawMouseData$trial = as.numeric(str_extract(rawMouseData$pav,"[[:digit:]]+"))
	# rawMouseData$trial = rawMouseData$pav
	# framesPerSec = 5
	# rawMouseData$frame = round(as.numeric(rawMouseData$time)*framesPerSec)
	# framesPerSec = 20
	# rawMouseData$frame20hz = round(as.numeric(rawMouseData$time)*framesPerSec)

	# ggplot(rawMouseData[removeTrials,], aes(x=CStime, y=CSnum))+
	# stat_binhex(bins = 10)+
	# # theme(strip.background = element_rect(fill="red"))+
	# scale_fill_gradient(low="black", high="red")+
	# facet_grid(mouse~pav)

	ggplot(mouseTemp,aes(x=date,y=operantScore,group=mouse,colour=type))+geom_point(aes(size=dayCycle), alpha=0.5)+stat_summary(aes(group=type), fun.y=mean, geom="line", size=2)
	plotmeans(mouseTemp$operantScore~factor(mouseTemp$type))

	ggplot(mouseTemp,aes(x=date,y=operantScore,group=type,colour=type))+
	stat_summary(fun.data = "mean_cl_boot",geom = "errorbar", width=0.1,size=1, alpha=0.3)+
	stat_summary(fun.data = "mean_cl_boot",geom = "point", size=1,shape=15)+
	stat_summary(aes(group=type), fun.y=mean, geom="line", size=1)

	plotmeans(mouseTemp$operantScore~factor(mouseTemp$type))
	# see if significantly different scores
	# fit = aov(operantScore ~ type, data=mouseTemp)
	fit = aov(operantScore ~ type + Error(date/type), data=mouseTemp)
	summary(fit)
	plot(fit)
	# see the pairwise differences
	with(mouseTemp, pairwise.t.test(operantScore, type, p.adjust.method="holm"))

	print(Sys.time()-startTime); flush.console();
	# _________________________________________________
	# save data
	# writeData(animalData,paste(analysis_dir,"lickCount.data",sep=""))
	# writeData(rawMouseData,paste(analysis_dir,"mouseRaw.data",sep=""))
	# print(Sys.time()-startTime); flush.console();
	# _________________________________________________
	output = list()
	output$rawMouseData = rawMouseData
	output$animalData = animalData
	return(output)
}


rawData = controlller.pav.liquid()
animalData = rawData$animalData
rawMouseData = rawData$rawMouseData