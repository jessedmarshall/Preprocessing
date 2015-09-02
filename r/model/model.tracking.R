# biafra ahanonu
# updated: 2013.09.01 [21:27:14]
# series of functions to help extract
# designed to be used in parallel if possible
# m882 = getTrackingData('E:/biafra/data/behavior/open_field/p97/2013_09_04_p97_m882_oft1.tracking')

# load packages
packagesFileList = c("reshape2", "ggplot2", "parallel", "stringr")
lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})

# fileList = list.files('E:/biafra/data/behavior/open_field/p97/for_analysis/tracking', full.names=T)

# cl = model.cluster()

# source('model/model.tracking.pav.R')
model.tracking <-function(thisDir,...){
	require(gridExtra)
	startTime = Sys.time()
	# thisDir = 'A:/biafra/data/behavior/open_field/p97/tracking/tmp';
	# thisFile = '2013_10_28_p97_m593_oft1.tif.tracking';
	v = getTrackingData(thisDir);
	# v = getTrackingData(paste(thisDir,'/',thisFile,sep=""));
	missingFrames = which(!(c(1:max(v$Slice) %in% unique(v$Slice))));
	incorrectSpeed = which(v$velocity>100);
	print('missing frames')
	print(missingFrames);
	print('incorrect speeds')
	print(incorrectSpeed);
	print(nrow(v));print(max(v$Slice));print(nrow(v)/max(v$Slice));
	# saveFilePath = paste(thisDir,'/',thisFile,'.tab',sep="")
	saveFilePath = paste(thisDir,'.tab',sep="")
	saveFilePath = gsub('(\\.avi|\\.csv)','',saveFilePath)
	writeData(v,saveFilePath);
	print(Sys.time()-startTime); flush.console();

	# create a theme function
	ggTheme <- function(...) theme(panel.background = element_rect(fill = "white", colour = NA), text = element_text(size=15))
	# print
	if(length(missingFrames)>0){
		p1 = ggplot(v, aes(XM, YM))+geom_path(aes(color=velocity))+scale_color_continuous(low="black", high="red")+
		geom_point(data=v[missingFrames,], size=2, color="yellow")+ggTheme()
	}else{
		p1 = ggplot(v, aes(XM, YM))+geom_path(aes(color=velocity))+scale_color_continuous(low="black", high="red")+ggTheme()
	}
	p2 = ggplot(v, aes(Slice, velocity))+geom_line()+ggTheme()
	leftDivide = 375
	rightDivide = 750
	p3 = ggplot(v,aes(XM,YM))+stat_binhex()+scale_fill_gradient(low="black", high="red")+ggTheme()
	# +
	# geom_vline(xintercept = leftDivide)+geom_vline(xintercept = rightDivide)

	nPts = length(v$XM)
	pctLeft = sum(v$XM<leftDivide)/nPts
	pctMiddle = sum(v$XM>leftDivide&v$XM<rightDivide)/nPts
	pctRight = sum(v$XM>rightDivide)/nPts
	cppData = data.frame(values=c(pctLeft,pctMiddle,pctRight),name=c('pctLeft','pctMiddle','pctRight'))
	p4 = ggplot(cppData,aes(name,values,fill=name))+geom_bar()+ggTheme()
	v$cumSum = cumsum(v$velocity)
	p4 = ggplot(v, aes(Slice, cumSum))+geom_line()+ggTheme()

	dev.new()
	print(basename(thisDir))
	grid.arrange(p1, p2, p3, p4, ncol=2, nrow=2, main = basename(thisDir))

	return(v)
}

# parLapply(cl, fileList, FUN=function(x){})

getTrackingData <-function(file,...){
	# extracts the tracking data from a file and formats it then adds to the dataStruct list
	v = read.table(file, sep=",", header=T)
	# remove objects that have an incorrect ratio
	axisRatio = 8
	axisRatioIdx = which(v$Major/v$Minor<axisRatio)
	v = v[axisRatioIdx,]
	# find largest obj
	idx = which(ave(v$Area, v$Slice, FUN=function(x){rank(-x,ties.method="first")})==1)
	v2 = v[idx,]
	# do.call('rbind', by(v, v$Slice, FUN=function(x){maxIdx = x$Area>=max(x$Area); return(x[maxIdx,])}))
	# get speed at each time-point
	output = getVelocity(v2)

	# # factor the rows based on time
	# numBinsTrial = 30
	# lenV2 = nrow(v2)
	# timeMouseData = seq(1,lenV2,length.out = numBinsTrial)
	# # make psuedo-factors to bin each timepoint into
	# vCuts = cut(1:lenV2,timeMouseData)
	# v2$trial = vCuts
	# # add factor slice number for faceting
	# v3 = do.call('rbind', by(v2, v2$trial, FUN=function(x){x$trialSlice = c(1:nrow(x)); return(x)}))

	return(output)
}
writeData <- function(data, file, sep="\t"){
	print(file)
	write.table(data, file=file, sep=sep, col.names=TRUE, row.names=FALSE)
}
displayPlots <-function(...){
	# plot
	ggplot(v3, aes(XM, -YM))+geom_path(aes(color=trialSlice))+scale_color_continuous(low="blue", high="red")+
	# geom_text(x=200,y=-19,label="spout")+
	geom_text(x=200,y=-100,label="+")+
	geom_text(x=50,y=-100,label="O")+
	geom_text(x=300,y=-100,label="O")+
	facet_wrap(~trial)

	ggplot(v3, aes(trialSlice, velocity, color=trialSlice))+geom_line()+facet_wrap(~trial)

	ggplot(v3, aes(XM, -YM))+geom_path(aes(color=velocity))+scale_color_continuous(low="blue", high="red")+
	# geom_text(x=200,y=-19,label="spout")+
	geom_text(x=200,y=-100,label="+")+
	geom_text(x=50,y=-100,label="O")+
	geom_text(x=300,y=-100,label="O")+
	facet_wrap(~trial)

	lapply(newplots, FUN=function(x){dev.new();print(x)})

}
getVelocity <-function(v3){
	dx = diff(v3$XM)
	dy = diff(v3$YM)
	distanceMoved = sqrt(dx^2 + dy^2)
	distanceMoved = c(0, distanceMoved)
	distanceMoved[is.na(distanceMoved)]=0
	v3$velocity = distanceMoved

	return(v3)
}

setTrackingToEvent <-function(dataStruct, eventData,...){
	# annotate the slices in a stack with a particular event information for faceting later\


	# add the ITI/pre/postCS info

	# add the CS trial info and time relative to CS


}

getKinematics <-function(dataStruct,...){
	# obtain kinematics of the animal


}