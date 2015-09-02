# biafra ahanonu
# 2014.02.01
# assess the change in sensitivity during pre/post surgery, chronic and other.

# load dependencies
srcFileList = c('view/view.barplot.R', 'helper/helper.footnote.R', 'helper/helper.ggplot_themes.R','helper/helper.packages.R')
lapply(srcFileList,FUN=function(file){source(file)})

main <-function(...){
	dataPath = 'D:/b/Dropbox/schnitzer/data/assays/pain/von_frey/database.vonFrey.csv'
	tableForTtest = implantPlots(dataPath)
	return(tableForTtest)
}

implantPlots <-function(dataPath,...){
	# read
	t = read.table(dataPath,sep=",",header=T);
	# 160 172 188
	protocol = 188
	t = t[t$protocol==protocol,]
	if(protocol %in% c(160)){
		t = t[t$surgeryType=="implant",]
	}
	# melt the
	tMelt = melt(t,measure.vars = c("right_foot", "left_foot"))
	tMelt$id = as.character(tMelt$id)

	tMelt$surgeryTimeChar = tMelt$surgeryTime
	# make time bar plot look cleaner
	# addNameDates = 1
	if(protocol %in% c(188)){
		tMelt$surgeryTimeChar[tMelt$surgeryTime<=8] = "1_early"
		tMelt$surgeryTimeChar[tMelt$surgeryTime>8&tMelt$surgeryTime<=19] = "2_mid"
		tMelt$surgeryTimeChar[tMelt$surgeryTime>19] = "3_late"
	}
	tMelt$surgeryTimeChar[tMelt$surgeryTime<0] = "0_pre"
	tMelt$surgeryTimeChar = as.character(tMelt$surgeryTimeChar)

	#ggplotErrorBarplot(t,'surgery','Lscore','surgery',addPoints=TRUE)
	#ggplotErrorBarplot(t,'surgery','Rscore','surgery',addPoints=TRUE)

	newplots = list()

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(tMelt[!is.na(tMelt$surgery),],aes(surgery,value,group=id,fill=surgeryType))+
	geom_boxplot(aes(group=surgery),alpha=0.3,outlier.shape = NA)+
	stat_summary(fun.y=mean, geom="point")+
	stat_summary(fun.y=mean, geom="line")+
	ggThemeBlank()+ggFillColor()+
	ylab('50% threshold (g)')+
	facet_grid(variable~surgeryType)

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(tMelt[!is.na(tMelt$surgery),],aes(surgery,value,group=id,fill=surgery))+
	geom_boxplot(aes(group=surgery),alpha=0.3,outlier.shape = NA)+
	stat_summary(fun.y=mean, geom="point")+
	stat_summary(fun.y=mean, geom="line")+
	ggThemeBlank()+ggFillColor()+
	ylab('50% threshold (g)')+
	facet_grid(variable~surgeryType)

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(tMelt[!is.na(tMelt$surgery),],aes(surgeryTimeChar,value,group=id,fill=surgery))+
	geom_boxplot(aes(group=surgeryTimeChar),alpha=0.3,outlier.shape = NA)+
	stat_summary(fun.y=mean, geom="point")+
	stat_summary(fun.y=mean, geom="line")+
	ggThemeBlank()+ggFillColor()+
	ylab('50% threshold (g)')+
	xlab('surgery time (days)')+
	facet_grid(variable~surgeryType)

	# create functions to get the lower and upper bounds of the error bars
	stderr <- function(x){sqrt(var(x,na.rm=TRUE)/length(na.omit(x)))}
	lowsd <- function(x){return(mean(x)-stderr(x))}
	highsd <- function(x){return(mean(x)+stderr(x))}

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(tMelt[!is.na(tMelt$surgeryTime),],aes(surgeryTime,value,linetype=surgeryType))+
	# geom_boxplot(aes(group=surgeryTime),alpha=0.3)+
	stat_summary(aes(group=id,color=id),fun.y=mean, geom="point")+
	stat_summary(aes(group=id,color=id),fun.y=mean, geom="line")+
	# stat_summary(fun.y=mean, fun.ymin=lowsd, fun.ymax=highsd, geom="errorbar", position=position_dodge(.9),color = 'black', size=1.5, width=0.2)+
	# geom_smooth(color="grey",fill="grey")+
	# stat_summary(fun.y=mean, geom="line", color='black')+
	ggThemeBlank()+ggFillColor()+
	geom_vline(xintercept = 0, color="red")+
	ylab('50% threshold (g)')+
	facet_grid(~variable)

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(tMelt[!is.na(tMelt$surgeryTime),],aes(id,value, group=id, fill=id, color=id, shape=surgeryType))+
	# geom_boxplot(position="dodge")+
	stat_summary(aes(group=id),fun.y=mean, geom="point", color="red", size=2, pch=15)+
	geom_point()+
	ggThemeBlank()+ggFillColor()+
	facet_grid(variable~surgery)

	colorSwitch = 1
	print(tMelt[!is.na(tMelt$surgery),])
	excludeRows = (!is.na(tMelt$surgery)&!is.na(tMelt$value))
	if(colorSwitch==1){
		newplots[[LETTERS[length(newplots)+1]]] = ggplotErrorBarplot(tMelt[excludeRows,],'surgery','value',1,color='surgeryType',addPoints=FALSE,addFacet="variable",ylabel='50% threshold (g)')
	}else{
		newplots[[LETTERS[length(newplots)+1]]] = ggplotErrorBarplot(tMelt[!is.na(tMelt$surgery),],'surgery','value',1,	addPoints=FALSE,addFacet="variable",ylabel='50% threshold (g)')
	}
	newplots[[LETTERS[length(newplots)]]] = newplots[[LETTERS[length(newplots)]]]+ggThemeBlank()+ggFillColor()

	if(colorSwitch==1){
		newplots[[LETTERS[length(newplots)+1]]] = ggplotErrorBarplot(tMelt[!is.na(tMelt$surgery),],'surgeryTimeChar','value',1,color='surgeryType',addPoints=FALSE,addFacet="variable",ylabel='50% threshold (g)')
	}else{
		newplots[[LETTERS[length(newplots)+1]]] = ggplotErrorBarplot(tMelt[!is.na(tMelt$surgery),],'surgeryTimeChar','value',1,addPoints=FALSE,addFacet="variable",ylabel='50% threshold (g)')
	}
	newplots[[LETTERS[length(newplots)]]] = newplots[[LETTERS[length(newplots)]]]+ggThemeBlank()+ggFillColor()

	excludeRows = !is.na(tMelt$surgeryType)&excludeRows
	tMelt$allVar = paste(tMelt$variable,tMelt$surgeryType,tMelt$surgery,sep="_")
	zzz = with(tMelt[excludeRows,], pairwise.wilcox.test(value,allVar, p.adjust.method="none", paired=FALSE, pool.sd=FALSE))
	# 10^(-log10(zzz[['p.value']]))
	newplots[[LETTERS[length(newplots)+1]]] = levelplot(10/zzz[['p.value']],
		main = 't-test for von frey | values are 10/p-value, so p<0.05 is p>200',
		xlab='',ylab='',
		col.regions = colorRampPalette(c("white","red")),
		scales=list(x=list(rot=90)),
		panel=function(...) {
		arg <- list(...)
		panel.levelplot(...)
		panel.text(arg$x, arg$y, ifelse(is.na(round(arg$z,0)), '', round(arg$z,0)))
				})

	# name new plots
	lapply(newplots, FUN=function(x){dev.new(width=16,height=9);print(x);makeFootnote()})

	tableForTtest = t[!is.na(t$surgery),]
	for (colName in c("left_foot","right_foot")) {
		# should be paired
		tTests = pairwise.wilcox.test(tableForTtest[[colName]],tableForTtest$surgery, p.adjust.method="none", paired=FALSE, pool.sd=FALSE)
		print(tTests)
	}
	return(tMelt)
}

tMelt = main()

fit = aov(value ~ variable*surgery + Error(id/(variable*surgery)), data=tMelt[!is.na(tMelt$surgery),]);summary(fit)
# boxplot(latency ~ type*date,data=rotorodSum[which(rotorodSum$protocol=="p30"),])
# interaction.plot(rotorodSumTmp$type,rotorodSumTmp$date,rotorodSumTmp$latency)