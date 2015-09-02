# biafra ahanonu
# 2013.02.08
# some io functions for saving plots

pngSave <- function(plotData,file,width=2500,height=2500,title="",rotX=FALSE,footnote="") {
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
pngSaveNormal <- function(plotData,file,width=2500,height=2500,title="",rotX=FALSE,footnote="") {
	png(file,width=width,height=height,res=200,pointsize=10,antialias="cleartype")
		print(plotData)
		makeFootnote(footnoteText=footnote)
	dev.off()
	print(file)
}