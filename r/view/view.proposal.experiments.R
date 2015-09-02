# create functions to get the lower and upper bounds of the error bars
stderr <- function(x){sqrt(var(x,na.rm=TRUE)/length(na.omit(x)))}
lowsd <- function(x){return(mean(x)-stderr(x))}
highsd <- function(x){return(mean(x)+stderr(x))}

# LICK RESPONSIVE REWARD
lick=rep(c(-10:10),2)
firing_rate=c(jitter(c(seq(30,10,length.out=10),seq(10,30,length.out=11)),amount = 3),jitter(c(seq(30,20,length.out=10),seq(20,30,length.out=11)),amount = 3))
state = c(rep('normal',21), rep('chronic pain',21))
neuralFrame = data.frame(lick,firing_rate)
ggplot(neuralFrame, aes(lick,firing_rate, fill=state))+geom_area(alpha=0.3,position="dodge")+
theme(text = element_text(size=20),line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
xlab('lick onset (s)')+
ylab('transients/second')
#=====================
# BEHAVIOR RESPONSE REWARD
preference = c(jitter(rep(0.9,10),20), jitter(rep(0.7,10),20))
state = c(rep('normal',10), rep('chronic pain',10))
behaviorFrame = data.frame(preference,state)

# create a ggplot
dev.new()
ggplot(behaviorFrame,aes(state,preference,fill=state))+
# first layer is barplot with means
stat_summary(fun.y=mean, geom="bar", position=position_dodge(), colour='white')+
# second layer overlays the error bars using the functions defined above
stat_summary(fun.y=mean, fun.ymin=lowsd, fun.ymax=highsd, geom="errorbar", position=position_dodge(.9),color = 'black', size=.5, width=0.2)+
theme(text = element_text(size=30),line = element_blank(), panel.background = element_rect(fill = "white", colour = NA),axis.text.x=element_blank())

#=============================================================
# BEHAVIOR RESPONSE NOXIOUS
withdrawal_threshold = c(jitter(rep(2,10),20), jitter(rep(0.3,10),20),jitter(rep(0.1,10),20))
state = c(rep('normal',10), rep('chronic 1d',10),rep('chronic 14d',10))
behaviorFrame = data.frame(withdrawal_threshold,state)

# create a ggplot
dev.new()
ggplot(behaviorFrame,aes(state,withdrawal_threshold,fill=state))+
# first layer is barplot with means
stat_summary(fun.y=mean, geom="bar", position=position_dodge(), colour='white')+
# second layer overlays the error bars using the functions defined above
stat_summary(fun.y=mean, fun.ymin=lowsd, fun.ymax=highsd, geom="errorbar", position=position_dodge(.9),color = 'black', size=.5, width=0.2)+
theme(text = element_text(size=25),line = element_blank(), panel.background = element_rect(fill = "white", colour = NA),axis.text.x=element_blank())+
ylab('withdrawal threshold (g)')

# LICK RESPONSIVE NOXIOUS
stimuli=rep(c(-10:10),2)
firing_rate=c(jitter(c(seq(10,20,length.out=10),seq(20,10,length.out=11)),amount = 3),jitter(c(seq(10,30,length.out=10),seq(30,10,length.out=11)),amount = 3))
state = c(rep('normal',21), rep('chronic pain',21))
neuralFrame = data.frame(stimuli,firing_rate,state)
dev.new()
ggplot(neuralFrame, aes(stimuli,firing_rate, fill=state))+geom_area(alpha=0.3,position="dodge")+
theme(text = element_text(size=20),line = element_blank(), panel.background = element_rect(fill = "white", colour = NA))+
xlab('stimuli onset (s)')+
ylab('transients/second')