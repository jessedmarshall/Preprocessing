# biafra ahanonu
# 2013.03.05
# read in training data and parse it out
getLatencyTimes <- function(data){
	# To avoid for loops, this function takes advantage of cut() and by() to group each experiment into trials by factor then analyze each trial to get correct or incorrect latency
	# Currently indifferent to left or right latency

	# 3|left lever press
	# 4|right lever press
	# 5|press requirement met on left lever; also correct left requirement met in choice trials
	# 6|press requirement met on right lever; also correct right requirement met in choice trails
	# 18|right lever cue delivery
	# 19|left lever cue delivery
	# 22|Incorrect left choice
	# 23|Incorrect right choice
	# 43|Required head entry
	# 44|Traylight(light above food hopper) ON, or start flashing
	# 45|Traylight OFF, or stop flashing
	# 48|Right lever cue light ON
	# 49|Right lever cue light OFF (can be siganlled by 25)
	# 50|Left lever cue light ON
	# 51|Left lever cue light OFF (can be siganlled by 25)
	# 52|Left lever extends
	# 53|Left lever retracts
	# 54|Right lever extends
	# 55|Right lever retracts
	# 58|Start choice trial, left is correct
	# 59|Start choice trial, right is correct

	# Use above information to set event values to search for
	TRIAL_START = c(58,59)
	LEVER_EXTEND = c(52,54)
	CORRECT = c(5,6)
	INCORRECT = c(22,23)
	TRAY_LIGHT_ON = 44
	REQUIRED_HE = 43
	# LEFT_CORRECT = 5
	# RIGHT_CORRECT = 6
	# LEFT_PRESS = 3
	# RIGHT_PRESS = 4

	# Get start location for each trial
	cueIDs = which(data$events %in% TRIAL_START)
	# Data points in trial
	vlen = length(data$events)
	# Break the experiment into groups based on trial start times
	groups = cut(c(1:vlen),breaks=c(1,cueIDs-1,vlen),labels=c(0:length(cueIDs)))

	# This function gets latency for correct/incorrect compared to startIdx
	correctCheck <- function(x,correct,incorrect,startIdx){
		checkTrue = sum(x$events %in% correct)
		choice = correct
		if(checkTrue==FALSE){
			# checkTrue = sum(x$events %in% incorrect)
			# ifelse(test, yes, no)
			choice = incorrect
		}
		outputTime = x$time[which(x$events %in% choice)]-x$time[which(x$events %in% startIdx)]
		return(c(checkTrue,mean(outputTime)))
	}

	# data to send back out
	output = list()
	# given a list of vectors with (correct,time) pairs
	latencyInfo = by(data=data,INDICES=groups,FUN=correctCheck,correct=CORRECT,incorrect=INCORRECT,startIdx=LEVER_EXTEND)
	# Convert to data.frame
	latency = data.frame(matrix(unlist(latencyInfo),ncol=2,byrow=TRUE))
	# Add names for convenience
	names(latency) = c('choice','time')

	# For correct and incorrect, find mean and sd then return
	correctTimes = latency$time[latency$choice==1]
	incorrectTimes = latency$time[latency$choice==0]
	output$press_correct_latency_mean = mean(correctTimes,na.rm=TRUE)
	output$press_correct_latency_sd = sd(correctTimes,na.rm=TRUE)
	output$press_incorrect_latency_mean = mean(incorrectTimes,na.rm=TRUE)
	output$press_incorrect_latency_sd = sd(incorrectTimes,na.rm=TRUE)

	return(output)
}
getMouseRaw <- function(file,data_main_dir){
	# Number of lines to skip before event times
	INTROLINES = 0
	# Max number of rows to read in
	MAXROWS = Inf
	# How many columns to split file into and their data types
	COLCLASS = c("character","character","character","numeric","numeric","numeric")
	# Identifier for events data group
	EVENTS_ID = 'E:'
	# Identifier for timestamp data group
	TIMESTAMP_ID = 'D:'
	# # choice trial, correctly pick left lever
	# REQ_RIGHT = 6
	# # choice trial, correctly pick left lever
	# REQ_LEFT = 5
	# # conditioned stimulus OFF
	# CS_OFF_ID = 31
	# # conditioned stimulus OFF
	# CS_OFF_ID = 31
	# centi to seconds
	TIMECONVERT = 100
	# # Amount of seconds to look before the cue
	# PRECUETIME = 10
	# _________________________________________________
	# Import data, split into five rows
	mouseRawData = read.table(paste(data_main_dir,file,sep=""),header=F,skip=INTROLINES,nrows=MAXROWS,fill=TRUE,colClasses=COLCLASS)
	# Rename columns
	names(mouseRawData) = paste("V",c(1:5),sep="")
	# print(mouseRawData)
	# _________________________________________________
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

	return(mouseEventTimes)
}
	# # _________________________________________________
	# # Get row numbers for all conditioned stimulus trials
	# csTrials = which(mouseEventTimes$events==CS_ON_ID)#CS_ON_ID
	# lickCount = data.frame()
	# for (csTrial in csTrials){
	# 	trialCounts = list()
	# 	# Get CS, pre-CS and post-CS times
	# 	timeCS = mouseEventTimes$time[csTrial]
	# 	timePre = mouseEventTimes$time[csTrial]-PRECUETIME
	# 	timePost = mouseEventTimes$time[csTrial]+PRECUETIME
	# 	# Get the pre-cue indicies/events
	# 	preCueIndx = (mouseEventTimes$time<timeCS)&(mouseEventTimes$time>=timePre)
	# 	postCueIndx = (mouseEventTimes$time>timeCS)&(mouseEventTimes$time<=timePost)
	# 	# Get number of pre-cue events that are licks
	# 	trialCounts$time = timeCS
	# 	trialCounts$precounts = sum(mouseEventTimes[preCueIndx,]$events==LICK_ID)
	# 	trialCounts$postcounts = sum(mouseEventTimes[postCueIndx,]$events==LICK_ID)
	# 	trialCounts$cs = which(csTrials==csTrial)
	# 	lickCount = rbind(lickCount,data.frame(trialCounts))
	# }
	# lickMetric = sum(lickCount$postcount)-sum(lickCount$precount)
	# return(lickCount)