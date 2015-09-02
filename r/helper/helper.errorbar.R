# create functions to get the lower and upper bounds of the error bars
stderr <- function(x){sqrt(var(x,na.rm=TRUE)/length(na.omit(x)))}
lowsd <- function(x){return(mean(x)-stderr(x))}
highsd <- function(x){return(mean(x)+stderr(x))}

ggplotErrorBars <-function(inputData, xVar, yVar,fillVar,...){
	# create a ggplot
	ggplot(trialLicks,aes_string(xVar,yVar,fill=fillVar))+
	# first layer is barplot with means
	stat_summary(fun.y=mean, geom="bar", position=position_dodge(), colour='white')+
	# second layer overlays the error bars using the functions defined above
	stat_summary(fun.y=mean, fun.ymin=lowsd, fun.ymax=highsd, geom="errorbar", position=position_dodge(.9),color = 'black', size=.5, width=0.2)+
	facet_wrap(~mouse)+
	ggtitle('Per trial licks, 15 seconds post reward')
	makeFootnote("number of licks for 15 seconds after first rewarded lick")
}