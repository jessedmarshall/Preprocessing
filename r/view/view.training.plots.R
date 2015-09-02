# biafra ahanonu
# 2013.02.08
# mouse training analysis
setwd("C:/Users/B/Dropbox/biafra/Stanford/Lab/schnitzer/scripts/R/")
#________________________________________________________
# Re-run parsing algorithm
runModel = type.convert(winDialogString("Parse data (TRUE) or not (FALSE)","FALSE"),as.is = TRUE)
if(runModel==TRUE){
	if(PERSON=='biafra'){
		source("model.parse.training.data.R")
	}else{
		source("model.parse.training.data.jones.R")
	}
}
PERSON = 'biafra'
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
# Set directory information, create appropriate directories
c(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir="../../data/",dataSubDir="databases/analysis/",analysisDir="../../analysis/temp/")
#________________________________________________________
if(PERSON=='biafra'){
	mouseSummaryFile = "database.mice.training.csv"
	mouseRawFile = "database.mice.training.raw.csv"
}else{
	mouseSummaryFile = "behavior/database.mice.training.jones.csv"
	mouseRawFile = "behavior/database.mice.training.raw.jones.csv"
}
# _________________________________________________
REQUIRED_HE = 43
# _________________________________________________
# Graphs
mouse = read.table(paste(data_main_dir,mouseSummaryFile,sep=""),header=TRUE,sep=",")
# CHOICE_TRIALS = c('2.1.0','2.1.1','2.1.2','3.1.0','2.1.3')
CHOICE_TRIALS = c('j2.1','j2.1.1','j3.1')
mouse$phase = as.character(mouse$phase)
mouse$date = as.character(mouse$date)
# ______________
# Make lineplot of total left/right forced trials
mouseTemp = mouse[!(mouse[['phase']] %in% CHOICE_TRIALS),]
mousePlot = ggplot(mouseTemp,aes(x=date,y=forced_rt+forced_lt-head_end_omissions-press_omissions,group=mouse,colour=phase))+geom_line()
# mousePlot = ggplot(mouseTemp,aes(x=date,y=forced_rt+forced_lt-head_end_omissions-press_omissions))+geom_boxplot()
newMousePlot = mousePlot+ylab("forced trials minus omissions")+facet_grid(type ~ .)
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_line.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=2500,title="Q175 Training",rotX=TRUE)

mouseTemp = mouse[!(mouse[['phase']] %in% CHOICE_TRIALS),]
newMousePlot = ggplot(mouseTemp,aes(x=date,y=forced_rt+forced_lt-head_end_omissions-press_omissions,colour=type,group=mouse))+geom_line()+geom_smooth(aes(group=type,size=1,fill=type))
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_line_2.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=2500,title="Q175 Training",rotX=TRUE)
# ______________
# Make a line plot of correct choice trials, only phase
mouseTemp = mouse[mouse[['phase']] %in% CHOICE_TRIALS,]
mousePlot = ggplot(mouseTemp,aes(x=date,y=correct/(incorrect+correct),group=mouse,colour=mouse))+geom_line()
# mousePlot = ggplot(mouseTemp,aes(x=date,y=correct-incorrect))+geom_boxplot()
newMousePlot = mousePlot+
# geom_ribbon(data=data.frame(date=mouse$date),mapping=aes(x=date,ymin=.4, ymax=.6,fill=rgb(0,1,0,.5)),inherit.aes=FALSE)+
ylab("correct trials (%)")+facet_grid(type ~ .)
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_line_correct.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=2500,title="Q175 Training",rotX=TRUE)

newMousePlot = ggplot(mouse[mouse[['phase']] %in% CHOICE_TRIALS,],aes(date,correct/(correct+incorrect),colour=type,group=mouse))+
geom_line()+
# geom_smooth(aes(group=type,size=1,fill=type))+
stat_summary(fun.data = "mean_cl_boot",geom = "errorbar", size=3,aes(group=type,colour=type))+
stat_summary(fun.data = "mean_cl_boot",geom = "line", size=3,aes(group=type,colour=type))+
ggtitle("")
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_line_correct_2.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=2500,title="Q175 Training",rotX=TRUE)

newMousePlot = ggplot(mouse[mouse[['phase']] %in% CHOICE_TRIALS,],aes(date,correct/(correct+incorrect),colour=type,group=mouse))+
geom_line()+
geom_smooth(aes(group=type,fill=type),size=1)+
theme(line = element_blank(),panel.background = element_rect(fill = "white", colour = NA), text = element_text(size=20),axis.text.x=element_blank())+
ggtitle("")+xlab("")
# stat_summary(fun.data = "mean_cl_boot",geom = "errorbar", size=3,aes(group=type,colour=type))+
# stat_summary(fun.data = "mean_cl_boot",geom = "line", size=3,aes(group=type,colour=type))+
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_line_correct_3.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=2500,title="Q175 Training",rotX=TRUE)
# ______________
# Correct as a function of day time
# if(PERSON=='biafra'){
dayStart = 7
dayEnd = 19
mouse$dayCycle = mouse$fileTime>=dayStart&mouse$fileTime<=dayEnd
newMousePlot = ggplot(mouse[mouse[['phase']] %in% CHOICE_TRIALS,],aes(fileTime,correct/(correct+incorrect),colour=type,group=mouse))+
geom_polygon(data=data.frame(time=c(dayStart,dayStart,dayEnd,dayEnd),ydata=c(0,1,1,0)),mapping=aes(x=time,y=ydata,fill=rgb(0,0,0)),alpha=0.5,inherit.aes=FALSE)+
geom_point()+
ggtitle("")
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_correct_filetimes_lines.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=1600,title="Q175 Training, circadian confounds?",rotX=TRUE)

