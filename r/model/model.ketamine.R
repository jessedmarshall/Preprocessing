# biafra ahanonu
# updated: 2013.09.30 [21:48:28]
#


vL = read.table('ResultsL.txt')
vR = read.table('ResultsR.txt')
vL$time = c(1:nrow(vL))
vR$time = c(1:nrow(vR))
vL$FOV_location = "left"
vR$FOV_location = "right"
vL$relative_fluorescence = vL$Mean/max(vL$Mean)
vR$relative_fluorescence = vR$Mean/max(vR$Mean)
vall = rbind(vR, vL)
ggplot(vall, aes(x=time,y=relative_fluorescence, color=FOV_location))+geom_line(alpha=0.5)+geom_vline(xintercept=2400)+ggtitle("m493 on ketamine")