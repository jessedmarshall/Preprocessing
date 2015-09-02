# biafra ahanonu
# updated: 2013.08.24 [11:29:49]
# controller for analysis of pav data

# clear memory space
# rm(list=ls())

# load packages
packagesFileList = c("reshape2", "ggplot2", "parallel", "stringr")
lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})

# get input files
srcFileList = c(
	# Function to get directory info and create folders
	"helper/helper.getDir.R",
	# Set directory information, create appropriate directories
	"helper/helper.rvalue.R",
	# traces functions
	"model/model.traces.general.R",
	# pav functions
	"model/model.traces.pav.R"
)
lapply(srcFileList,FUN=function(file){source(file)})

controller.traces.cluster <-function(...){
	# opens a cluster
	logFile = 'log.txt'
	# unlink (delete) the log file before starting
	unlink(logFile)
	# open multiple R workers, leave one logical core available for system processes
	cl = makeCluster(detectCores()-1, outfile=logFile)
	# pass scripts/packages to clusters
	clusterEvalQ(cl, {
		srcFileList = c("model/model.traces.general.R","model/model.traces.pav.R")
		lapply(srcFileList,FUN=function(file){source(file)})
		packagesFileList = c("reshape2")
		lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})
	})
	# pass data(bases) to clusters
	# clusterExport(cl, c("dataMainDir","eventFile"))
	return(cl)
}
controller.traces.general <-function(dataStruct, mouseID = 728,...){
	# given an input mouse, gathers data and structures it

	# dataStruct must be a list()
	if(class(dataStruct)!="list"){return;}

	result = tryCatch({
		# get data directories
		# c(dataMainDir,dataSubDir,dataSubDirMod,currentDate,analysisDir):=getDirectoryInfo(dataMainDir="E:/biafra/data/tmp/",dataSubDir="",analysisDir="../../analysis/temp/")

		# choose files, currently only for windows
		allTraceDir = 'E:/biafra/data/traces/pav/'
		thistraceDir = paste(allTraceDir, 'm', mouseID, '/', sep="")
		fileList = list.files(path = thistraceDir, full.names=TRUE)
		print(fileList); flush.console();

		# load clusters, functions, and variables
		startTime = Sys.time()

		# open multiple R workers, leave one logical core available for system processes
		cl = controller.traces.cluster()

		# get traces for each file in parallel
		trialImagingData = parLapply(cl, fileList, fun=analyzeTraces)
		print(paste("finished traces in",print(Sys.time()-startTime))); flush.console();

		# unrwrap and combine list outputs into single data.frames
		traceSum = trialImagingData$traceSum
		traceDataSpikes = trialImagingData$traceDataSpikes
		traceDataSpikes = lapply(trialImagingData, FUN=function(x){x$traceDataSpikes})
		traceDataSpikes = do.call("rbind",traceDataSpikes)
		traceSum = lapply(trialImagingData, FUN=function(x){x$traceSum})
		traceSum = do.call("rbind",traceSum)

		# add data to analysis structure
		dataStruct$traceSum = traceSum
		dataStruct$traceDataSpikes = traceDataSpikes
	}, error = function(err) {
		print(err)
		print(traceback())
		return(dataStruct)
	}, finally = {
		print(Sys.time()-startTime); flush.console();
		# stop the cluster
		stopCluster(cl)
		return(dataStruct)
	})
}
controller.traces.pav <-function(dataStruct,...){
	# takes an input that contains spike data, outputs an alignment to CS, etc. from PAV

	# dataStruct must be a list()
	if(class(dataStruct)!="list"){return;}

	result = tryCatch({
		# unpack variables to be used
		traceSum = dataStruct$traceSum
		traceDataSpikes = dataStruct$traceDataSpikes

		# add the pav and mouse numbers to the trace list based on file-name
		traceSum$pav = str_extract(traceSum$file, "pav\\d+")
		traceSum$mouse = as.numeric(gsub("m","",str_extract(traceSum$file, "m\\d+")))
		traceDataSpikes$pav = str_extract(traceDataSpikes$file, "pav\\d+")
		traceDataSpikes$mouse = as.numeric(gsub("m","",str_extract(traceDataSpikes$file, "m\\d+")))

		# load clusters, functions, and variables
		startTime = Sys.time()

		# open multiple R workers, leave one logical core available for system processes
		cl = controller.traces.cluster()

		# get event data/dir
		mouseID = 728
		allEventDir = 'E:/biafra/data/behavior/pav/'
		thisEventDir = paste(allEventDir, 'm', mouseID, '/', sep="")
		eventFile = paste(thisEventDir,'pav_all.data', sep="")

		# get event data
		eventDataOutput = getEventData(eventFile)
		#
		eventDataCSOnly = eventDataOutput$eventDataCueOnly
		eventDataCSOnly$pav = str_extract(eventDataCSOnly$file, "PAV_\\d+")
		#
		eventDataLickOnly = eventDataOutput$eventDataLickOnly
		eventDataLickOnly$pav = str_extract(eventDataLickOnly$file, "PAV_\\d+")
		# align the traces to each files data
		eventDataList = by(eventDataCSOnly, eventDataCSOnly$file, FUN=function(x){x})
		registeredCsData = parLapply(cl, eventDataList, FUN=registerTracesToCS, traceSum)
		registeredCsDataALL = do.call('rbind', registeredCsData)

		eventDataList = by(eventDataLickOnly, eventDataLickOnly$file, FUN=function(x){x})
		registeredLickData = parLapply(cl, eventDataList, FUN=registerTracesToCS, traceSum)
		registeredLickDataALL = do.call('rbind', registeredLickData)

		dataStruct$registeredCsDataALL = registeredCsDataALL
		dataStruct$registeredLickDataALL = registeredLickDataALL
		dataStruct$eventDataCSOnly = eventDataCSOnly
		dataStruct$eventDataRaw = eventDataOutput$eventDataRaw
	}, error = function(err) {
		print(err)
		print(traceback())
		registeredCsDataALL = NULL
		return(dataStruct)
	}, finally = {
		print(Sys.time()-startTime); flush.console();
		# stop the cluster
		stopCluster(cl)
		return(dataStruct)
	})
}
controller.traces.lick <-function(dataStruct,...){
	# dataStruct must be a list()
	if(class(dataStruct)!="list"){return;}

	result = tryCatch({
		# unpack variables to be used
		traceDataSpikes = dataStruct$traceDataSpikes
		# get event data
		eventDataRaw = dataStruct$eventDataRaw

		# load clusters, functions, and variables
		startTime = Sys.time()

		# open multiple R workers, leave one logical core available for system processes
		cl = controller.traces.cluster()

		# align the traces to each files data
		eventDataList = by(eventDataCSOnly, eventDataCSOnly$file, FUN=function(x){x})
		registeredCsData = parLapply(cl, eventDataList, FUN=registerTracesToCS, traceSum)
		# registeredCsData = by(eventDataCSOnly, eventDataCSOnly$file, FUN=registerTracesToCS, traceSum)
		registeredCsDataALL = do.call('rbind', registeredCsData)

		dataStruct$registeredCsDataALL = registeredCsDataALL
		dataStruct$eventDataCSOnly = eventDataCSOnly
	}, error = function(err) {
		print(err)
		print(traceback())
		registeredCsDataALL = NULL
		return(dataStruct)
	}, finally = {
		print(Sys.time()-startTime); flush.console();
		# stop the cluster
		stopCluster(cl)
		return(dataStruct)
	})
}
controller.traces.classify <-function(dataStruct){

}

# get the trace data
dataStruct = list()
# get the trace data, converts to
dataStruct = controller.traces.general(dataStruct)
# get pav aligned data
dataStruct = controller.traces.pav(dataStruct)
# identify cells modulated by CS, US, other events
# dataStruct = controller.traces.classify(dataStruct)

# see plots for further analysis