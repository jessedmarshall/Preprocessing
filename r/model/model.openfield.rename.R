# biafra ahanonu
# updated: 2013.09.29 [14:47:59]
# rename open field trials to standardized output

require(stringr)
trialInfo = read.table("C:/b/Dropbox/schnitzer/data/databases/database.mice.open_field.csv", sep=",", header=T, stringsAsFactors=FALSE)
mouseInfo = read.table("C:/b/Dropbox/schnitzer/data/databases/database.mice.csv", sep=",", header=T, stringsAsFactors=FALSE)
trialFiles = data.frame()
trialFiles$file = list.files("E:/biafra/data/behavior/open_field", full.names=TRUE, recursive=TRUE, pattern="*.txt")
trialFiles$experiment = str_extract(trialFiles$file, "p\\d+")
trialFiles$trial = str_extract(str_extract(trialFiles$file, "(trial_\\d+|Trial\\s+\\d+)"), "[[:digit:]]+")
trialFiles$subject = str_extract(str_extract(trialFiles$file, "(subject_\\d+|Subject\\s+\\d+)"), "[[:digit:]]+")
trialFiles$fileDates = str_extract(trialFiles$file, "\\d+_\\d+_\\d+")
t = merge(trialFiles, trialInfo, by=c("experiment", "subject", "trial"))
t$date = gsub("\\.","_",t$date)
newDir = "E:/biafra/data/behavior/open_field/all/"
t$newFile = paste(newDir,t$date,"_",t$experiment,"_","m",t$mouse,"_","oft",t$trial, ".csv", sep="")
by(t, t$file, FUN=function(t){file.copy(t$file, t$newFile)})