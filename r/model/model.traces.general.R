# biafra ahanonu
# updated: 2013.08.14 [20:31:08]
# general function to retrieve traces
# rm(list=ls())
require(parallel)
require(reshape2)

analyzeTraces <- function(traceFile,...){
	result = tryCatch({
			print(traceFile); flush.console();
			# get the raw trace and event data
			traceData = getRawData(traceFile, "", "")
			traceDataSpikes = traceData$traceDataSpikes
			# get the sum of the traces within given timepoints
			traceSum = getTraceSums(traceDataSpikes)

			# add trace file to data.frames
			traceDataSpikes$file = traceFile
			traceSum$file = traceFile
		}, error = function(err) {
			print(err)
			print(traceback())
			traceDataSpikes=NULL
			traceSum=NULL
			return(dataStruct)
		}, finally = {
			return(list(traceDataSpikes=traceDataSpikes,traceSum=traceSum))
		})

}
getRawData <- function(traceFile, eventFile, trialFileName, spikeThreshold = 0.05, traceHz = 5, CS_ON_ID = 30, ...) {
	output = list()
	# read in the data
	traceData = as.matrix(read.table(traceFile, sep=",", header=FALSE, colClasses="numeric"))
	traceDataSpikes = filterSpikes(traceData)

	output$traceDataSpikes = traceDataSpikes
	return(output)
}
filterSpikes <- function(traceData, spikeZscoreThreshold = 5, traceHz = 5, ...){
	# arbitrary spike threshold
	# traceDataSpikes = traceData>spikeThreshold
	# only take spikes above the standard deviation
	# traceDataSpikes = apply(t(traceData),2,FUN=function(x, zscore){
	# 		x = as.numeric(x)
	# 		xmean=mean(x);
	# 		xstd=sqrt(var(x));
	# 		return(as.numeric(x>(xmean+zscore*xstd)))
	# 	}, zscore=spikeStdThreshold)
	# x=matrix(rnorm(1000), 500, 15000);
	traceDataSpikes=traceData>(rowMeans(traceData)+spikeZscoreThreshold*diag(var(t(traceData))))
	traceDataSpikes = as.data.frame(traceDataSpikes)
	# add cell IDs to dataframe
	traceDataSpikes = cbind(data.frame(cellID=1:nrow(traceDataSpikes)),traceDataSpikes)
	# melt to make easier to plot
	traceDataSpikesCleaned = melt(traceDataSpikes, id="cellID")
	names(traceDataSpikesCleaned) = c('cellID','frame','spikes')
	# only keep spikes to save memory
	traceDataSpikesCleaned = traceDataSpikesCleaned[traceDataSpikesCleaned$spikes>0,]
	head(traceDataSpikesCleaned)
	# convert time points to numeric
	traceDataSpikesCleaned$frame = as.numeric(gsub("V","",traceDataSpikesCleaned$frame))
	# add time in seconds
	# traceDataSpikesCleaned$time = traceDataSpikesCleaned$frame/traceHz
	# # to separate cells on y axis
	# traceDataSpikesCleaned$cellSpikes = traceDataSpikesCleaned$spikes*traceDataSpikesCleaned$cellID

	return(traceDataSpikesCleaned)
}
getTraceSums <- function(traceDataSpikes){
	# sum spikes at each timepoint to make PSTH
	PSTH = tapply(traceDataSpikes$spikes,INDEX=as.factor(traceDataSpikes$frame), sum)
	time = sort(unique(traceDataSpikes$frame))
	traceSum = data.frame(time, PSTH)

	return(traceSum)
}
plotTraceData <- function(...){
	# plot traces
	newplot = ggplot(traceDataSpikes,aes(frame,value))+
	geom_point(aes(color=cellID))
	print(newplot)

	# plot PSTH
	newplot = ggplot(traceSum,aes(time,PSTH))+
	geom_line()
	dev.new();print(newplot)

}
pngSave <- function(plotData,file,width=3200,height=1800,title="",rotX=FALSE,footnote="") {
	png(file,width=width,height=height,res=200,pointsize=10,antialias="cleartype")
		if(rotX==TRUE){
		plotData = plotData + theme(axis.text.x = element_text(angle = 90, hjust = 1))
		}
		plotData = plotData + ggtitle(title)
		print(plotData)
		makeFootnote(footnoteText=footnote)
	dev.off()
	print(file)
}