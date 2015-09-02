# biafra ahanonu
# 2013.02.18
# plot footnotes on a graphic

makeFootnote <- function(footnoteText="",size= .7, color= grey(.5)){
	require(grid)
	pushViewport(viewport())
	if(footnoteText==""){
		footnoteText = paste(format(Sys.time(),"%d %b %Y"),format(Sys.time(), format="%H:%M:%S"),sep=" | ")
	}else{
		footnoteText = paste(footnoteText,format(Sys.time(),"%d %b %Y"),format(Sys.time(), format="%H:%M:%S"),sep=" | ")
	}
	grid.text(label= footnoteText ,
		x = unit(1,"npc") - unit(2, "mm"),
		y= unit(2, "mm"),
		just=c("right", "bottom"),
		gp=gpar(cex= size, col=color))
	popViewport()
}