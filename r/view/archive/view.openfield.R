# biafra ahanonu
# updated: 2013.08.24 [11:44:27]
# plots for open field

g = data.frame(x=NA,y=NA,xsd=NA,ysd=NA)
for(i in c(1:4)){
#print(i)
xdata = mean(as.numeric(as.vector(tail(mouseData[[i]][['X.center']]))))
ydata = mean(as.numeric(as.vector(tail(mouseData[[i]][['Y.center']]))))
xstdv = sd(as.numeric(as.vector(mouseData[[i]][['X.center']])))
ystdv = sd(as.numeric(as.vector(mouseData[[i]][['Y.center']])))
g[i,]=c(xdata,ydata,xstdv,ystdv)
}
dev.new()
dev.set(3)
ggplot(g,aes(x,y,label=rownames(g)))+
geom_point()+
geom_text()+
geom_errorbar(aes(ymin=y-ysd,ymax=y+ysd))+
geom_errorbarh(aes(xmin=x-xsd,xmax=x+xsd))


velocityData = data.frame(subject=NA,velocity=NA,time=NA)
mouseNames = c("wild-type","homozygous","heterozygous","heterozygous")
for(i in c("wild-type","homozygous","heterozygous")){
	#print(i)
	#velocity = abs(as.numeric(as.vector(mouseData[[i]][['Velocity']])))
	#bins = cut(c(1:length(mouseData[[i]][['Velocity']])),breaks=30)
	#this.data = cumsum(na.omit(as.numeric(as.vector(mouseData[[i]]$Distance.moved))))
	this.data = na.omit(as.numeric(as.vector(mouseData[[i]]$Velocity)))
	bins = cut(c(1:length(this.data)),breaks=30)
	counts = as.vector(tapply(X=this.data,INDEX=bins,FUN=function(x){mean(x,na.rm=T)}))
	times = c(1:length(counts))
	subjectData = data.frame(subject=paste(mouseNames[i],i),velocity=counts,time=times)
	velocityData=rbind(velocityData,subjectData)
}
dev.new()
#dev.set(2)
velocityData = velocityData[2:nrow(velocityData),]
mousePlot = ggplot(velocityData,aes(time,velocity))
mousePlot + geom_line(aes(color=subject))
mousePlot = ggplot(velocityData,aes(factor(subject),velocity))+
mousePlot = ggplot(velocityData,aes(velocity))
mousePlot + geom_boxplot(notch = TRUE,aes(fill=factor(subject)))
