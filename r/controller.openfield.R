# biafra ahanonu
# updated: 2013.09.29 [22:16:46]
# open field analysis

packagesFileList = c("reshape2", "ggplot2", "parallel", "stringr")
lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})

# get input files
srcFileList = c("view/view.footnote.R", "model/model.openfield.R", "helper/helper.getDir.R")
lapply(srcFileList,FUN=function(file){source(file)})

controlller.openfield <- function(...){
	# run main function

	# cd to scripts if on correct computer
	if(length(dir('Z:/biafra/scripts'))!=0){setwd("Z:/biafra/scripts")}

	# Function to get directory info and create folders
	dataDir = "A:/biafra/data/behavior/open_field/all/"
	analysisDir = "C:/b/Dropbox/schnitzer/analysis/biafra/open_field/"
	dataSubDir=""
	c(dataDir,dataSubDir,dataMainDir,currentDate,analysisDir):=getDirectoryInfo(dataMainDir=dataDir,dataSubDir=dataSubDir,analysisDir=analysisDir)
	# _________________________________________________
	# get files
	fileList = list.files(dataMainDir, full.names=TRUE, include.dirs = FALSE)
	# Extract only the files
	print(fileList); flush.console();
	# _________________________________________________
	# load databases
	databaseDir = "C:/b/Dropbox/schnitzer/data/databases/"
	c(databaseDir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir=databaseDir,dataSubDir="",analysisDir=analysisDir)
	# databaseDir = choose.dir(databaseDir, 'select folder with mice and open field databases')

	# load mouse information (genotype, etc.)
	infoFilePath = "database.mice.csv"
	infoFilePath = paste(databaseDir,infoFilePath,sep="\\")
	infoData = read.table(infoFilePath, sep=",", header=T)

	# load database with open field information
	trialFilePath = "database.mice.open_field.csv"
	trialFilePath = paste(databaseDir,trialFilePath,sep="\\")
	trialData = read.table(trialFilePath, sep=",", header=T)

	# merge data.frames to get all information in one place
	mouseDatabase = merge(infoData, trialData, sort=FALSE, by.x = "mouse", by.y = "mouse")
	# remove duplicate rows, prevent later errors
	mouseDatabase = unique(mouseDatabase)
	# _________________________________________________
	# Loop over each file, extract data
	result = tryCatch({
		# load clusters, functions, and variables
		startTime = Sys.time()

		# open multiple R workers, leave one logical core available for system processes
		cl = model.cluster()

		# get data for each file in parallel
		listData = parLapply(cl, fileList, fun=model.openfield.v2, mouseDatabase)
		print(Sys.time()-startTime); flush.console();

		# unpack the data and combine into one data.frame
		multiMouseData = lapply(listData, FUN=function(x){x$multiMouseData})
		multiMouseData = do.call("rbind",multiMouseData)
		rawData = lapply(listData, FUN=function(x){x$rawData})
		rawData = do.call("rbind",rawData)
		mouseCenter = lapply(listData, FUN=function(x){x$mouseCenter})
		mouseCenter = do.call("rbind",mouseCenter)

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

	# _________________________________________________
	output = list()
	output$multiMouseData = multiMouseData
	output$rawData = rawData
	output$mouseCenter = mouseCenter
	return(output)
}


rawData = controlller.openfield()
multiMouseData = rawData$multiMouseData
rawMouseData = rawData$rawData
mouseCenter = rawData$mouseCenter