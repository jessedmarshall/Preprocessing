# general packages to load
# biafra ahanonu
# stated 2014.03.19

packagesFileList = c("reshape2", "ggplot2", "parallel", "stringr","lattice","grid","gridExtra")
lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})