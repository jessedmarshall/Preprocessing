source("helper/helper.rvalue.R")
#________________________________________________________
# Get data directory
getDirectoryInfo = function(dataMainDir="",dataSubDir="",analysisDir="",getUsrInput=TRUE) {
	# if(dataMainDir!=""){
	# 	dataMainDir = getwd();
	# }
	# Ask for user input
	if(getUsrInput){
		dataSubDirMod = gsub("\\\\","/",choose.dir(default=dataMainDir,caption="select directory to analyze"))
	}else{
		dataSubDirMod = dataMainDir
	}
	# If user gives no input, go to default directory
	dataSubDirMod = ifelse(is.na(dataSubDirMod), paste(dataMainDir,dataSubDir,sep=""), dataSubDirMod)
	print(paste("Data directory:",dataSubDirMod))

	# Get analysis directory
	# if(analysisDir!=""){
	# 	analysisDir = getwd();
	# }
	if(getUsrInput){
		analysisDirTemp = gsub("\\\\","/",choose.dir(default=analysisDir,caption="select directory to output data"))
	}else{
		analysisDirTemp = analysisDir
	}
	# If user gives no input, go to default directory
	analysisDir = ifelse(is.na(analysisDirTemp), analysisDir, paste(analysisDirTemp,"/",sep=""))
	# Create analysis directory
	dir.create(file.path(analysisDir),showWarnings=FALSE)
	# Create dated sub-directory to store analysis files
	currentDate = format(Sys.Date(), format="%Y_%m_%d")
	dir.create(file.path(analysisDir, currentDate),showWarnings=FALSE)
	analysisDir = paste(analysisDir,currentDate,"/",sep="")
	print(paste("Analysis directory:",analysisDir))

	# Use for unique folder for each run, comment out
	# analysis_dir_run_id = format(Sys.time(), format="%H%M%S")
	# analysisDir = paste(analysisDir,analysis_dir_run_id,"/",sep="")

	return(list(dataMainDir,dataSubDir,dataSubDirMod,currentDate,analysisDir))
}