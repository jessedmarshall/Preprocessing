# biafra ahanonu
# updated: 2013.08.20 [15:22:48]
# get pav event data and align it to trace data
require(reshape2)

getEventData <-function(eventFile, spikeThreshold = 0.05, traceHz = 5, CS_ON_ID = 30, LICK_ID = 24){
	# read event data
	eventDataRaw = read.table(eventFile, sep="\t", header=TRUE)
	# look at only the CS on times and filename
	# eventDataFiltered = eventData[eventData$file==trialFileName&eventData$events==CS_ON_ID,]
	eventDataCueOnly = eventDataRaw[eventDataRaw$events==CS_ON_ID,]
	eventDataLickOnly = eventDataRaw[eventDataRaw$events==LICK_ID,]
	# correct time for removal of first three frames
	framesRemoved = 6
	eventDataCueOnly$framesCorrected = eventDataCueOnly$time*traceHz-framesRemoved
	eventDataLickOnly$framesCorrected = eventDataLickOnly$time*traceHz-framesRemoved

	output = list()
	output$eventDataCueOnly = eventDataCueOnly
	# output$eventDataRaw = eventData[eventData$file==trialFileName,]
	output$eventDataRaw = eventDataRaw
	output$eventDataLickOnly = eventDataLickOnly
	return(output)
}
registerTracesToCS <- function(eventData, traceSum){
	# register all spikes to CS
	listRegisteredCsData = lapply(eventData$framesCorrected, FUN=timeAroundCS, traceSum = traceSum, eventData=eventData)
	registeredCsData = data.frame()
	registeredCsData = do.call('rbind', listRegisteredCsData)
	# for (thisData in listRegisteredCsData) {
	# 	registeredCsData = rbind(registeredCsData, thisData)
	# }
	return(registeredCsData)
}
timeAroundCS <- function(timeCS, traceSum, eventData, timeAroundCSView = 20*5, timeAroundCSCount = 10*5,...){
	# labels data points around timeCS
	timePre = timeCS-timeAroundCSCount
	timePost = timeCS+timeAroundCSCount
	# Get the pre-cue indices/events
	ITIIndx = (traceSum$time<=timePre)&(traceSum$time>=timePre-30)
	preCueIndx = (traceSum$time<timeCS)&(traceSum$time>=timePre)
	postCueIndx = (traceSum$time>timeCS)&(traceSum$time<=timePost)
	postUSIndx = (traceSum$time>timePost)
	traceSum$eventType[preCueIndx] = 'preCS'
	traceSum$eventType[postCueIndx] = 'postCS'
	traceSum$eventType[postUSIndx] = 'postUS'
	traceSum$eventType[ITIIndx] = 'ITI'
	#
	traceSumFiltered = traceSum[(traceSum$time<timeCS+timeAroundCSView)&(traceSum$time>timeCS-timeAroundCSView),]
	traceSumFiltered$time = traceSumFiltered$time - timeCS
	# flush.console()
	if(nrow(traceSumFiltered)==0){
		# traceSumFiltered$CSnum =
	}else{
		traceSumFiltered$CSnum = eventData$CSnum[which(eventData$framesCorrected==timeCS)]
	}
	return(traceSumFiltered)
}
# registerSpikesToEvent <-
classify <-function(dataStruct){

}