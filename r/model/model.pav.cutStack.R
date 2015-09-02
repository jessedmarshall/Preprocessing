# biafra ahanonu
# updated: 2013.10.07 [15:15:57]
# cut the stack

stackList = getStackList(rawMouseData, "809", "SHC02")
write(stackList, file="stackCut", ncolumns=length(stackList), sep=",")

getStackList <-function(r, thisMouse, thisPav, framesBefore = 50, framesAfter = 100, events=30, frameRate = 20, downsampleFactor = 0.25){
	# frameRate = frames/sec
	# downsampleFactor = factor downsample final movie

	CS = r[r$events==events&r$mouse==thisMouse&r$pav==thisPav,]
	# add frames to data.frame
	CS$frames = round(CS$time*frameRate)
	#frames before
	framesBeforeCS = framesBefore/downsampleFactor
	#frames after
	framesAfterCS = framesAfter/downsampleFactor

	stackList = lapply(CS$frames, FUN=function(x, before, after){
	stackList = c((x-before):(x+after))
	return(stackList)
	},framesBeforeCS,framesAfterCS)

	stackList = unlist(stackList)
	stackList2 = round(stackList*downsampleFactor)
	stackList2 = unique(stackList2)
	stackList2 = stackList2[1:(length(stackList2)-framesBefore)]
	return(stackList2)
}