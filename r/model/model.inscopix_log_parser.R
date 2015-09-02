# biafra ahanonu
# updated: 2013.09.18 [10:20:56]
# analyze inscopix files

# load dependencies
srcFileList = c('view/view.barplot.R', 'helper/helper.footnote.R', 'helper/helper.ggplot_themes.R')
lapply(srcFileList,FUN=function(file){source(file)})
# load packages
packagesFileList = c("reshape2", "ggplot2", "parallel", "stringr","lattice")
lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})

getFileInfo <- function(filename){
	print(filename)
	fileInfo = readMultiByteFile(filename, nrow=12)
	# print(fileInfo)
	if(!("VERSION" %in% colnames(fileInfo))){
		fileInfo$VERSION = "1.3.1"
	}else if(fileInfo$VERSION == "2.0b5"){
		fileInfo = readMultiByteFile(filename, nrow=19)
	}else{
		fileInfo = readMultiByteFile(filename, nrow=13)
	}
	#fileInfo[,2:10] = as.numeric(fileInfo[,2:10])
	fileInfo$dropped_count = fileInfo$"DROPPED COUNT"
	fileInfo$file = filename
	fileInfo$assay = str_extract(fileInfo$file, "(MAG|PAV(|-PROBE)|(Q|)EXT|REN|REINST|S(HC|CH)|SUL(|P)|SAL|TROP|epmaze|OFT|formalin|hcplate|vonfrey|acetone|pinprick|habit|OFT|roto|oft|openfield|check)\\d+")
	fileInfo$assayName = str_extract(fileInfo$assay, "[[:alpha:]]+")
	fileInfo$assayNum = as.numeric(str_extract(fileInfo$assay,"[[:digit:]]+"))
	fileInfo$date = str_extract(fileInfo$file, "\\d{4}_\\d{2}_\\d{2}")
	fileInfo$subject = as.numeric(gsub("m","",str_extract(fileInfo$file, "m\\d+")))
	fileInfo$protocol = as.numeric(gsub("p","",str_extract(fileInfo$file, "p\\d+")))
	return(fileInfo)
}
readMultiByteFile <-function(filename, nrow=12, mbyte=": ", sepSub=";"){
	fileData = readLines(filename)
	fileData = gsub(mbyte, sepSub, fileData)
	# print(fileData)
	fileData = textConnection(fileData)
	fileData = read.table(fileData, sep=sepSub, nrows=nrow, row.names=1, na.strings=c("[]"))
	fileInfo = as.data.frame(t(fileData), check.names=TRUE, stringsAsFactors=FALSE)

	return(fileInfo)
}
model.cluster <-function(...){
	# opens a cluster
	logFile = 'log.txt'
	# unlink (delete) the log file before starting
	unlink(logFile)
	# open multiple R workers, leave one logical core available for system processes
	cl = makeCluster(detectCores()-1, outfile=logFile)
	# pass scripts/packages to clusters
	clusterEvalQ(cl, {
		# srcFileList = c("model/model.pav.liquid.parse.R")
		# lapply(srcFileList,FUN=function(file){source(file)})
		packagesFileList = c("stringr")
		lapply(packagesFileList,FUN=function(file){if(!require(file,character.only = TRUE)){install.packages(file,dep=TRUE)}})
	})
	# pass data(bases) to clusters
	clusterExport(cl, exportFxns)
	return(cl)
}

result = tryCatch({
	# load clusters, functions, and variables
	startTime = Sys.time()

	# open multiple R workers, leave one logical core available for system processes
	exportFxns=c("readMultiByteFile","getFileInfo")
	cl = model.cluster(exportFxns)

	analysisDir = 'B:/data/miniscope/p188'
	# analysisDir = 'E:/biafra/data/miniscope/open_field/p97'
	infoFiles = list.files(analysisDir, pattern='recording.*.txt', recursive=TRUE, full.names=TRUE)
	# remove concat and other log files
	infoFiles = infoFiles[grep('(concat|log)',infoFiles, invert=TRUE)]

	# filter for empty files
	filteredFileInfo = c()
	count = 1;
	for (i in c(1:length(infoFiles))) {
		if(!(file.info(infoFiles[i])$size==0)){
			filteredFileInfo[count] = infoFiles[i];
			count = count + 1;
		}
	}

	print(filteredFileInfo); flush.console();
	# get data for each file in parallel
	tmpData = parLapply(cl, filteredFileInfo, fun=getFileInfo)
	# tmpData = lapply(infoFiles, getFileInfo)
	allFileInfo = do.call("rbind", tmpData)
	names(allFileInfo) = str_replace(names(allFileInfo)," ","_")
	allFileInfo$FILETIME = str_extract(allFileInfo$RECORD_START,"\\d+:\\d+ (AM|PM)")
	allFileInfo$FILETIME = as.POSIXct(allFileInfo$FILETIME,format="%I:%M %p")
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

if(exists("allFileInfo")){
	# make plots
	newplots = list()

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(allFileInfo, aes(assayNum, as.character(assayName),fill=as.numeric(dropped_count)))+geom_tile()+theme(axis.text.x = element_text(angle = 90, hjust = 1))+facet_wrap(~subject)+ggThemeBlank()
	#ggplot(allFileInfo, aes(WIDTH, as.numeric(dropped_count), group=WIDTH))+geom_boxplot()+geom_point()

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(allFileInfo, aes(assayNum, as.character(assayName),fill=as.numeric(dropped_count)/as.numeric(FRAMES)*100))+geom_tile()+theme(axis.text.x = element_text(angle = 90, hjust = 1))+facet_wrap(~subject)+ggThemeBlank()

	newplots[[LETTERS[length(newplots)+1]]] =ggplot(allFileInfo, aes(assayNum, as.character(assayName),fill=as.numeric(dropped_count)))+geom_tile()+theme(axis.text.x = element_text(angle = 90, hjust = 1))+facet_wrap(~subject)+ggThemeBlank()

	newplots[[LETTERS[length(newplots)+1]]] =ggplot(allFileInfo, aes(assayNum, as.character(subject),fill=FPS))+geom_tile()+theme(axis.text.x = element_text(angle = 90, hjust = 1))+facet_wrap(~assayName)+ggThemeBlank()+ggFillColor()

	newplots[[LETTERS[length(newplots)+1]]] = ggplot(allFileInfo,aes(as.character(subject),FILETIME,group=subject))+geom_boxplot()+geom_point()+xlab("subject")+ylab("trial start time ")+ggtitle("start time distributions (red line = dark/light transition)")+geom_hline(yintercept=as.numeric(as.POSIXct(c("07:00 AM","07:00 PM"),format="%I:%M %p")),color="red",size=2)+ggThemeBlank()+ggFillColor()+ggThemeBlank()+ggFillColor()

	# newplots[[LETTERS[length(newplots)+1]]] = ggplot(allFileInfo,aes(FILETIME,color=subject))+
	# geom_density()+
	# ggThemeBlank()+ggFillColor()

	# name new plots
	lapply(newplots, FUN=function(x){dev.new(width=16,height=9);print(x)})

}