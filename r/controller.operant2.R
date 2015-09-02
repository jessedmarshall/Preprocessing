# biafra ahanonu
# updated: 2013.07.29
# read in training data and parse it out

# get input files
srcFileList = c('model/model.medfiles_parser.R','view/view.footnote.R','helper/helper.getDir.R','helper/helper.packages.R','helper/helper.footnote.R','helper/helper.ggplot_themes.R')
lapply(srcFileList,FUN=function(file){source(file)})

getOperantData <-function(inputPath){
	result = tryCatch({
		srcFileList = c('model/model.medfiles_parser.R','helper/helper.packages.R')
		lapply(srcFileList,FUN=function(file){source(file)})
		# get the date
		date = str_extract(inputPath, "(\\d{6}|\\d+_\\d+_\\d+)")
		trueDate=date
		dates=as.Date(trueDate, format="%Y_%m_%d")
		for(i in 1:length(dates)){
			idate = dates[i]
			if(is.na(idate)){
				dates[i]=as.Date(trueDate[i],"%y%m%d")
			}
		}
		date = dates
		# get extra data
		extraData = list()
		extraData$assay = str_extract(inputPath, "(REVTRAIN|TRAIN|REVERSAL|T)\\d+")
		extraData$assayName = str_extract(extraData$assay, "[[:alpha:]]+")
		extraData$assayNum = as.numeric(str_extract(extraData$assay,"[[:digit:]]+"))
		extraData$subject = as.character(gsub("(m|M|f|F|A|B|C)","",str_extract(inputPath, "(m|M|f|F|A|B|C)\\d+")))
		extraData$subjectName = as.character(str_extract(inputPath, "(m|M|f|F|A|B|C)\\d+"))
		extraData$protocol = as.numeric(gsub("p","",str_extract(inputPath, "p\\d+")))
		extraData$file = inputPath
		extraData$trialSet = extraData$assayNum
		extraData$type = extraData$assayName
		extraData$trial = extraData$assay
		extraData$date = date

		# # get operant data from file and annotate
		# rawSubjData = readMedpcFiles(inputPath);
		# # add extra data
		# for (thisName in names(extraData)){
		# 	rawSubjData[thisName] = extraData[thisName]
		# }
		# # add for miniscope analysis
		# framesPerSec = 5
		# rawSubjData$frame = round(as.numeric(rawSubjData$time)*framesPerSec)
		# framesPerSec = 20
		# rawSubjData$frame20hz = round(as.numeric(rawSubjData$time)*framesPerSec)

		# \ A(3)	= total number of correct lever choices
		# \ A(17) = Tally of Forced left trials
		# \ A(18) = Tally of Forced right trials
		# \ A(19) = Tally of Choice trials
		# \ A(20) = Total number of incorrect lever choices
		# \ A(22) = Mean latency to do required lick
		# \ A(24) = Mean latency to press the lever
		# \ A(33) = Counter for left nose pokes
		# \ A(34) = Counter for right nose pokes
		# \ A(35) = Counter for licks
		# \ A(40) = Number of lick omissions (timeouts due to failure to do req licks in time)
		# \ A(41) = Number of lever omissions (timeouts due to failure to lever press in time)
		summaryStatList = c(3,17,18,19,20,22,24,33,34,35,40,41)
		summaryStatNames = c('correct_choices','forced_left','forced_right','choice_trials','incorrect_choices','mean_latency_lick','mean_latency_press','left_nose_count','right_nose_count','licks','omissions_lick','omissions_press')
		summarySubjData = readMedpcFiles(inputPath,events_id='A:',timestamp_id = 'A:');
		summarySubjData = data.frame(value = summarySubjData[summaryStatList+1,]$events, variable = summaryStatNames)
		for (thisName in names(extraData)){
			summarySubjData[thisName] = extraData[thisName]
		}

		outputData = list()
		# outputData$rawSubjData = rawSubjData
		outputData$rawSubjData = data.frame(j=NULL)
		outputData$summarySubjData = summarySubjData
		return(outputData)
	}, error = function(err) {
		print(err)
		print(traceback())
		print(warnings())
		return(NULL)
	}, finally = {
		# print(inputPath)
	})
}
writeData <- function(data, file, sep="\t"){
	# writes a data.frame to a file
	print(file)
	write.table(data, file=file, sep=sep, col.names=TRUE, row.names=FALSE, quote=FALSE)
}
controllerOperant <- function(data_dir,analysis_dir,...){
	# run main function

	# Function to get directory info and create folders

	data_sub_dir=""
	c(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir=data_dir,dataSubDir=data_sub_dir,analysisDir=analysis_dir,getUsrInput=FALSE)
	# _________________________________________________
	# get files
	fileList = list.files(data_main_dir, full.names=TRUE, include.dirs = FALSE)
	# Extract only the files
	# fileList = matrix(unlist(strsplit(fileList,'/')),nrow=length(strsplit(fileList,'/')[[1]]))[length(strsplit(fileList,'/')[[1]]),]
	print(fileList); flush.console();
	# _________________________________________________
	# Loop over each file, extract data
	result = tryCatch({
		# load clusters, functions, and variables
		startTime = Sys.time()

		# open multiple R workers, leave one logical core available for system processes
		cl = model.cluster()

		# get data for each file in parallel
		allSubjectData = parLapply(cl, fileList, fun=getOperantData)
		# unpack the data and combine into one data.frame
		# allSubjectData = do.call("rbind",allSubjectData)
		rawSubjData = lapply(allSubjectData, FUN=function(x){x$rawSubjData})
		rawSubjData = do.call("rbind",rawSubjData)
		summarySubjData = lapply(allSubjectData, FUN=function(x){x$summarySubjData})
		summarySubjData = do.call("rbind",summarySubjData)
	}, error = function(err) {
		print(err)
		print(traceback())
		return(data.frame())
	}, finally = {
		print(Sys.time()-startTime); flush.console();
		# stop the cluster
		stopCluster(cl)
		# return(data.frame())
	})

	print(Sys.time()-startTime); flush.console();
	# _________________________________________________
	# save data
	# writeData(allSubjectData,paste(analysis_dir,'../',"rawData.csv",sep=""),sep=',')
	# writeData(rawMouseData,paste(analysis_dir,'../',"mouseRaw.data",sep=""))
	# print(Sys.time()-startTime); flush.console();
	# _________________________________________________
	output = list()
	output$rawSubjData = rawSubjData
	output$summarySubjData = summarySubjData
	return(output)
}

