# biafra ahanonu
# updated: 2013.06.18
# for error plotting in ggplot2
# ________________________________________________________
# create functions to get the lower and upper bounds of the error bars
stderr <- function(x){sqrt(var(x,na.rm=TRUE)/length(na.omit(x)))}
lowsd <- function(x){return(mean(x)-stderr(x))}
highsd <- function(x){return(mean(x)+stderr(x))}