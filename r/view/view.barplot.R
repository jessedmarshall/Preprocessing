# biafra ahanonu
# updated: 2013.10.03 [13:36:36]
# implements barplot via ggplot2

#load ggplot
require(ggplot2)
require(plyr)
ggplotErrorBarplot <-function(data,x,y,fill,color=1,addPoints=FALSE,addFacet=FALSE,addFacet2=FALSE,ylabel=FALSE,...){
	result = tryCatch({
		# makes a barplot with errorbars using ggplot, variable inputs are strings
		# biafra ahanonu, updated: 2013.12.28

		if(fill==1){
			types = "white"
		}else{
			data$fill = data[,names(data) %in% c(fill)]
			data  <- ddply(data,c(x,fill),
			            transform,
			            types = paste(as.character(fill)," - (n=",length(fill),")",sep = ""))
			types = "types"
		}

		# create functions to get the lower and upper bounds of the error bars
		stderr <- function(x){sqrt(var(x,na.rm=TRUE)/length(na.omit(x)))}
		lowsd <- function(x){
			val=mean(x)-stderr(x);
			# if(val<0){
			# 	val=median(x)-median(x)*0.01;
			# }
			return(val)
		}
		highsd <- function(x){return(mean(x)+stderr(x))}

		# create a ggplot
		if(fill==1){
			if(color==1){
				thisPlot = ggplot(data,aes_string(x=x,y=y),color='white')
			}else{
				thisPlot = ggplot(data,aes_string(x=x,y=y,fill=color),color='white')
			}
		}else{
			if(color==1){
				thisPlot = ggplot(data,aes_string(x=x,y=y,fill=types,color=color,group=fill))
			}else{
				thisPlot = ggplot(data,aes_string(x=x,y=y,fill=types,group=fill))
			}
		}
		# first layer is barplot with means
		thisPlot = thisPlot+stat_summary(fun.y=mean, geom="bar", position=position_dodge())+
		# aes_string(color=color)
		# second layer overlays the error bars using the functions defined above
		stat_summary(fun.y=mean, fun.ymin=lowsd, fun.ymax=highsd, geom="errorbar", position=position_dodge(.9),color = 'black', size=1, width=0.2)+
		# stat_bin(geom="text", aes_string(x=x,y = 0.5, label="..count..", vjust=2),position=position_dodge())+
		theme(line = element_blank(),panel.background = element_rect(fill = "white", colour = NA), text = element_text(size=10))
		# stat_bin(data=data, aes_string(x), geom="text", color="white", inherit.aes=FALSE)
		if(addPoints==TRUE){
			thisPlot = thisPlot+geom_point()
		}
		if(addFacet!=FALSE){
			if(addFacet2!=FALSE){
				thisPlot = thisPlot+facet_grid(paste(addFacet2,"~",addFacet,sep=""))
			}else{
				thisPlot = thisPlot+facet_grid(paste("~",addFacet,sep=""))
			}
			
		}
		if(ylabel!=FALSE){
			thisPlot = thisPlot + ylab(ylabel)
		}
		# print(thisPlot)
		return(thisPlot)
	}, error = function(err) {
		print(err)
		print(traceback())
		return(FALSE)
	}, finally = {
		return(thisPlot)
		# print(Sys.time()-startTime); flush.console();
		# stop the cluster
		# stopCluster(cl)
		# return(data.frame())
	})
}