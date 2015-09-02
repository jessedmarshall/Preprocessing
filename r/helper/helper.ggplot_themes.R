# themes to add to ggplot
# biafra ahanonu
# stated 2014.03.19

# install.packages("extrafont");library(extrafont)
# font_import("Futura Book")

srcFileList = c('helper/helper.packages.R')
lapply(srcFileList,FUN=function(file){source(file)})

ggThemeBlank <- function(stripTextSize=20,stripYAngle = 270, axisTextSize = 25, defaultTextSize = 20, axisXAngle = 0, gridMajorColor = "#F0F0F0", gridMinorColor = "#F0F0F0", backgroundColor="white", borderColor = "transparent",xAxisAdj = 1){
	# font_import(pattern="[F/f]utura")
	# theme(text=element_text(size=16, family="Comic Sans MS"))

	theme(panel.background = element_rect(fill = backgroundColor, colour = NA),
		text = element_text(size=defaultTextSize),
		legend.text=element_text(size=defaultTextSize),
		legend.title=element_text(size=defaultTextSize),
		legend.key = element_blank(),
		legend.key.height=unit(1.5,"line"),
		legend.key.width=unit(1.5,"line"),
		strip.background = element_rect(fill = '#005FAD'),
		strip.text.x = element_text(colour = 'white', angle = 0, size = stripTextSize, hjust = 0.5, vjust = 0.5, face = 'bold'),
		strip.text.y = element_text(colour = 'white', angle = stripYAngle, size = stripTextSize, hjust = 0.5, vjust = 0.5, face = 'bold'),
		axis.text.x = element_text(colour="black", size = axisTextSize, angle = axisXAngle, vjust = xAxisAdj,hjust = xAxisAdj),
		axis.text.y = element_text(colour="black", size = axisTextSize),
		axis.title.y=element_text(vjust=5, size = axisTextSize),
		axis.title.x=element_text(vjust=0.2, size = axisTextSize),
		plot.title=element_text(vjust=1.4),
		axis.ticks.x = element_blank(),
		axis.ticks.y = element_blank(),
		panel.grid.major = element_line(color = gridMajorColor),
		panel.grid.minor = element_line(color = gridMinorColor),
		panel.border = element_rect(fill = NA,colour = borderColor),
		panel.margin=unit(1 , "lines"))
}
ggFillColor <- function(palette="Set1",colourCount = 15,...){
	# Set1 or Paired
	# colourCount = 15
	getPalette = colorRampPalette(brewer.pal(colourCount, palette))
	# scale_fill_brewer(palette=palette)
	return(scale_fill_manual(values = getPalette(colourCount)))
}
ggFillColorContinuous <- function(midpointH=0,lowColor="blue",midColor="white",highColor="red",...){
	# return(scale_colour_gradient2(low=lowColor, mid=midColor, high=highColor))
	return(scale_fill_gradient2(low=lowColor, mid=midColor, high=highColor,midpoint=midpointH))
}
ggCustomColor <- function(palette="Set1",colourCount = 15,...){

	getPalette = colorRampPalette(brewer.pal(colourCount, palette))
	# scale_colour_brewer(palette=palette)
	return(scale_colour_manual(values = getPalette(colourCount)))
}
ggCustomColorContinuous <- function(midpointH=0,lowColor="blue",midColor="white",highColor="red",...){
	# return(scale_colour_gradient2(low=lowColor, mid=midColor, high=highColor))
	# return(scale_colour_gradient(low=lowColor, high=highColor))
	return(scale_colour_gradientn(colours = brewer.pal(7, "YlGnBu")))

	# return(scale_colour_gradient2(low=lowColor, mid=midColor, high=highColor,midpoint=midpointH))
}
ggThemeBlankLines <- function(...) theme(line = element_blank(),panel.background = element_rect(fill = "white", colour = NA), text = element_text(size=10))