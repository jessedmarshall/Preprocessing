# biafra ahanonu
# 2014.02.01
# assess the change in sensitivity during pre/post surgery, chronic and other.

# load dependencies
srcFileList = c('view/view.barplot.R', 'helper/helper.footnote.R', 'helper/helper.ggplot_themes.R','helper/helper.packages.R')
lapply(srcFileList,FUN=function(file){source(file)})

main <-function(...){
	dataPath = 'D:/b/Dropbox/schnitzer/data/assays/pain/acetone/database.acetone.csv'
	tMelt = hargreavePlots(dataPath)
	return(tMelt)
}
hargreavePlots<-function(dataPath,...){
	t = read.table(dataPath,sep=",",header=T);
	t = t[t$protocol==172,]

	tMelt = melt(t,id.vars = c("date","surgeryTime","surgeryType","protocol","id","id2"))
	tMelt$foot = str_extract(tMelt$variable, "(left|right)")
	tMelt$liquid = str_extract(tMelt$variable, "(water|acetone)")
	tMelt$trial = as.numeric(str_extract(tMelt$variable,"[[:digit:]]+"))
	# summarize the plot
	tMeltSummary = melt(with(tMelt, tapply(value, list(date,surgeryTime,surgeryType,protocol,id,foot,liquid), FUN=function(x){y=mean(as.numeric(x), na.rm = "TRUE")})))
	names(tMeltSummary) = c("date","surgeryTime","surgeryType","protocol","id","foot","liquid","value")
	tMeltSummary = tMeltSummary[!is.na(tMeltSummary $value),]
	tMeltSummary$surgery = tMeltSummary$surgeryTime>0
	tMeltSummary$id = as.character(tMeltSummary$id)

	newplots = list()

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(tMeltSummary,aes(surgery,value,color=id,linetype=surgeryType))+
	geom_boxplot(aes(group=surgery))+
	geom_point(aes(group=id),alpha = 0.6)+
	geom_line(aes(group=id),alpha = 0.6)+
	theme(line = element_blank(),panel.background = element_rect(fill = "white", colour = NA), text = element_text(size=20))+
	facet_grid(liquid~foot,scale="free")

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(tMeltSummary,aes(surgery,value,fill=surgeryType))+
	geom_boxplot(aes(group=interaction(surgeryType, surgery)),alpha=0.3)+
	stat_summary(aes(colour=surgeryType,group=id),fun.y=mean, geom="point")+
	stat_summary(aes(colour=surgeryType,group=id),fun.y=mean, geom="line")+
	ggThemeBlank()+ggFillColor()+
	ylab('withdrawal latency (s)')+
	facet_grid(foot~liquid)

	newplots[[LETTERS[length(newplots)+1]]] = ggplotErrorBarplot(tMeltSummary,'surgery','value',1,color='surgeryType',addPoints=FALSE,addFacet="liquid",addFacet2="foot",ylabel='flick response duration (s)')
	newplots[[LETTERS[length(newplots)]]] = newplots[[LETTERS[length(newplots)]]]+ggThemeBlank()+ggFillColor()

	tMeltSummary$allVar = paste(tMeltSummary$liquid,tMeltSummary$foot,tMeltSummary$surgeryType,tMeltSummary$surgery,sep="_")
	# excludeRows = (tMeltSummary$liquid=="acetone")&(tMeltSummary$foot=="left")
	# print(tMeltSummary[excludeRows,])
	zzz = with(tMeltSummary, pairwise.wilcox.test(value,allVar, p.adjust.method="none", paired=FALSE, pool.sd=FALSE))
	# -log10(zzz[['p.value']])
	newplots[[LETTERS[length(newplots)+1]]] = levelplot(10/zzz[['p.value']],
		main = 't-test for acetone | values are 10/pvalue, so p<0.05 is p>200',
		xlab='',ylab='',
		col.regions = colorRampPalette(c("white","red")),
		scales=list(x=list(rot=90)),
		panel=function(...) {
		arg <- list(...)
		panel.levelplot(...)
		panel.text(arg$x, arg$y, ifelse(is.na(round(arg$z,0)), '', round(arg$z,0)))
				})

	wilcox.test
	# name new plots
	lapply(newplots, FUN=function(x){dev.new(width=16,height=9);print(x);makeFootnote()})

	return(tMeltSummary)
}
tMelt = main()