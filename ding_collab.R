# load dependencies
source('controller.pav.liquid.R')
srcFileList = c('view/view.barplot.R', 'helper/helper.footnote.R', 'helper/helper.ggplot_themes.R','helper/helper.packages.R')
lapply(srcFileList,FUN=function(file){source(file)})

mouse = as.character(c(2975,866,867,865,2972,2973))
group = c("KO","KO","KO","CTRL","CTRL","CTRL")
addTable = data.frame(mouse,group)
summaryTable = merge(animalData,addTable)
summaryTable$pavType = str_extract(summaryTable$pav, "[[:alpha:]]+")
summaryTable$pavNum = str_extract(summaryTable$pav, "[[:digit:]]+")
pavIdx = grep("(MAG|PAV(|Q)|(Q|)EXT|REN|SCH|SUL|TROP|D|HAL)", summaryTable$pav)

pav = "pav"
pavNum = "pavNum"
variableList = c("lickMetric","lickRate")
titleList = c("CS - ITI","licks/second")
newplots = list()
for (i in c(1,2)){
	newplots[[LETTERS[length(newplots)+1]]] = ggplot(summaryTable,aes_string(x=pavNum,y=variableList[i]))+
	stat_summary(aes(group=group,colour=group), fun.y=mean, geom="line", alpha=0.8)+
	stat_summary(aes(group=mouse,colour=group), fun.y=mean, geom="line", alpha=0.3)+
	stat_summary(aes(group=group,colour=group), fun.y=mean, geom="point", alpha=0.8)+
	ylab(titleList[i])+
	xlab('')+
	ggThemeBlank()+ggFillColor()+
	facet_grid(.~pavType,scale="free",space = "free")
}
# dev.new()
png(paste(analysis_dir,"pav_condition_licks_ding.png",sep=""),width=3200,height=1800,res=200,pointsize=10,antialias="cleartype")
newPlot = do.call("grid.arrange", c(newplots, ncol=2))
dev.off()

# summaryTable$lickDiff = c(0,diff(summaryTable$time))
# summaryTable$lickDiff[summaryTable$lickDiff<0] = 0
# filterIdx = grep("(PAV)", summaryTable$type)
# ggplot(summaryTable[filterIdx,],aes(lickDiff,color=group,fill=group))+
# geom_density(aes(y=..count..),alpha=0.5)+scale_x_log10()+scale_y_log10()+facet_wrap(~type)+ggThemeBlank()+
# ylim(0,1e1,1e2,1e3,1e4)

# hist(diff(rawMouseData[filterIdx,]$time))
# acf(rawMouseData[filterIdx,]$time)