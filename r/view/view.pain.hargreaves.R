# biafra ahanonu
# 2014.02.01
# assess the change in sensitivity during pre/post surgery, chronic and other.

# load dependencies
srcFileList = c('view/view.barplot.R', 'helper/helper.footnote.R', 'helper/helper.ggplot_themes.R','helper/helper.packages.R')
lapply(srcFileList,FUN=function(file){source(file)})

main <-function(...){
	dataPath = 'D:/b/Dropbox/schnitzer/data/assays/pain/hargreaves/database.hargreaves.csv'
	tMelt = hargreavePlots(dataPath)
	return(tMelt)
}
hargreavePlots<-function(dataPath,...){
	t = read.table(dataPath,sep=",",header=T);
	t = t[t$protocol==172,]
	tMelt = melt(t,id.vars = c("date","surgeryTime","surgeryType","protocol","id","id2"))
	# print(tMelt)
	tMelt$foot = str_extract(tMelt$variable, "(left|right)")
	tMelt$trial = as.numeric(str_extract(tMelt$variable,"[[:digit:]]+"))
	tMeltSummary = melt(with(tMelt, tapply(value, list(date,surgeryTime,surgeryType,protocol,id,foot), FUN=function(x){y=mean(as.numeric(x), na.rm = "TRUE")})))
	# print(tMeltSummary)
	names(tMeltSummary) = c("date","surgeryTime","surgeryType","protocol","id","foot","value")
	tMeltSummary = tMeltSummary[!is.na(tMeltSummary $value),]
	tMeltSummary$surgery = tMeltSummary$surgeryTime>0
	tMeltSummary$id = as.character(tMeltSummary$id)

	newplots = list()

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(tMeltSummary,aes(surgery,value,fill=surgery))+
	geom_boxplot(aes(group=surgery),alpha=0.3)+
	stat_summary(aes(group=id),fun.y=mean, geom="point")+
	stat_summary(aes(group=id),fun.y=mean, geom="line")+
	ggThemeBlank()+ggFillColor()+
	ylab('withdrawal latency (s)')+
	facet_grid(foot~surgeryType)

	newplots[[LETTERS[length(newplots)+1]]] = ggplotErrorBarplot(tMeltSummary,'surgery','value',1,color='surgeryType',addPoints=FALSE,addFacet="foot",ylabel='withdrawal latency (s)')
	newplots[[LETTERS[length(newplots)]]] = newplots[[LETTERS[length(newplots)]]]+ggThemeBlank()+ggFillColor()

	tMeltSummary$allVar = paste(tMeltSummary$foot,tMeltSummary$surgeryType,tMeltSummary$surgery,sep="_")
	zzz = with(tMeltSummary, pairwise.wilcox.test(value,allVar, p.adjust.method="bonferroni", paired=FALSE, pool.sd=FALSE))
	# -log10(zzz[['p.value']])
	newplots[[LETTERS[length(newplots)+1]]] = levelplot(10/zzz[['p.value']],
		main = 't-test for hargreaves | values are 10/p-value, so p<0.05 is p>200',
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

	return(tMeltSummary)
}
tMelt = main()
fit = aov(value ~ foot*surgery*surgeryType + Error(id/(foot*surgery*surgeryType)), data=tMelt[!is.na(tMelt$surgery),]);summary(fit)
fit = aov(value ~ foot*surgery*surgeryType, data=tMelt[!is.na(tMelt$surgery),]);summary(fit)