newMousePlot = ggplot(mouse[mouse[['phase']] %in% CHOICE_TRIALS,],aes(x=dayCycle,y=correct/(correct+incorrect),colour=type,group=dayCycle))+
geom_boxplot(notch=TRUE)+
geom_jitter(aes(colour=type,group=dayCycle),position = position_jitter(width = .1))+
ggtitle("")
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_correct_filetimes.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=900,height=2500,title="Q175 Training, circadian confounds?",rotX=TRUE)

newMousePlot = ggplot(mouse,aes(x=date,y=fileTime,colour=type,group=date))+
# geom_polygon(data=data.frame(time=c(dayStart,dayStart,dayEnd,dayEnd),ydata=c(0,1,1,0)),mapping=aes(x=ydata,y=time,fill=rgb(0,0,0)),alpha=0.3,inherit.aes=FALSE)+
geom_boxplot()+
geom_point()+
coord_flip()+
# coord_polar()+
ggtitle("")
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_correct_filetimes_boxplot_check_al.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=1600,title="Q175 Training, circadian confounds?",rotX=TRUE)
# }
# ______________
# Look at choice bias
newMousePlot = ggplot(mouse,aes(x=date,y=(correctLeft-correctRight)/(correctLeft+correctRight),colour=phase,group=mouse))+
geom_line()+facet_grid(type~.)+ylab("left(1)/right(-1) bias")
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_right_left_bias.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=2500,title="Q175 correct choice bias",rotX=TRUE)
# ______________
# latency to head entry
newMousePlot = ggplot(mouse[mouse[['phase']] %in% CHOICE_TRIALS,],aes(date,mean_lat_to_he,colour=type,group=mouse))+geom_line()+geom_smooth(aes(group=type,size=1,fill=type))
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_late_to_he.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=2500,title="Q175 correct choice bias",rotX=TRUE)
# ______________
# latency to press
newMousePlot = ggplot(mouse[mouse[['phase']] %in% CHOICE_TRIALS,],aes(date,mean_lat_to_press,colour=type,group=mouse))+geom_line()+geom_smooth(aes(group=type,size=1,fill=type))
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_late_to_press.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=2500,title="Q175 correct choice bias",rotX=TRUE)
# ______________
# compare latency to press
newMousePlot = ggplot(mouse[mouse[['phase']] %in% CHOICE_TRIALS,],aes(x=mean_lat_to_press,y=mean_lat_to_he,size=correct/(correct+incorrect),colour=type,group=mouse))+
geom_point()+
geom_density2d(mapping=aes(x=mean_lat_to_press,y=mean_lat_to_he,colour=type),inherit.aes=FALSE)
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_late_to_press_points.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=1600,title="Q175 latency",rotX=TRUE)
# ______________
# compare latency to press
bestFit = as.numeric(coef(lm(press_correct_latency_mean ~ press_incorrect_latency_mean, data = mouse[mouse[['mouse']] %in% c('Y2'),])))
newMousePlot = ggplot(mouse[mouse[['phase']] %in% CHOICE_TRIALS,],aes(x=press_correct_latency_mean,y=press_incorrect_latency_mean,size=correct/(correct+incorrect)))+
geom_density2d(mapping=aes(x=press_correct_latency_mean,y=press_incorrect_latency_mean,colour=type),inherit.aes=FALSE)+
geom_point(aes(colour=type,group=mouse))+
# geom_abline(intercept=bestFit[1],slope=bestFit[2])+
scale_y_log10()+scale_x_log10()
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_latency_press_correct.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=1600,title="Q175 latency to press correct vs. incorrect",rotX=TRUE)
# _________________________________________________
plotData = array()
# Raw graphs
# read in data
allMouseRawData = read.table(paste(data_dir,mouseRawFile,sep=""),header=TRUE,sep=",")
allMouseRawData$phase = as.character(allMouseRawData$phase)
allMouseRawData$date = as.character(allMouseRawData$date)
allMouseRawDataChoice = allMouseRawData[allMouseRawData[['phase']] %in% CHOICE_TRIALS,]
# ______________
# Look at pressing over time
newMousePlot = ggplot(allMouseRawData[allMouseRawData$events %in% c(LEFT_CORRECT,RIGHT_CORRECT),],aes(x=time,fill=mouse))+geom_histogram(bindwidth=20,stat="bin",colour="white")+facet_grid(type~.)
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_line_leftright_presses.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=1500,title="Q175 count of left/right presses",rotX=FALSE)
# ______________
# Look at pressing over time with phases
newMousePlot = ggplot(allMouseRawData[(allMouseRawData$events %in% c(LEFT_CORRECT,RIGHT_CORRECT)),],aes(x=time,fill=mouse))+geom_histogram(bindwidth=20,stat="bin",colour="white")+facet_grid(type~phase)
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_line_leftright_presses_phase.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=1500,title="Q175 count of left/right presses",rotX=FALSE)
# ______________
# Look at head entries over time
newMousePlot = ggplot(allMouseRawDataChoice[(allMouseRawDataChoice$events %in% c(REQUIRED_HE)),],aes(x=date,fill=type))+
geom_histogram(bindwidth=20,stat="bin",colour="white")
# Save the file
plotFile = paste(analysis_dir,current_date,"_training_raw_head_entries.png",sep="")
pngSave(plotData=newMousePlot,file=plotFile,width=2500,height=1500,title="Q175 count of required head entries",rotX=TRUE)
# ______________
# Loop over all plots made and save them
for (plotData in plotList) {
	plot = plotData[1]
	filename = plotData[2]
	title = plotData[3]
	plotFile = paste(analysis_dir,current_date,filename,sep="")
	pngSave(plotData=plot,file=plotFile,width=2500,height=1500,title=title,rotX=TRUE)
}