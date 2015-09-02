# biafra ahanonu
# updated: 2013.08.24 [11:38:53]
# open field analysis tool

# load packages
require(ggplot2)
require(stringr)
require(base)
require(foreach)

model.openfield <- function(plotGraphs=FALSE){
	#main function

	#get the raw data
	mouseData = getRawData()

	if(plotGraphs==TRUE){
		newRawData = data.frame(first=rawData$Velocity[0:(length(rawData$Velocity)-1)], second=rawData$Velocity[-1:0], type=rawData$type[0:(length(rawData$type)-1)])
		ggplot(newRawData,aes(first,second,fill=type))+stat_smooth(n=30)+stat_binhex(alpha=0.4)
		#+scale_fill_gradient(name = "count", trans = "log")

		ggplot(rawData,aes(X.center,Y.center,group=type))+stat_binhex()+facet_grid(experiment~type)+scale_fill_gradient(low="black", high="red")

		ggplot(multiMouseData,aes(time,distance,color=type))+geom_smooth()+geom_point()+scale_y_log10()
		ggplot(multiMouseData,aes(time,distance,color=type))+geom_smooth()+geom_point()+scale_y_log10()+facet_grid(experiment~.)

		ggplot(rawData,aes(Trial.time,Velocity))+geom_line()
	}

	return(mouseData)
}
getRawData <- function(){
	# get trial information
	trialDir = "F:/schnitzer/data/open_field/huntington/"
	trialDir = choose.dir(trialDir, 'select folder with trial data')
	listOfFiles = dir(trialDir)

	dataDir = "../tmp/"
	dataDir = choose.dir(dataDir, 'select folder with mice database')

	# load mouse information (genotype, etc.)
	infoFilePath = "database.mice.csv"
	infoFilePath = paste(dataDir,infoFilePath,sep="")
	infoData = read.table(infoFilePath, sep=",", header=T)

	# load information for a particular trial
	trialFilePath = "database.mice.open_field.csv"
	trialFilePath = paste(dataDir,trialFilePath,sep="")
	trialData = read.table(trialFilePath, sep=",", header=T)

	# merge data.frames to get all information in one place
	trialInfoDataMerged = merge(infoData, trialData, sort=FALSE, by.x = "mouse", by.y = "mouse")

	trialDataRaw = getTrialData(listOfFiles, trialInfoDataMerged, trialDir, dataDir)

	return(trialDataRaw)
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
	centerVals = values[is.between(values,-stdVal,stdVal)]
	centerRange =  max(abs(centerVals),na.rm=TRUE)*centerVal
	centerTime = pct.between(xvalues,-centerRange,centerRange)
	return(centerTime)
}
getTrialData <-function(listOfFiles, mouseTrial, trialDir, dataDir){
	multiMouseData = data.frame()
	rawData = data.frame()
	mouseCenter = data.frame()

	# loop over all data files
	for(dataFile in listOfFiles){
		dataFile = paste(trialDir,dataFile,sep="")
		print(dataFile)
		# get trial and subject data for this particular mouse
		trial = as.integer(unlist(strsplit(str_extract(dataFile,"trial_\\d"),"_"))[2])
		if(is.na(trial)){
			trial = as.integer(unlist(strsplit(str_extract(dataFile,"Trial\\s+\\d"),"\\s+"))[2])
		}
		subject = as.integer(unlist(strsplit(str_extract(dataFile,"subject_\\d"),"_"))[2])
		if(is.na(subject)){
			subject = as.integer(unlist(strsplit(str_extract(dataFile,"Subject\\s+\\d"),"\\s+"))[2])
		}
		# get experiment number
		experiment = gsub("_","",str_extract(dataFile,"_p\\d+_"))
		# use unique
		thisMouseInfo = data.frame(experiment,subject,trial)
		thisMouseInfo = merge(thisMouseInfo,mouseTrial,by=c("experiment","subject","trial"), sort=FALSE)

		# read in the trial data and get labels for columns
		mouseData = read.table(dataFile, skip=33, sep=",", colClasses="numeric", na.strings="\"-\"")
		mouseLabels = read.table(dataFile, skip=31, sep=",", nrow=1)
		names(mouseData) = gsub(" ",".",t(mouseLabels))

		# remove first row since contains NA...
		mouseData = mouseData[2:dim(mouseData)[1],]
		# scale the center
		mouseData$X.center = scale(mouseData$X.center)
		mouseData$Y.center = scale(mouseData$Y.center)
		#ggplot(mouseData[2:dim(mouseData)[1],],aes(Trial.time,cumsum(Distance.moved)))+geom_point()

		# get distance moved
		cumsum(mouseData$Distance.moved)

		# cut the trial into timepoints and sum
		lenMouseData = dim(mouseData)[1]
		timeMouseData = seq(1,lenMouseData,length.out = 20)
		mouseCuts = cut(1:lenMouseData,timeMouseData)
		mouseData$bins = mouseCuts
		mouseDistance = as.vector(t(tapply(mouseData$Distance.moved,mouseCuts,FUN=function(x)sum(x,na.rm=T))))

		thisMouseData = data.frame(experiment,distance=mouseDistance,time=timeMouseData[-1:0],mouse=dataFile,type=thisMouseInfo$type)
		multiMouseData = rbind(multiMouseData,thisMouseData)

		#add current raw data to larger data.frame
		rawData = rbind(rawData,cbind(mouseData,data.frame(experiment,type=thisMouseInfo$type)))

		#get the time mice spend in the center
		mouseCenterTime = findCenter(mouseData)
		mouseCenter = rbind(mouseCenter,data.frame(experiment,mouseCenterTime,type=thisMouseInfo$type))
	}

	return(list(multiMouseData=multiMouseData,rawData=rawData,mouseCenter=mouseCenter))
}