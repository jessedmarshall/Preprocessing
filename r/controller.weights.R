# biafra ahanonu
# updated: 2013.06.18
# open field analysis
# ________________________________________________________
# Set the local directory
setwd("C:/Users/B/Dropbox/biafra/stanford/lab/schnitzer/scripts/R/")
# ________________________________________________________
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
source("helper.stats.R")
# Function to get raw data from files
# source("model.parse.training.raw.R")
# ________________________________________________________
#SETTINGS
#Data and analysis directories
data_dir = "../../data/"
data_sub_dir="open_field/analysis/"
analysis_dir = "../../analysis/biafra/weights/"
# Set directory information, create appropriate directories
c(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir=data_dir,dataSubDir=data_sub_dir,analysisDir=analysis_dir)
# ________________________________________________________
hdMouse = read.table(paste(data_dir,"mice/database.mice.feeding.weights.cohort1.csv",sep=""),sep=",",header=T)
hdMouse$date = as.Date(paste(substr(hdMouse$date,1,4),substr(hdMouse$date,5,6),substr(hdMouse$date,7,8),sep="-"),format="%Y-%m-%d")

# look at body weight
newplot = ggplot(hdMouse,aes(date,BW,color=type))+geom_smooth()+geom_point()
# save plot
plotFile = paste(analysis_dir,current_date,"_hd_weights.png",sep="")
plotTitle = "huntington: mouse weights"
plotFootnote = "These are measured during training"
pngSave(plotData=newplot,file=plotFile,title=plotTitle,footnote=plotFootnote)

# look at food given
newplot = ggplot(hdMouse,aes(date,FW,color=type,group=type))+geom_point()+geom_smooth()
plotFile = paste(analysis_dir,current_date,"_hd_food_given.png",sep="")
plotTitle = "huntington: food given"
plotFootnote = "These are measured during training"
pngSave(plotData=newplot,file=plotFile,title=plotTitle,footnote=plotFootnote)
