# biafra ahanonu
# 2013.02.08
# mouse training analysis
# setwd("C:/Users/B/Dropbox/biafra/Stanford/Lab/schnitzer/scripts/R/")
# _________________________________________________
# Re-run parsing algorithm
# source("model.parse.training.data.R")
# _________________________________________________
# Load libraries and dependencies
# For plotting
require(ggplot2)
require(gridExtra)
require(reshape2)
# Add time-stamped footnote to graphs
source("view/view.footnote.R")
# Function to get directory info and create folders
source("helper/helper.getDir.R")
# barplot for ggplot
source('view/view.barplot.R')
# Set directory information, create appropriate directories
c(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir="../../data/",dataSubDir="assays/roto_rod/",analysisDir="../../analysis/temp/biafra/")
# _________________________________________________
# # Contains main roto-rod data
# inputFile = "database.mice.rotorod.p146.csv"
# mouse = read.table(paste(data_main_dir,inputFile,sep=""),header=T,sep=",")
# # Hash table to match column names to date/trial
# hashFile = "database.mice.rotorod.hash.csv"
# mouseHash = read.table(paste(data_main_dir,hashFile,sep=""),header=T,sep=",")


require(stringr)
rotorod = read.table('../../data/assays/roto_rod/database.mice.rotorod.p146.csv', sep=",", header=T)
rotorod = melt(rotorod, id=c("mouse","id","type","sex","bw"), variable="date", value.name="latency")
rotorod$trial = as.numeric(gsub("x","",str_extract(rotorod$date, "x\\d+")))
rotorod$date = as.Date(gsub("X","",str_extract(rotorod$date, "X\\d+")), format="%Y%m%d")
rotorod$retry = rotorod$trial>0

rotorodHash = read.table('../../data/assays/roto_rod/database.mice.rotorod.hash.csv', sep=",", header=T)
rotorodHash$date = as.Date(rotorodHash$date, format="%m/%d/%Y")
protocolId = "p146"

# now integrate the number of rotorod training
rotorod = merge(rotorod, rotorodHash, by="date")
rotorodRetries = rotorod[which(rotorod$trial==0),]
rotorodRetries$retries = rotorodRetries$latency
rotorodRetries=rotorodRetries[,(names(rotorodRetries) %in% c("date","mouse","id","retries"))]
rotorod = merge(rotorod, rotorodRetries, by=c("date","mouse","id"))

g = melt(with(rotorod, tapply(latency, list(date,mouse), FUN=function(x){mean(as.numeric(x), na.rm = "TRUE")})))
names(g) = c("date","mouse","latency")
rotorodSum = merge(unique(rotorod[,(names(rotorod) %in% c("date","mouse","id","type","sex","bw","retries","protocol"))]), g, by=c("date","mouse"))

# summary(aov(latency ~ type + Error(as.character(date)/type), data=rotorodSum[which(rotorodSum$protocol=="p13"),]))
rotorodSumTmp = rotorodSum[which(rotorodSum$protocol==protocolId),]
summary(aov(latency ~ type, data=rotorodSumTmp)

# fit = aov(latency ~ type + Error(date/type), data=rotorodSum[which(rotorodSum$protocol=="p146"),])
fit = aov(latency ~ type*date + Error(mouse), data=rotorodSumTmp)
summary(fit)
with(rotorodSumTmp, pairwise.t.test(latency,date, p.adjust.method="bonf", paired=FALSE, pool.sd=FALSE))

fit = aov(latency ~ type*date, data=rotorodSumTmp)
TukeyHSD(fit, "date")

boxplot(latency ~ type*date,data=rotorodSum[which(rotorodSum$protocol==protocolId),])
interaction.plot(rotorodSumTmp$type,rotorodSumTmp$date,rotorodSumTmp$latency)
plot(fit)

rotorodPlot=
ggplot(rotorod[rotorod$trial!=0,],aes(x=trial,y=latency,group=type,colour=type))+
stat_summary(fun.data = "mean_cl_boot",geom = "errorbar", width=0.1,size=0.5)+
stat_summary(fun.data = "mean_cl_boot",geom = "point", size=3, shape=15)+
ylab("latency to fall (s)")+
theme(line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
# scale_y_log10(breaks=c(10,20,30,50))+
ggtitle("Q175 roto-rod latency")+
facet_wrap(~protocol)

# dev.new()
# create functions to get the lower and upper bounds of the error bars
stderr <- function(x){sqrt(var(x,na.rm=TRUE)/length(na.omit(x)))}
lowsd <- function(x){return(median(x)-stderr(x))}
highsd <- function(x){return(median(x)+stderr(x))}

# create a ggplot
rotorodPlot2 = ggplot(rotorod[rotorod$trial!=0,],aes(trial,as.numeric(latency),fill=type,group=type))+
# first layer is barplot with means
stat_summary(fun.y=median, geom="bar", position=position_dodge(), colour='white')+
# second layer overlays the error bars using the functions defined above
stat_summary(fun.y=median, fun.ymin=lowsd, fun.ymax=highsd, geom="errorbar", position=position_dodge(.9),color = 'black', size=.5, width=0.2)+
theme(line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))


rotorodPlot3 = ggplot(rotorod[rotorod$trial!=0,],aes(x=1,y=as.numeric(latency),group=type,fill=type))+
geom_boxplot(notch=FALSE)+
theme(line = element_blank(), axis.text.x=element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
ylab("latency to fall (s)")+
xlab("")+
facet_wrap(~identi)

print(rotorodPlot3)

# create a ggplot
rotorodPlot4 = ggplot(rotorodSum,aes(' ',as.numeric(bw),fill=type,group=type))+
# first layer is barplot with means
stat_summary(fun.y=median, geom="bar", position=position_dodge(), colour='white')+
# second layer overlays the error bars using the functions defined above
stat_summary(fun.y=median, fun.ymin=lowsd, fun.ymax=highsd, geom="errorbar", position=position_dodge(.9),color = 'black', size=.5, width=0.2)+
theme(line = element_blank(), axis.text.x=element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
ylab("body weight (g)")+
xlab("")

print(rotorodPlot4)


rotorodPlot3 = ggplot(rotorodSum[which(rotorodSum$date=="2013-12-17"),],aes(x=1,y=as.numeric(bw),group=type,fill=type))+
geom_boxplot(notch=FALSE)+
theme(line = element_blank(), axis.text.x=element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
ylab("body weight (g)")+
xlab("")

print(rotorodPlot3)

ggplot(rotorodSum[which(rotorodSum$date=="2013-12-17"),],aes(x=type,y=..count..,group=type,fill=type))+geom_histogram(position="dodge")+
theme(line = element_blank(), axis.text.x=element_blank(), panel.background = element_rect(fill = "white", colour = NA))