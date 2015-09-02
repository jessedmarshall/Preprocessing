# biafra ahanonu
# 2013.02.08
# mouse training analysis
setwd("C:/Users/B/Dropbox/biafra/Stanford/Lab/schnitzer/scripts/R/")
# _________________________________________________
# Re-run parsing algorithm
# source("model.parse.training.data.R")
# _________________________________________________
# Load libraries and dependencies
# For plotting
library(ggplot2)
library(gridExtra)
# Add time-stamped footnote to graphs
source("view.footnote.R")
# Function to get directory info and create folders
source("helper.getDir.R")
# Set directory information, create appropriate directories
c(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir="../../data/",dataSubDir="roto_rod/",analysisDir="../../analysis/temp/biafra/")
# _________________________________________________
# Contains main roto-rod data
inputFile = "database.mice.rotorod.csv"
mouse = read.table(paste(data_main_dir,inputFile,sep=""),header=T,sep=",")
# Hash table to match column names to date/trial
hashFile = "database.mice.rotorod.hash.csv"
mouseHash = read.table(paste(data_main_dir,hashFile,sep=""),header=T,sep=",")

# Get a list of date,trial pairs
# mouseDataColumns = unlist(strsplit(gsub("[[:punct:]]","-",gsub("X","",names(mouse)))[6:length(names(mouse))],'-'))
mouseDataColumns = unlist(strsplit(gsub("[[:punct:]]","-",gsub("X","",names(mouse)))[6:length(names(mouse))],'x'))
# Get the sequence of mouse trials
mouseTrials = mouseDataColumns[seq(2,length(mouseDataColumns),2)]
# Get sequence of dates
mouseDates = mouseDataColumns[seq(1,length(mouseDataColumns),2)]
# tempDate = list()
# for (i in c(1:length(mouseDates))) {
# 	tempDate[[i]] = as.vector(mouseHash[mouseDates[i],]$date)
# 	print(as.vector(mouseHash[mouseDates[i],]$date))
# }
# tempDate = unlist(tempDate)
tempDate = mouseDates

# Loop over each mouse and re-order data
mouseData = data.frame()
for(i in c(1:nrow(mouse))){
	imouse = as.vector(mouse[i,])
	time = as.numeric(t(imouse[,6:ncol(imouse)]))
	mouseData = rbind(mouseData,cbind(imouse[,1:5],time,trials=mouseTrials,date=tempDate))
}

# seScores = predict(lm(time ~ type+date,data=mouseData),se=TRUE)[c("fit","se.fit")]
# data=data.frame(mouseData[1:155,],seScores);
# ggplot(data,aes(date,fit,ymin=fit-se.fit,ymax=fit+se.fit,colour=type))+
# geom_linerange()+
# geom_pointrange()

mouseTime = ggplot(mouseData[which(mouseData$trial!=0),],aes(x=date,y=time,group=type,colour=type))+
stat_summary(fun.data = "mean_cl_boot",geom = "errorbar", width=0.1,size=1)+
stat_summary(fun.data = "mean_cl_boot",geom = "point", size=3,shape=15)+
ylab("latency to fall (s)")+
scale_y_log10(breaks=c(10,20,30,50))+
ggtitle("Q175 roto-rod latency")

mouseMistakes = ggplot(mouseData[which(mouseData$trial==0),],aes(x=date,y=time,group=type,colour=type))+
stat_summary(fun.data = "mean_cl_boot",geom = "errorbar", width=0.1,size=1)+
stat_summary(fun.data = "mean_cl_boot",geom = "point", size=3,shape=15)+
ylab("retries (latency<6s)")+
ggtitle("Q175 roto-rod retries")

print(grid.arrange(mouseTime,mouseMistakes))

png(paste(analysis_dir,current_date,"_rotorod_p25.png",sep=""),width=2400,height=1350,res=200,pointsize=10,antialias = "cleartype")
	print(grid.arrange(mouseTime,mouseMistakes))
	makeFootnote()
dev.off()

# geom_line(aes(x=date,y=time))
# ggplot(mouseData,aes(trials,time,colour=mouse,group=mouse))+geom_line()+geom_point()+facet_grid(type~date,scale="free")

# gggplot(mouseData,aes(trials,time,colour=factor(type),group=factor(type)))+
# stat_summary(fun.data = "mean_cl_boot")+
# facet_grid(.~date,scale="free")

# ggplot(mouseData,aes(type,time,fill=type,group=trials))+geom_bar(stat = "identity", position="dodge")+ scale_fill_grey()+facet_grid(.~date,scale="free")

# newMousePlot = ggplot(mouseData,aes(trials,time,fill=type,group=type))+
# geom_boxplot()+
# facet_grid(.~date,scale="free")+
# ggtitle("Q175 roto-rod performance")

# newMousePlot = ggplot(mouseData,aes(factor(trials),time,fill=type,group=type))+
# geom_boxplot()+
# facet_grid(.~date,scale="free")+
# ggtitle("Q175 roto-rod performance")

# png(paste(analysis_dir,current_date,"_rotorod.png",sep=""),width=2400,height=1350,res=200,pointsize=10,antialias = "cleartype")
# 	print(newMousePlot)
# 	makeFootnote()
# dev.off()

# theme(axis.text.x = element_text(angle = 90, hjust = 1))+
