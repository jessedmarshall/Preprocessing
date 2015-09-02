require(reshape2)
require(ggplot2)

m561 = read.table("E:/biafra/data/behavior/t_maze/p109/traces/v3.traces.2013_09_26_p109_m561_tmaze1.csv", sep=",")
m561$cell = c(1:nrow(m561))
m561 = melt(m561,'cell')
names(m561) = c('cellID','frame','spikes')
m561$frame = as.numeric(gsub("V","",m561$frame))
#ggplot(m561, aes(frame, spikes))+stat_summary(fun.y=sum, geom="bar")

PSTH = tapply(m561$spikes,INDEX=as.factor(m561$frame), sum)
time = sort(unique(m561$frame))
traceSum = data.frame(time, PSTH)
ggplot(traceSum, aes(time, PSTH))+geom_line()

file = 'E:/biafra/data/behavior/t_maze/p109/tracking/2013_09_26_p109_m561_tmaze1.tracking.txt'
v = read.table(file, header=T)
idx = which(ave(v$Area, v$Slice, FUN=rank)==1)
v2 = v[idx,]

allData = merge(v2, traceSum, sort=FALSE, by.x = "Slice", by.y = "time")
ggplot(allData, aes(XM, -YM, color=PSTH>=2))+geom_path()