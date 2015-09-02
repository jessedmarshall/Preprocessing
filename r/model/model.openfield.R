# biafra ahanonu
# updated: 2013.08.03 [19:51:03]
# open field analysis tool

# load packages
require(ggplot2)
require(stringr)
require(base)
#require(foreach)

# conversion from relative movement to absolute is given in separate database
# all files will be formatted to the following convention:
# XM = x location
# YM = y location
# Angle = mouse angle
# velocity = velocity based on x,y
# frame = row's frame in the movie

model.openfield.v2 <- function(filePath, mouseDatabase, numBinsTrial=20){
	#main function

	result = tryCatch({
		# get trial information from each file
		fileInfo=extractFileInfo(filePath)
		# get mouse info based on unique identifiers
		thisMouseInfo = merge(fileInfo, mouseDatabase, by=c("experiment","mouse","trial"), sort=FALSE)
		# get the mouse age at start of trial
		mouseAge = getTimeDiff(thisMouseInfo$birth,thisMouseInfo$date, "months", "%Y.%m.%d")
		thisMouseInfo$age = mouseAge

		# check whether ethovision or imagej
		fileFormatCheck = !is.na(str_extract(readLines(filePath, n=1), "Number of header lines:"))
		if(fileFormatCheck){
			mouseData = getEthovisionData(filePath)
		}else{
			mouseData = getImageJData(filePath)
		}

		# # get velocity
		mouseData = getVelocity(mouseData)

		# # get distance moved
		binData = getBinnedDistance(mouseData, numBinsTrial)

		# # combine mouse time information into one vector
		# # data.frame(distance=binData$mouseDistance,time=binData$timeMouseData[-1:0])
		thisMouseData = cbind(binData,thisMouseInfo)

		# #get the time mice spend in the center
		mouseCenterTime = findCenter(mouseData)
		mouseCenterTime$age = mouseAge

		# add back stats to mouseData
		mouseData$mouse = thisMouseInfo$mouse
		mouseData$type = thisMouseInfo$type
		mouseData$age = mouseAge

		print("+++++++++++++++++++++")
		print(filePath)
		print("+++++++++++++++++++++")
		flush.console()

		return(list(multiMouseData=thisMouseData,rawData=mouseData,mouseCenter=mouseCenterTime))
	}, error = function(err) {
		print("________________________")
		print(filePath)
		print(err)
		print(traceback())
		print("________________________")
		flush.console()
		# print(warnings())
		# print(traceback())
		return(FALSE)
	}, finally = {

	})
}
getTimeDiff <-function(startDate, endDate, type="months", iformat="%Y.%m.%d"){
	# calculates the difference between two dates
	if(type=="months"){
		# get the mouse age at start of trial
		birthDate = as.Date(startDate, iformat)
		trialDate = as.Date(endDate, iformat)
		timeDiff = as.numeric(round((trialDate - birthDate)/(365.25/12)))
	}
	return (timeDiff)
}
model.cluster <-function(...){
	# opens a cluster
	logFile = 'log2.txt'
	# unlink (delete) the log file before starting
	unlink(logFile)
	# open multiple R workers, leave one logical core available for system processes
	cl = makeCluster(detectCores()-1, outfile=logFile)
	# pass scripts/packages to clusters
	clusterEvalQ(cl, {
		srcFileList = c("model/model.openfield.R")
		lapply(srcFileList,FUN=function(file){source(file)})
		packagesFileList = c("reshape2", "stringr")
		lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})
	})
	# pass data(bases) to clusters
	# clusterExport(cl, c("dataMainDir","eventFile"))
	return(cl)
}
is.between <- function(x, low, high) {
	# returns the values of x that are between low and high
	xrange = (x - low)*(high - x) > 0
	# sum(xrange>0,na.rm=TRUE)/length(x)
	return(xrange)
}
pct.between <- function(x, low, high) {
	# returns the pct of x values between low and high
	xrange = (x - low)*(high - x) > 0
	xpct = sum(xrange>0,na.rm=TRUE)/length(xrange)
	return(xpct)
}
findCenter <- function(listOfVectors, centerVal = 0.3, stdVal = 3.5){
	# find the center
	listOfCenterVals = lapply(listOfVectors, FUN=getCenterTime)
	return(mean(unlist(listOfCenterVals)))
}
getCenterTime <- function(vector, centerVal = 0.3, stdVal = 3.5){
	# finds percent time in center
	centerVals = vector[is.between(vector,-stdVal,stdVal)]
	centerRange =  max(abs(centerVals),na.rm=TRUE)*centerVal
	centerTime = pct.between(centerVals,-centerRange,centerRange)
	return(centerTime)
}
extractFileInfo <- function(filePath){
	# get trial and subject data from filename for this particular mouse
	trial = str_extract(str_extract(filePath, "(trial_\\d+|Trial\\s+\\d+)"), "[[:digit:]]+")
	if(is.na(trial)){
		trial = str_extract(str_extract(filePath, "(oft\\d+)"), "[[:digit:]]+")
	}
	subject = str_extract(str_extract(filePath, "(subject_\\d+|Subject\\s+\\d+)"), "[[:digit:]]+")
	if(is.na(subject)){
		subject = as.character(gsub("(m|M)","",str_extract(filePath, "(m|M)\\d+")))
	}
	mouse = as.character(gsub("(m|M)","",str_extract(filePath, "(m|M)\\d+")))
	# get experiment number
	experiment = gsub("_","",str_extract(filePath,"_p\\d+_"))
	# if(is.na(subject)){
	# 	experiment = winDialogString('enter experiment ID', 'p00')
	# }

	# Get modification time for each file
	fileDayTime = as.numeric(unlist(strsplit((strsplit(as.character(file.info(filePath)$mtime)," ")[[1]][2]),":")))
	fileDayTime = fileDayTime[1]+fileDayTime[2]/60+fileDayTime[3]/(60*60)
	fileDate = (strsplit(as.character(file.info(filePath)$mtime)," "))[[1]][[1]]

	dayStart = 7; dayEnd = 19;
	if(fileDayTime>=dayStart&fileDayTime<=dayEnd){
		circadianCycle="day"
	}else{
		circadianCycle="night"
	}

	# print(data.frame(subject, trial, mouse, experiment, fileDate, fileDayTime, circadianCycle))

	return(data.frame(subject, trial, mouse, experiment, fileDate, fileDayTime, circadianCycle))
}
getBinnedDistance <- function(mouseData, numBinsTrial=20){
	# cut the trial into timepoints and sum
	lenMouseData = nrow(mouseData)
	# split trial into twenty even points
	timeMouseData = seq(1,lenMouseData,length.out = numBinsTrial)
	# make psuedo-factors to bin each timepoint into
	mouseCuts = cut(1:lenMouseData,timeMouseData)
	mouseData$bins = mouseCuts
	# sum each bin using apply
	mouseDistance = as.vector(t(tapply(mouseData$velocity,mouseCuts,FUN=function(x)sum(x,na.rm=T))))

	difference=c(0,diff(mouseDistance))

	normDistance = mouseDistance/mouseDistance[1]

	pctTimeMoving = as.vector(t(tapply(mouseData$velocity,mouseCuts,FUN=function(x){
		notMoving = 0.02
		sum(x<notMoving)/length(x)
		})))

	# distanceCum = cumsum(mouseDistance)

	return(data.frame(distance=mouseDistance,time=timeMouseData[-1:0],diff=difference,normDistance,pctTimeMoving))
}
getEthovisionData <-function(filePath,...){
	# read in the trial data and get labels for columns
	# get number of header lines
	numHeaderLines = as.numeric(unlist(strsplit(as.character(read.table(filePath, nrow=1)$V2),"\""))[[2]])
	# read in data
	mouseData = read.table(filePath, skip=numHeaderLines, sep=",", colClasses="numeric", na.strings="\"-\"", stringsAsFactors=FALSE)
	mouseLabels = read.table(filePath, skip=numHeaderLines-2, sep=",", nrow=1, stringsAsFactors=FALSE)
	names(mouseData) = gsub(" ",".",t(mouseLabels))

	# remove first row, contains NA...
	# mouseData = mouseData[2:dim(mouseData)[1],]
	# mouseData = mouseData[0:-(nrow(mouseData) %% numBinsTrial),]

	# scale the mouse location, centered at zero
	mouseData$X.center = scale(mouseData$X.center)
	mouseData$Y.center = scale(mouseData$Y.center)

	# filter out un-used columns
	filterCols = c("X.center", "Y.center")
	# columns to rename
	renameCols = c("XM","YM")
	# restructure data
	mouseData = mouseData[,filterCols]
	names(mouseData) = renameCols

	# add Frame/Angle to match ImageJ data
	mouseData$Frame = c(1:nrow(mouseData))
	mouseData$Angle = NA

	return(mouseData)
}
getImageJData <-function(filePath,...){
	mouseData = read.table(filePath, sep=",", header=TRUE, stringsAsFactors=FALSE)
	idx = which(ave(mouseData$Area, mouseData$Slice, FUN=rank)==1)
	mouseData = mouseData[idx,]

	# filter out un-used columns
	filterCols = c("XM", "YM", "Angle", "Slice")
	# columns to rename
	renameCols = c("XM","YM", "Angle", "Frame")
	# restructure data
	mouseData = mouseData[,filterCols]
	names(mouseData) = renameCols

	return(mouseData)
}
getVelocity <-function(input){
	dx = diff(input$XM)
	dy = diff(input$YM)
	distanceMoved = sqrt(dx^2 + dy^2)
	distanceMoved = c(0, distanceMoved)
	distanceMoved[is.na(distanceMoved)]=0
	input$velocity = distanceMoved

	return(input)
}

# result = tryCatch({
# 	trialData = model.openfield.v2()
# 	multiMouseData = trialData$multiMouseData
# 	rawData = trialData$rawData
# 	mouseCenter = trialData$mouseCenter
# }, error = function(err) {
# 	print(err)
# 	# print(traceback())
# 	return(FALSE)
# }, finally = {

# })