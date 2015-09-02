# biafra ahanonu
# updated: 2013.10.16 [21:38:32]
# scripts to analyze hotplate behavior

source('model/model.tracking.pav.R')
v = getTrackingData('E:/biafra/data/behavior/pain/hcplate/p111/2103_10_16_p111_m728_hcplate2_trial1.tracking.csv')

temp = read.table("E:/biafra/data/behavior/pain/hcplate/p111/2013_10_16_p111_m728_hcplate1_trial1.txt", sep=",", header=T, skip=11)
temp$Slice = c(1:nrow(temp))
temp = temp[c(1:which(temp$Time..==520)),]

v$temp = approx(x=temp$T..Plate.1, n=nrow(v))$y

ggplot(v[v$velocity<20,], aes(temp, velocity, color=temp))+geom_point(size=1)+
scale_color_continuous(low="gray", high="red")+geom_vline(xintercept=v$temp[min(which(v$temp==50))])+
ggtitle("2013.10.16, p111, m728 for temperature vs. hotplate")

ggplot(v[v$velocity<20,], aes(x=temp, y=velocity, z=temp))+
stat_density2d(geom="tile", aes(fill = ..density..), contour = FALSE)+
scale_fill_continuous(low="black", high="red")+
theme(line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))