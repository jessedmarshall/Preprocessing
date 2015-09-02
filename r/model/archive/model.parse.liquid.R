# biafra ahanonu
# updated: 2013.07.21
# read in training data and parse it out
model.parse.liquid <- function(){
	# setwd("Z:/biafra/scripts")
	#________________________________________________________
	# Load libraries and dependencies
	library(ggplot2)
	source("view.footnote.R")
	#________________________________________________________
	# Get data directory
	data_dir = "./"
	data_sub_dir=""
	data_main_dir = paste(data_dir,data_sub_dir,sep="")
	data_main_dir = gsub("\\\\","/",choose.dir(default=getwd(),caption="select directory to analyze"))
	# If user gives no input, go to default directory
	data_main_dir = ifelse(is.na(data_main_dir), paste(data_dir,data_sub_dir,sep=""), data_main_dir)
	print(paste("Data directory:",data_main_dir))
	# _________________________________________________
	# Get analysis directory
	analysis_dir = "./"
	analysis_dir = gsub("\\\\","/",choose.dir(default=getwd(),caption="select directory to output data"))
	# If user gives no input, go to default directory
	analysis_dir = ifelse(is.na(analysis_dir), "../analysis/", analysis_dir)
	# Analysis stored in dated sub-directory
	current_date = format(Sys.Date(), format="%Y_%m_%d")
	dir.create(file.path(analysis_dir, current_date),showWarnings=FALSE)
	analysis_dir = paste(analysis_dir,"/",current_date,"/",sep="")
	print(paste("Analysis directory:",analysis_dir))
	# Create analysis directory
	dir.create(file.path(analysis_dir),showWarnings=FALSE)
	# analysis_dir_run_id = format(Sys.time(), format="%H%M%S")
	# analysis_dir = paste(analysis_dir,analysis_dir_run_id,"/",sep="")
	# _________________________________________________
	# get files
	# Ask for user input
	# files = dir(data_main_dir)[grep("A[[:digit:]]",dir(data_main_dir))]
	# files = gsub("\\\\","/",choose.files(default=paste(data_main_dir,"/0",sep=""),caption="select files to analyze",multi=TRUE))
	files = dir(data_main_dir)
	# Extract only the files
	files = matrix(unlist(strsplit(files,'/')),nrow=length(strsplit(files,'/')[[1]]))[length(strsplit(files,'/')[[1]]),]
	# _________________________________________________
	# Loop over each file, extract data
	animalData = data.frame()
	rawMouseData = data.frame()
	sessionNum = 1
	for (file in files) {
		print(file)
		# obtain raw data for each file
		outputData = getRawMouseData(file,paste(data_main_dir,'/',sep=""))
		lickCount = outputData$lickCount
		animalData = getLickMetric(file, animalData, lickCount)
		# get raw output
		rawOutput = outputData$raw
		rawOutput$session = sessionNum
		rawMouseData = rbind(rawMouseData,rawOutput)
		sessionNum = sessionNum + 1
	}
	# _________________________________________________
	# save plots
	newPlot = ggplot(animalData,aes(date,lickMetric,colour=id,group=id))+geom_line()+geom_point()+facet_grid(lickMetricType~group,scale="free")+theme(axis.text.x = element_text(angle = 90, hjust = 1))+ggtitle("Pav Conditioning Lick Metric")
	pngSave(newPlot,paste(analysis_dir,"pav_condition_licks.png",sep=""))
	newPlot = ggplot(mouseRaw[mouseRaw$CStype!=FALSE,],aes(CStime,fill=CStype))+geom_histogram()+facet_wrap(~session)
	pngSave(newPlot,paste(analysis_dir,"pav_lick_count_facet.png",sep=""))
	# _________________________________________________
	# save data
	writeData(animalData,paste(analysis_dir,"lickCount.data",sep=""))
	writeData(rawOutput,paste(analysis_dir,"mouseRaw.data",sep=""))
	# _________________________________________________
	output = list()
	output$rawMouseData = rawMouseData
	output$animalData = animalData
	return(output)
}
pngSave <- function(plotData,file,width=2500,height=2500,title="",rotX=FALSE,footnote="") {
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
writeData <- function(data, file){
	print(file)
	write.table(data,file=file ,sep="\t",col.names=T)
}
getRawMouseData <- function(file,data_main_dir,constants){
	# Number of lines to skip before event times
	INTROLINES = 0
	# Max number of rows to read in
	MAXROWS = Inf
	# How many columns to split file into and their data types
	COLCLASS = c("character","character","character","numeric","numeric","numeric")
	# Identifier for events data group
	EVENTS_ID = 'I:'
	# Identifier for timestamp data group
	TIMESTAMP_ID = 'T:'
	# magazine lick
	LICK_ID = 24
	# conditioned stimulus ON
	CS_ON_ID = 30
	# conditioned stimulus OFF
	CS_OFF_ID = 31
	# centi to seconds
	TIMECONVERT = 100
	# Amount of seconds to look before the cue
	PRECUETIME = 10
	# _________________________________________________
	# Import data, split into five rows
	mouseRawData = read.table(paste(data_main_dir,file,sep=""),header=F,skip=INTROLINES,nrows=MAXROWS,fill=TRUE,colClasses=COLCLASS,comment.char = "\\")
	# Rename columns
	names(mouseRawData) = paste("V",c(1:5),sep="")
	# print(mouseRawData)
	# _________________________________________________
	mouseEventTimes = getMouseEventTimes(mouseRawData, EVENTS_ID, TIMESTAMP_ID, TIMECONVERT)
	# _________________________________________________
	# Get row numbers for all conditioned stimulus trials
	csTrials = which(mouseEventTimes$events==CS_ON_ID)#CS_ON_ID
	lickCount = data.frame()
	for (csTrial in csTrials){
		trialCounts = list()
		# Get CS, pre-CS and post-CS times
		timeCS = mouseEventTimes$time[csTrial]
		timePre = timeCS-PRECUETIME
		timePost = timeCS+PRECUETIME
		# Get the pre-cue indices/events
		preCueIndx = (mouseEventTimes$time<timeCS)&(mouseEventTimes$time>=timePre)
		postCueIndx = (mouseEventTimes$time>timeCS)&(mouseEventTimes$time<=timePost)
		# add identification of cue to raw table
		mouseEventTimes$CStype[preCueIndx] = 'preCue'
		mouseEventTimes$CStype[postCueIndx] = 'postCue'
		mouseEventTimes$CStime[preCueIndx] = mouseEventTimes$time[preCueIndx] - timeCS
		mouseEventTimes$CStime[postCueIndx] = mouseEventTimes$time[postCueIndx] - timeCS
		mouseEventTimes$CSnum[preCueIndx] = csTrial
		mouseEventTimes$CSnum[postCueIndx] = csTrial
		# Get number of pre-cue events that are licks
		trialCounts$time = timeCS
		trialCounts$precounts = sum(mouseEventTimes[preCueIndx,]$events==LICK_ID)
		trialCounts$postcounts = sum(mouseEventTimes[postCueIndx,]$events==LICK_ID)
		trialCounts$cs = which(csTrials==csTrial)
		lickCount = rbind(lickCount,data.frame(trialCounts))
	}
	output = list()
	output$lickCount = lickCount
	output$raw = mouseEventTimes
	return(output)
}
getMouseEventTimes <- function(mouseRawData, EVENTS_ID, TIMESTAMP_ID, TIMECONVERT){
	for (dataID in c(EVENTS_ID,TIMESTAMP_ID)) {
		# Get row index for events
		eventsStartLine = which(mouseRawData$V1==dataID)
		# Get row index for all data group types
		groupLocations = which(mouseRawData$V1 %in% paste(LETTERS,":",sep=""))
		# Get stop line for events
		eventsStopLine = groupLocations[which(groupLocations==eventsStartLine)+1]
		# print(paste(eventsStartLine,groupLocations,eventsStopLine))
		# Get all the events from the matrix
		mouseRawDataMod = mouseRawData[(eventsStartLine+1):(eventsStopLine-1),]
		if(dataID==EVENTS_ID){
			# Reshape to a 1xn vector
			mouseEvents = as.integer(as.vector(t(mouseRawDataMod[,2:6])))
		}else if(dataID==TIMESTAMP_ID){
			# Reshape to a 1xn vector
			mouseTimestamps = as.numeric(as.vector(t(mouseRawDataMod[,2:6])))/TIMECONVERT
		}
	}
	# _________________________________________________
	# Combine into one dataframe
	mouseEventTimes = data.frame(cbind(mouseEvents,mouseTimestamps))
	names(mouseEventTimes) = c('events','time')
	# Remove NaNs
	if(sum(is.na(mouseEventTimes))>0){
		mouseEventTimes = mouseEventTimes[1:(which(is.na(mouseEventTimes))[1]-1),]
	}
	mouseEventTimes$CStype = FALSE
	mouseEventTimes$CStime = FALSE
	mouseEventTimes$CSnum = FALSE

	return(mouseEventTimes)
}
getLickMetric <- function(file, animalData, lickCount){
	# calculates the lick metric based on counts from file

	# Get animal information from filename
	animalTempInfo = list()
	animalInfo = strsplit(file,"-")[[1]]
	animalTempInfo$date = animalInfo[1]
	animalTempInfo$group = ifelse(!is.na(animalInfo[3]), animalInfo[3], 'GRPNA')
	animalTempInfo$id = animalInfo[2]

	# Add lick metrics to the list
	animalTempInfo$postcount = sum(lickCount$postcount)
	animalTempInfo$precount = sum(lickCount$precount)
	for (type in c("ratio","diff")) {
		if(type=="ratio"){
			animalTempInfo$lickMetric = sum(lickCount$postcount)/sum(lickCount$precount)
		}else if(type=="diff"){
			animalTempInfo$lickMetric = (sum(lickCount$postcount)-sum(lickCount$precount))/(sum(lickCount$postcount)+sum(lickCount$precount))
		}
		animalTempInfo$lickMetricType = type
		# Convert list to data.frame and add to data.frame with all data, row-wise to aid later analysis
		animalData = rbind(animalData,data.frame(animalTempInfo))
	}

	return(animalData)
}