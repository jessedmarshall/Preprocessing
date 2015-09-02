# biafra ahanonu
# updated: 2013.07.29
# read in training data and parse it out
# =================================================
# get input files
liquidLight = 0
if(liquidLight==0){
	# normal pav liquid
	srcFileList = c("view/view.footnote.R", "model/model.pav.liquid.parse.R", "helper/helper.getDir.R",'helper/helper.packages.R')
}else{
	# lick for laser
	srcFileList = c("view/view.footnote.R", "model/model.pav.liquid_light.parse.R", "helper/helper.getDir.R",'helper/helper.packages.R')
}
lapply(srcFileList,FUN=function(file){source(file)})
# =================================================
controlller.pav.liquid <- function(...){
	# run main function
	# =================================================
	# get files
	fileList = list.files(data_main_dir, full.names=TRUE, include.dirs = FALSE)
	# Extract only the files
	# fileList = matrix(unlist(strsplit(fileList,'/')),nrow=length(strsplit(fileList,'/')[[1]]))[length(strsplit(fileList,'/')[[1]]),]
	print(fileList); flush.console();
	# =================================================
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
		print('done extracting data from files')
		print(Sys.time()-startTime); flush.console();
		# stop the cluster
		stopCluster(cl)
		# return(data.frame())
	})
	result = tryCatch({
		# =================================================
		# add pav and animal info
		rawMouseData = getFileInfo(rawMouseData)
		animalData = getFileInfo(animalData)
		print('done extracting file info')
		print(Sys.time()-startTime); flush.console();
	}, error = function(err) {
		print(err)
		print(traceback())
		# return(data.frame())
	}, finally = {
		print(Sys.time()-startTime); flush.console();
		# return(data.frame())
	})

	output = list()
	output$rawMouseData = rawMouseData
	output$animalData = animalData
	return(output)
}

# cd to scripts if on correct computer
# if(length(dir('Z:/biafra/scripts'))!=0){setwd("Z:/biafra/scripts")}

# Function to get directory info and create folders
if(liquidLight==0){
	# data_dir = "A:/biafra/data/behavior/pav/p92/licking"
	# analysis_dir = "C:/b/Dropbox/schnitzer/analysis/biafra/pav/"
	# data_dir = "A:/biafra/data/behavior/pav/p104"
	# data_dir = "A:/biafra/data/behavior/pav/p62/licking/"
	# analysis_dir = "C:/b/Dropbox/schnitzer/analysis/biafra/pav/p62/"
	data_dir_list = c("A:/biafra/data/behavior/pav/p205")
	analysis_dir_list = c("D:/b/Dropbox/biafra_jones/analysis/pav/")
}else{
	data_dir_list = c("C:/b/Dropbox/biafra_jones/data/behavior/L4LL/v2")
	analysis_dir_list = c("C:/b/Dropbox/biafra_jones/analysis/L4LL/")
}
for (dirNo in c(1:length(data_dir_list))) {
	data_sub_dir=""
	data_dir = data_dir_list[dirNo]
	analysis_dir = analysis_dir_list[dirNo]
	c(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir=data_dir,dataSubDir=data_sub_dir,analysisDir=analysis_dir)
	rawData = controlller.pav.liquid(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir)
	animalData = rawData$animalData
	rawMouseData = rawData$rawMouseData
	# =================================================
	# add for miniscope analysis
	rawMouseData$subject = rawMouseData$mouse
	rawMouseData$trialSet = as.numeric(str_extract(rawMouseData$pav,"[[:digit:]]+"))
	rawMouseData$type = str_extract(rawMouseData$pav, "[[:alpha:]]+")
	# rawMouseData$trial = as.numeric(str_extract(rawMouseData$pav,"[[:digit:]]+"))
	rawMouseData$trial = rawMouseData$pav
	framesPerSec = 5
	rawMouseData$frame = round(as.numeric(rawMouseData$time)*framesPerSec)
	framesPerSec = 20
	rawMouseData$frame20hz = round(as.numeric(rawMouseData$time)*framesPerSec)
	# =================================================
	result = tryCatch({
		srcFileList = c("view/view.pav.liquid_light.R", "view/view.pav.liquid.R")
		lapply(srcFileList,FUN=function(file){source(file)})
		if(liquidLight==0){
			# source("view/view.pav.liquid.R");view.pav.liquid(animalData, rawMouseData, analysis_dir)
			view.pav.liquid(animalData, rawMouseData, analysis_dir)
		}else{
			# source("view/view.pav.liquid_light.R");view.pav.liquid_light(animalData, rawMouseData, analysis_dir)
			view.pav.liquid_light(animalData, rawMouseData, analysis_dir)
		}
	}, error = function(err) {
		print(err)
		print(traceback())
		return(data.frame())
	}, finally = {
	})
	# =================================================
	writeDataToFile <- function(data, file, sep="\t"){
		print(file)
		write.table(data, file=file, sep=sep, col.names=TRUE, row.names=FALSE, quote=FALSE)
	}
	# =================================================
	# save data
	print('saving lick counts')
	writeData(animalData,paste(analysis_dir,"lickCount.data",sep=""))
	# writeData(rawMouseData,paste(analysis_dir,"mouseRaw.data",sep=""))
	# print('saving raw')
	writeDataToFile(rawMouseData,paste(analysis_dir,"rawLickData.tab",sep=""))
	writeDataToFile(rawMouseData,paste(analysis_dir,"rawLickData.csv",sep=""),sep=",")
	# writeData(lickRawData,paste(analysis_dir,"rawLickData.tab",sep=""))
	# print(Sys.time()-startTime); flush.console();
	# =================================================
}
