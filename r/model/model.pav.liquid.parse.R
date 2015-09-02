# biafra ahanonu
# updated: 2013.07.29
# read in training data and parse it out

model.cluster <-function(...){
	# opens a cluster
	logFile = 'log.txt'
	# unlink (delete) the log file before starting
	unlink(logFile)
	# open multiple R workers, leave one logical core available for system processes
	cl = makeCluster(detectCores()-1, outfile=logFile)
	# pass scripts/packages to clusters
	clusterEvalQ(cl, {
		srcFileList = c("model/model.pav.liquid.parse.R")
		lapply(srcFileList,FUN=function(file){source(file)})
		packagesFileList = c("reshape2")
		lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})
	})
	# pass data(bases) to clusters
	# clusterExport(cl, c("dataMainDir","eventFile"))
	return(cl)
}

main.pav.fxn <-function(file){
	print(file); flush.console();
	# get constant values
	CON = getRawConstantValues()
	# obtain raw data for each file
	outputData = getRawMouseData(file,CON)
	CON$NUMCSEVENTS = outputData$NUMCSEVENTS
	lickCount = outputData$lickCount
	animalData = data.frame()
	animalData = getLickMetric(file, animalData, lickCount, CON)
	# get raw output
	rawOutput = outputData$raw
	# add the lick rate
	vecLen = length(rawOutput$time)
	animalData$trialTime = rawOutput$time[vecLen]
	animalData$lickRate = animalData$count/animalData$trialTime
	# rawOutput$session = sessionNum
	rawOutput$file = file
	rawMouseData = rawOutput
	# rawMouseData = rbind(rawMouseData,rawOutput)
	# sessionNum = sessionNum + 1
	return(list(rawMouseData=rawMouseData, animalData=animalData))
}
getFileInfo <-function(input){
	# gets file info, assumes input is a data.frame with column 'file'
	# print(input)
	input$pav = str_extract(input$file, "(MAG|PAV(|-PROBE)|(Q|)EXT|REN|REINST|S(HC|CH)|SUL(|P)|SAL|TROP|D|HAL)\\d+")
	print(sort(unique(input$pav))); flush.console();
	# sub for name convention consistency
	input$pav = gsub("PAV-PROBE","PAVQ",input$pav)
	input$pav = gsub("SAL","SCH",input$pav)
	input$pav = gsub("SULP","SUL",input$pav)
	input$pav = gsub("SHC","SCH",input$pav)
	input$pav = gsub("REINST","REN",input$pav)
	input$pav = gsub("EXT","QEXT", input$pav)
	input$pav = gsub("D","QD", input$pav)
	input$pav = gsub("HAL","QHAL", input$pav)
	# make sure strings starts at 01 instead of 1 for correct ordering
	pavNameList = str_extract(input$pav, "[[:alpha:]]+")
	pavDigitList = as.numeric(str_extract(input$pav,"[[:digit:]]+"))
	pavDigitIdx = pavDigitList<10|is.na(pavDigitList)
	pavDigitList = as.character(pavDigitList)
	pavDigitList[pavDigitIdx] = paste("0",pavDigitList[pavDigitIdx],sep="")
	input$pav = paste(pavNameList, pavDigitList, sep="")

	# input$date = str_extract(input$file, "\\d{4}_\\d{2}_\\d{2}")
	date = str_extract(input$file, "(\\d{6}|\\d+_\\d+_\\d+)")
	trueDate=date
	dates=as.Date(trueDate, format="%Y_%m_%d")
	dates[is.na(dates)] = as.Date(dates[is.na(dates)],"%y%m%d")
	# for(i in 1:length(dates)){
	# 	idate = dates[i]
	# 	if(is.na(idate)){
	# 		dates[i]=as.Date(trueDate[i],"%y%m%d")
	# 	}
	# }
	date = dates

	input$mouse = as.character(gsub("(m|M|f|F)","",str_extract(input$file, "(m|M|f|F)\\d+")))
	input$protocol = as.numeric(gsub("p","",str_extract(input$file, "p\\d+")))
	return(input)
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
writeData <- function(data, file, sep="\t"){
	print(file)
	write.table(data, file=file, sep=sep, col.names=TRUE, row.names=FALSE)
}
getRawConstantValues <- function(){
	CON = list()
	# Number of lines to skip before event times
	CON$INTROLINES = 0
	# Max number of rows to read in
	CON$MAXROWS = Inf
	# How many columns to split file into and their data types
	CON$COLCLASS = c("character","character","character","numeric","numeric","numeric")
	# Identifier for events data group
	CON$EVENTS_ID = 'I:'
	# Identifier for timestamp data group
	CON$TIMESTAMP_ID = 'T:'
	# magazine lick
	CON$LICK_ID = 24
	# conditioned stimulus ON
	CON$CS_ON_ID = 30
	# conditioned stimulus OFF
	CON$CS_OFF_ID = 31
	# centi to seconds
	CON$TIMECONVERT = 100
	# ITI seconds to analyze
	CON$ITITIME = 60
	# seconds pre-CS to analyze
	CON$PRECUETIME = 30
	# seconds post-CS to analyze
	CON$POSTCUETIME = 10
	# seconds post-US to analyze
	CON$POSTUSTIME = 20
	# seconds to minutes
	CON$SECTOMIN = 60

	return(CON)
}
getRawMouseData <- function(file,CON){
	# _________________________________________________
	# Import data, split into five rows
	mouseRawData = read.table(file,header=F,skip=CON$INTROLINES,nrows=CON$MAXROWS,fill=TRUE,colClasses=CON$COLCLASS,comment.char = "\\")
	# Rename columns
	names(mouseRawData) = paste("V",c(1:5),sep="")
	# print(mouseRawData)
	# _________________________________________________
	mouseEventTimes = getMouseEventTimes(mouseRawData, CON$EVENTS_ID, CON$TIMESTAMP_ID, CON$TIMECONVERT)
	# _________________________________________________
	# Get row numbers for all conditioned stimulus trials
	csTrials = which(mouseEventTimes$events==CON$CS_ON_ID)#CS_ON_ID
	lickCount = data.frame()
	currentTrial = 1
	for (csTrial in csTrials){
		trialCounts = list()
		# Get CS, pre-CS and post-CS times
		timeCS = mouseEventTimes$time[csTrial]
		timePre = timeCS-CON$PRECUETIME
		timePost = timeCS+CON$POSTCUETIME
		timeITI = timeCS-CON$ITITIME
		timePostUS = CON$POSTUSTIME
		# Get the pre-cue indices/events
		ITIIndx = (mouseEventTimes$time<=timePre)&(mouseEventTimes$time>=timeITI)
		preCueIndx = (mouseEventTimes$time<timeCS)&(mouseEventTimes$time>=timePre)
		postCueIndx = (mouseEventTimes$time>=timeCS)&(mouseEventTimes$time<=timePost)
		postUSIndx = (mouseEventTimes$time<timePost+timePostUS)&(mouseEventTimes$time>=timePost)
		allIndx = preCueIndx | postCueIndx | postUSIndx | ITIIndx
		# add identification of cue to raw table
		mouseEventTimes$CStype[preCueIndx] = 'preCS'
		mouseEventTimes$CStype[postCueIndx] = 'postCS'
		mouseEventTimes$CStype[postUSIndx] = 'postUS'
		mouseEventTimes$CStype[ITIIndx] = 'ITI'
		mouseEventTimes$CStime[allIndx] = mouseEventTimes$time[allIndx] - timeCS
		mouseEventTimes$CSnum[allIndx] = currentTrial
		mouseEventTimes$CSnum[csTrial] = currentTrial
		# Get number of pre-cue events that are licks
		trialCounts$time = timeCS
		trialCounts$precounts = sum(mouseEventTimes[preCueIndx|ITIIndx,]$events==CON$LICK_ID)
		trialCounts$postcounts = sum(mouseEventTimes[postCueIndx,]$events==CON$LICK_ID)
		trialCounts$postUsCounts = sum(mouseEventTimes[postUSIndx,]$events==CON$LICK_ID)
		trialCounts$cs = which(csTrials==csTrial)
		lickCount = rbind(lickCount,data.frame(trialCounts))
		currentTrial = currentTrial + 1
	}
	# remove licking artifacts
	mouseEventTimes=mouseEventTimes[!(round(mouseEventTimes$CStime,2) %in% c(-0.01,9.99,13.01, 10.01)),]
	mouseEventTimes=mouseEventTimes[round(mouseEventTimes$CStime,1)!=10.9,]
	# add total counts
	lickCount$counts = sum(mouseEventTimes$events==CON$LICK_ID)

	# output
	output = list()
	output$lickCount = lickCount
	output$raw = mouseEventTimes
	output$NUMCSEVENTS = length(csTrials)
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
	mouseEventTimes$CStype = 'ITI'
	mouseEventTimes$CStime = FALSE
	mouseEventTimes$CSnum = FALSE

	return(mouseEventTimes)
}
getLickMetric <- function(file, animalData, lickCount, CON){
	# calculates the lick metric based on counts from file

	# Get animal information from filename
	animalTempInfo = list()
	animalTempInfo$file = file
	# animalInfo = strsplit(file,"-")[[1]]
	# animalTempInfo$date = animalInfo[1]
	# animalTempInfo$group = ifelse(!is.na(animalInfo[3]), animalInfo[3], 'GRPNA')
	# animalTempInfo$id = animalInfo[2]

	# Add lick metrics to the list
	animalTempInfo$postcount = sum(lickCount$postcount)
	animalTempInfo$precount = sum(lickCount$precount)
	animalTempInfo$count = lickCount$count[1]
	# precountRate = sum(lickCount$precount/CON$ITITIME)
	# postcountRate = sum(lickCount$postcount/CON$POSTCUETIME)

	precountRate = animalTempInfo$precount/((CON$ITITIME*CON$NUMCSEVENTS)/CON$SECTOMIN)
	postcountRate = animalTempInfo$postcount/((CON$POSTCUETIME*CON$NUMCSEVENTS)/CON$SECTOMIN)
	# c("ratio","diff")
	for (type in c("normRatio", "difference")) {
		if(type=="difference"){
			animalTempInfo$lickMetric = postcountRate - precountRate
		}else if(type=="normRatio"){
			animalTempInfo$lickMetric = (postcountRate - precountRate)/(postcountRate + precountRate)
		}
		animalTempInfo$lickMetricType = type
		# Convert list to data.frame and add to data.frame with all data, row-wise to aid later analysis
		# print(animalData)
		# print(data.frame(animalTempInfo))
		animalData = rbind(animalData,data.frame(animalTempInfo))
	}

	return(animalData)
}
# ggg = by(rData, rData$session, FUN=function(x){
# 	pre=x[x$CStype %in% c("ITI", "preCS"),];
# 	pretime = 60
# 	prerate = nrow(pre)/pretime
# 	post=x[x$CStype=="postCS",];
# 	posttime = 10
# 	postrate = nrow(post)/posttime
# 	(postrate - prerate)/(postrate + prerate)
# })