# biafra ahanonu
# 2013.02.08
# read in training data and parse it out
#________________________________________________________
# Set the local directory
# setwd("C:/Users/B/Dropbox/biafra/Stanford/Lab/schnitzer/scripts/R/")
#________________________________________________________
# Load libraries and dependencies
# For plotting
library(ggplot2)
# Add time-stamped footnote to graphs
source("view.footnote.R")
# Function to get directory info and create folders
source("helper.getDir.R")
# Wrap common image file saving routines in helper functions
source("helper.io.image.save.R")
# Function to get raw data from files
source("model.operant.parse.raw.R")
#________________________________________________________
# SETTINGS
# Set directory information, create appropriate directories
c(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir="../../data/",dataSubDir="jones/working_memory_5_cannulae/all/",analysisDir="../../analysis/temp/jones/")
# _________________________________________________
# Setup a hash table to help lookup particular phase's data
phaseHashTableFile = "database.mice.phases.discimination.wm.jones.csv"
# Read in hash file
phaseHashTable = read.table(paste(data_dir,"training/",phaseHashTableFile,sep=""),header=T,sep=",",row.names="phase")
# _________________________________________________
# Outputs
# Choose whether to analyze all files again or just append.
newFile = TRUE
# Output directory and filename
output_dir = paste(data_dir,"behavior/",sep="")
outputFilename = "database.mice.training.jones.csv"
outputFilenameRaw = "database.mice.training.raw.jones.csv"
# _________________________________________________
# _________________________________________________
# Loop through all mouse files and parse out relevant data
mouseFiles = dir(path=data_main_dir,recursive=TRUE)
# Read in file that contains information about each mouse
mouseInfoFile = "database.mice.csv"
mouseInfo = read.table(paste(data_dir,"mice/",mouseInfoFile,sep=""),header=T,sep=",",row.names="id")
# If only appending, filter for yesterday's trials
dayOffset = 0
if(newFile==FALSE){
	mouseFiles = mouseFiles[grep(format(Sys.Date()-dayOffset, format="%Y_%m_%d"),mouseFiles)]
}
createInitialFile=TRUE
# Loop over each file, get raw and summary data for each mice/trial
for(file in mouseFiles){
	# The summary and raw mouse data for all mice/trials
	allmousedata = data.frame()
	allMouseRawData = data.frame()
	# Get mouse ID and date from filename
	datatype = strsplit(file,"-")[[1]]
	date = as.numeric(datatype[1])
	mouseID = datatype[2]
	# Inform the user of progress
	print(paste(mouseID,date))

	# Get data for this particular mouse trial
	mouseRawData = read.table(paste(data_main_dir,file,sep=""),header=F,skip=30,nrows=10)
	# Convert to vector row-wise
	mouseRawData = as.vector(t(mouseRawData[,2:6]))
	mouseData = list()

	# Get modification time for each file
	fileDayTime = as.numeric(unlist(strsplit((strsplit(as.character(file.info(paste(data_main_dir,file,sep=""))$mtime)," ")[[1]][2]),":")))
	fileDayTime = fileDayTime[1]+fileDayTime[2]/60+fileDayTime[3]/(60*60)

	# Get all parameters used for these experiments
	phase_vector = list()
	phase_vector$forced_trial_left = mouseRawData[1]
	phase_vector$forced_trial_right = mouseRawData[2]
	phase_vector$choice_trials = mouseRawData[3]
	phase_vector$fixed_ratio = mouseRawData[12]
	phase_vector$right_level_cue = mouseRawData[13]
	phase_vector$left_level_cue = mouseRawData[50]
	phase_vector$lever_cue_freq = mouseRawData[43]
	phase_vector$lever_cue_duration = mouseRawData[5]
	phase_vector$pre_cue_duration = mouseRawData[47]
	phase_vector$max_session_time = mouseRawData[45]
	phase_vector$delay_duration = mouseRawData[6]
	phase_vector$iti_duration = mouseRawData[10]
	phase_vector$timeout_duration = mouseRawData[11]
	phase_vector$time_light_pellet = mouseRawData[53]
	phase_vector$require_he = mouseRawData[7]
	phase_vector$flash_hopper = mouseRawData[49]
	phase_vector$repeat_missed = mouseRawData[44]
	phase_vector$house_pre_cue = mouseRawData[46]
	phase_vector$limit_he_time = mouseRawData[8]
	phase_vector$limit_press_time = mouseRawData[9]
	phase_vector$pre_cue_TTL = mouseRawData[51]
	phase_vector$post_pellet_TTL = mouseRawData[52]
	phase_vector = as.numeric(phase_vector)
	phase_vector[is.na(phase_vector)]='NOTS'
	phase_len = length(phase_vector)

	# Compare the phase vector to each possible row, return match
	phase = gsub("X","",names(phaseHashTable)[apply(phaseHashTable,2,FUN=function(colData,comData){sum(colData==comData)==length(colData)},comData=phase_vector)])
	phase = ifelse(length(phase)==0,"0.0",phase)
	# If there is an error determining the phase, write this to the database to help fix data-table
	if(phase=="0.0"){
		write.table(data.frame(t(phase_vector)),append=!createInitialFile,file=paste(output_dir,'database.jones.errors',sep=""),sep=",",row.names=FALSE,col.names=createInitialFile,quote=TRUE)
		print(phase_vector);
		# break;
	}else if(createInitialFile==TRUE){
		write.table(data.frame(t(phase_vector)),append=!createInitialFile,file=paste(output_dir,'database.jones.errors',sep=""),sep=",",row.names=FALSE,col.names=createInitialFile,quote=TRUE)
	}

	mouseData$date = date
	mouseData$fileTime = round(fileDayTime,4)
	mouseData$phase = phase
	mouseData$mouse = mouseID
	mouseData$id = as.vector(mouseInfo[mouseID,]$mouse)
	mouseData$type = as.vector(mouseInfo[mouseID,]$type)
	mouseData$correct = mouseRawData[4]
	mouseData$incorrect = mouseRawData[21]
	mouseData$head_end_omissions = mouseRawData[41]
	mouseData$press_omissions = mouseRawData[42]
	mouseData$mean_lat_to_press = mouseRawData[25]
	mouseData$mean_lat_to_he = mouseRawData[23]
	mouseData$mean_lat_to_pellet = mouseRawData[40]
	mouseData$forced_rt = mouseRawData[19]
	mouseData$forced_lt = mouseRawData[18]
	mouseData$choice = mouseRawData[20]
	mouseData$rt_np = mouseRawData[35]
	mouseData$lt_np = mouseRawData[34]
	mouseData$he = mouseRawData[36]

	# Get mouse event data
	mouseEventData = getMouseRaw(file,data_main_dir)

	# choice trial, correctly pick left lever
	LEFT_CORRECT = 5
	# choice trial, correctly pick left right
	RIGHT_CORRECT = 6
	# press left lever
	LEFT_PRESS = 3
	# press right lever
	RIGHT_PRESS = 4

	mouseData$correctLeft = nrow(mouseEventData[mouseEventData$events==LEFT_CORRECT,])
	mouseData$correctRight = nrow(mouseEventData[mouseEventData$events==RIGHT_CORRECT,])
	mouseData$pressLeft = nrow(mouseEventData[mouseEventData$events==LEFT_PRESS,])
	mouseData$pressRight = nrow(mouseEventData[mouseEventData$events==RIGHT_PRESS,])
	# Add the correct and incorrect latency times to the list
	mouseData = c(mouseData,getLatencyTimes(mouseEventData))

	mouseData = data.frame(mouseData)
	allmousedata = rbind(allmousedata,mouseData)

	allMouseRawData=rbind(allMouseRawData,data.frame(mouseEventData,date=date,phase=phase,mouse=mouseID,id=as.vector(mouseInfo[mouseID,]$mouse),type=as.vector(mouseInfo[mouseID,]$type)))

	# Force display of output
	flush.console()

	# Write summary data to file
	write.table(allmousedata,append=!createInitialFile,file=paste(output_dir,outputFilename,sep=""),sep=",",row.names=FALSE,col.names=createInitialFile,quote=TRUE)
	# Write the event data to a file
	write.table(allMouseRawData,append=!createInitialFile,file=paste(output_dir,outputFilenameRaw,sep=""),sep=",",row.names=FALSE,col.names=createInitialFile,quote=TRUE)
	if(createInitialFile==TRUE){createInitialFile=FALSE}
}