listSubDirs = c('q175_reversal/','p215_q175_reversal/','ding_collaboration_progressive/')
data_dir_list = paste('D:/b/Dropbox/biafra_jones/data/behavior/med_files/',listSubDirs,sep="")
analysis_dir_list = paste('../../analysis/team_bg/',listSubDirs,sep="")
rawData = list()
newplots = list()
# loop over each folder and analyze the files there
for (dirNo in c(1:length(data_dir_list))) {
	data_dir = data_dir_list[dirNo]
	analysis_dir = analysis_dir_list[dirNo]
	rawData[[LETTERS[length(rawData)+1]]] = controllerOperant(data_dir,analysis_dir);
	# convert dates to trial nums
	trialTable = data.frame()
	tmpSummaryTable = rawData[[LETTERS[length(rawData)]]]$summarySubjData
	for(thisSubj in unique(tmpSummaryTable$subjectName)){
		#thisSubj = "B5"
		subjDate = unique(tmpSummaryTable$date[tmpSummaryTable$subjectName==thisSubj])
		dateOrder = order(subjDate)
		thisTable = data.frame(subjectName=thisSubj,date=subjDate,trialNum=dateOrder)
		trialTable  = rbind(trialTable,thisTable)
	}
	rawData[[LETTERS[length(rawData)]]]$summarySubjData = merge(tmpSummaryTable,trialTable)

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(rawData[[LETTERS[length(rawData)]]]$summarySubjData,aes(as.character(date),variable))+geom_tile(fill='white')+geom_text(aes(label=value),size=3)+facet_wrap(~subjectName,scales="free_x")+theme(axis.text.x = element_text(angle = 90, hjust = 1))
	newplots[[LETTERS[length(newplots)+1]]] = ggplot(rawData[[LETTERS[length(rawData)]]]$summarySubjData,aes(trialNum,value,color=subjectName,group=subjectName))+geom_point()+geom_line()+facet_wrap(~variable, scale="free")
}
# name new plots
lapply(newplots, FUN=function(x){dev.new(width=16,height=9);print(x);makeFootnote()})