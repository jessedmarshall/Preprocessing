# biafra ahanonu
# 2013.03.05
# read in medpc data and put into data.frame for later processing
# changelog
	# 2014.05.07 [20:37:47] separated from operant specific, made more general and adaptable
	# 2014.05.07 [21:02:57] added readMedpcFileSpecificValue

readMedpcFiles <- function(filePath,events_id='E:',timestamp_id = 'D:'){
	result = tryCatch({
		# Number of lines to skip before event times
		INTROLINES = 0
		# Max number of rows to read in
		MAXROWS = Inf
		# How many columns to split file into and their data types
		COLCLASS = c("character","character","character","numeric","numeric","numeric")
		# Identifier for events data group
		EVENTS_ID = events_id
		# Identifier for timestamp data group
		TIMESTAMP_ID = timestamp_id
		# centi to seconds
		TIMECONVERT = 100
		# _________________________________________________
		# Find out how many rows to read
		# filePath = paste(data_main_dir,file,sep="")
		#
		rawFileData = scan(filePath,what="character",sep = "\n",quiet=TRUE)
		# Find location of first bit of real data, use to set number of lines to skip
		skipLines = which(rawFileData=="A:")+1
		# Import data, split into five rows
		rawData = read.table(filePath,header=F,skip=skipLines,nrows=MAXROWS,fill=TRUE,colClasses=COLCLASS)
		# Rename columns
		names(rawData) = paste("V",c(1:5),sep="")
		# print(mouseRawData)
		# _________________________________________________
		bindingData = list()
		for (dataID in c(EVENTS_ID,TIMESTAMP_ID)) {
			# Get row index for events
			eventsStartLine = which(rawData$V1==dataID)
			# Get row index for all data group types
			groupLocations = which(rawData$V1 %in% paste(LETTERS,":",sep=""))
			# Get stop line for events
			eventsStopLine = groupLocations[which(groupLocations==eventsStartLine)+1]
			# print(paste(eventsStartLine,groupLocations,eventsStopLine))
			# Get all the events from the matrix
			rawDataMod = rawData[(eventsStartLine+1):(eventsStopLine-1),]
			# print(rawDataMod)
			bindingData[[LETTERS[length(bindingData)+1]]] = as.numeric(as.vector(t(rawDataMod[,2:6])))
			# if(dataID==EVENTS_ID){
			# 	# Reshape to a 1xn vector
			# 	events = as.integer(as.vector(t(rawDataMod[,2:6])))
			# }else if(dataID==TIMESTAMP_ID){
			# 	# Reshape to a 1xn vector
			# 	timestamps = as.numeric(as.vector(t(rawDataMod[,2:6])))/TIMECONVERT
			# }
		}
		# _________________________________________________
		# Combine into one dataframe
		rawEventTimes = data.frame(cbind(bindingData$A,bindingData$B/TIMECONVERT))
		names(rawEventTimes) = c('events','time')
		# Remove NaNs
		if(sum(is.na(rawEventTimes))>0){
			rawEventTimes = rawEventTimes[1:(which(is.na(rawEventTimes))[1]-1),]
		}
		return(rawEventTimes)
	}, error = function(err) {
		print(err)
		print(traceback())
		print(warnings())
		return(data.frame(events=c(NULL,NULL),time=c(NULL,NULL)))
	}, finally = {
		print(filePath)
	})

}
readMedpcOverviewValues <- function(filePath,identifier="Q:",column=2){
	# Find out how many rows to read
	# filePath = paste(data_main_dir,file,sep="")
	#
	rawFileData = scan(filePath,what="character",sep = "\n")
	# Find location of first bit of real data, use to set number of lines to skip
	skipLines = which(regexpr(identifier,rawFileData)>0)+1
	#
	rawData = read.table(filePath,header=F,skip=skipLines,nrows=1,fill=TRUE)
	# get value
	value = rawData[column]
	return(value)
}
readMedpcFileSpecificValue <- function(filePath,identifier="Q:",column=2){
	# Find out how many rows to read
	# filePath = paste(data_main_dir,file,sep="")
	#
	rawFileData = scan(filePath,what="character",sep = "\n")
	# Find location of first bit of real data, use to set number of lines to skip
	skipLines = which(regexpr(identifier,rawFileData)>0)+1
	#
	rawData = read.table(filePath,header=F,skip=skipLines,nrows=1,fill=TRUE)
	# get value
	value = rawData[column]
	return(value)
}