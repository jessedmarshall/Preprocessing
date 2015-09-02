#load ggplot
packagesFileList = c("ggplot2")
lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})

# create functions to get the lower and upper bounds of the error bars
stderr <- function(x){sqrt(var(x,na.rm=TRUE)/length(na.omit(x)))}
lowsd <- function(x){return(mean(x)-stderr(x))}
highsd <- function(x){return(mean(x)+stderr(x))}

# create a ggplot
lbp.barplot <- function(data,col.x,col.y,col.fill){
	ggplot(diamonds,aes_string(x=col.x, y=col.y, fill=col.fill))+
	# first layer is barplot with means
	stat_summary(fun.y=mean, geom="bar", position="dodge", colour='white')+
	# second layer overlays the error bars using the functions defined above
	stat_summary(fun.y=mean, fun.ymin=lowsd, fun.ymax=highsd, geom="errorbar", position="dodge",color = 'black', size=.5)
}