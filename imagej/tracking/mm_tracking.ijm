// biafra ahanonu
// updated: 2013.10.04 [13:43:25]
// tracks an obj assuming it can be isolated via background subtraction and thresholding
// the resulting txt file should be filtered by finding the largest area for each Slice
// changelog
	// 2013.12.15 [19:22:11] several improvements to the workflow (now ask user to crop image, set the trheshold [the auto threshold wasn't very robust]) and a couple bug fixes.
	// 2014.05.16 - added ability to convert to 8 bit, crop using NaN as a way to remove inconvenient regions, close all windows at end, automatic thresholding, ability to load a list of files, etc..

//TODO
	// add convert to 8 bit option!!!!
	// dialation
	// use selection, inverse and set outside to NaN

// start the script
// parameters = getParameters()
parameters = "";
main(parameters);

function main(parameters){

	// set the temporary directory
	saveDir = "C:\\";
	objThresHigh = 255;
	objThresLow = 62;
	// ========================================================
	// create an options dialog box
	Dialog.create("tracking parameters");
	Dialog.addNumber("number of session folders to analyze:", 1);
	Dialog.addString("tracking save path:", saveDir,80);
	Dialog.addNumber("pct to add to obj mean gray value: ", 0);
	Dialog.addNumber("min pixel area for obj: ", 100);
	Dialog.addNumber("max pixel area for obj: ", 5000);
	Dialog.addCheckbox("background subtract?", false);
	Dialog.addCheckbox("background average (check) max (uncheck)?", true);
	Dialog.addCheckbox("normalize stack?", false);
	Dialog.addCheckbox("crop stack?", false);
	// convert to 8 bit?
	Dialog.addCheckbox("convert movie to 8-bit?", false);
	// extra invert (obj should be black on white)
	Dialog.addCheckbox("invert movie colors (obj black on white)?", true);
	// automatically threshold?
	Dialog.addCheckbox("automatically threshold?", true);
	Dialog.addString("auto threshold type (Minimum, Otsu, MaxEntropy)", "Minimum",80);
	Dialog.addNumber("slice to estimate automatic threshold: ", 200);
	Dialog.addNumber("frames to gamma adjust: ", 0);
	Dialog.addNumber("gamma adjust value (0.1-3): ", 0.1);
	Dialog.addNumber("high threshold value: ", objThresHigh);
	Dialog.addNumber("low threshold value: ", objThresLow);
	Dialog.addCheckbox("erode and dilate?", true);
	// whether to look at a file containing a list of relevant movies
	Dialog.addCheckbox("analyze movies from a list file", true);
	//
	Dialog.addCheckbox("open avi dialog?", true);
	Dialog.addNumber("first frame movie (0=all): ", 0);
	Dialog.addNumber("last frame movie: ", 0);
	//
	Dialog.addCheckbox("open single frame?", false);
	// display the dialog box
	Dialog.show();
	// ========================================================
	// get dialog box options
	numFiles = Dialog.getNumber();
	saveDir = Dialog.getString();
	objMinAdd = Dialog.getNumber();
	minObjArea = Dialog.getNumber();
	maxObjArea = Dialog.getNumber();
	backgroundSubtract = Dialog.getCheckbox();
	backgroundAvgOrMax = Dialog.getCheckbox();
	normalizeStackChoice = Dialog.getCheckbox();
	cropImageOption = Dialog.getCheckbox();
	checkUse8bit = Dialog.getCheckbox();
	extraInvert = Dialog.getCheckbox();
	//
	useAutomaticThreshold = Dialog.getCheckbox();
	thresholdMethodType = Dialog.getString();
	sliceToEstimateThreshold = Dialog.getNumber();
	framesToGammaAdj = Dialog.getNumber();
	gammaAdjValue = Dialog.getNumber();
	objThresHigh = Dialog.getNumber();
	objThresLow = Dialog.getNumber();
	erodeDilateStack = Dialog.getCheckbox();

	useListFile = Dialog.getCheckbox();
	checkUseAviDialog = Dialog.getCheckbox();
	firstFrame = Dialog.getNumber();
	lastFrame = Dialog.getNumber();
	//
	openSingleFrame = Dialog.getCheckbox();
	// ========================================================

	// options for analyzing the obj, centroid
	measureOptions = "area center fit stack redirect=None decimal=3";
	analyzeOptions = "size=" + minObjArea + "-" + maxObjArea + " circularity=0.00-1.00 show=Outlines display clear stack";

	// make sure save directory has trailing slash
	if(!endsWith(saveDir,"\\")){
		print('appending slash to save directory...');
		saveDir = saveDir + "\\";
		print(saveDir);
	}

	if(useListFile){
		fileList = File.openDialog('select file with list of movie (tiff, avi, etc.) to convert');
		listOfFiles = File.openAsString(fileList);
		listOfFiles = split(listOfFiles,"\n");
	}else{
		listOfFiles = newArray();
		for(i=0; i<numFiles; i++){
			fileStr = "select file " + i + "/" + numFiles;
			listOfFiles = Array.concat(listOfFiles,File.openDialog(fileStr));
			print("added file " + i + ": " + listOfFiles[i]);
			// concatName = getEndPathName(listOfFiles[i]);
		}
	}

	startTime = getTime();

	// GET USER INPUT BEFORE PROCESSING
	thresholdMinArray = newArray();
	thresholdMaxArray = newArray();
	//
	rectArray_x = newArray();
	rectArray_y = newArray();
	rectArray_width = newArray();
	rectArray_height = newArray();
	for(fileNo=0; fileNo<listOfFiles.length; fileNo++){
		print('=======');
		thisFile = listOfFiles[fileNo];
		print((fileNo+1)+'/'+listOfFiles.length+': '+thisFile);
		if(cropImageOption){
			// selectWindow(stackID);
			run("AVI...", "select=["+thisFile+"] first="+sliceToEstimateThreshold+" last="+(sliceToEstimateThreshold+3));
			// as user to crop image
			setTool("rectangle");
			waitForUser("select region to crop...");
			getSelectionBounds(x, y, width, height);
			rectArray_x = Array.concat(rectArray_x,x);
			rectArray_y = Array.concat(rectArray_y,y);
			rectArray_width = Array.concat(rectArray_width,width);
			rectArray_height = Array.concat(rectArray_height,height);
			closeAllWindows();
		}
		if(!useAutomaticThreshold){
			run("AVI...", "select=["+thisFile+"] first="+1+" last="+10);
			run("AVI...", "select=["+thisFile+"] first="+sliceToEstimateThreshold+" last="+(sliceToEstimateThreshold+3));
			run("Concatenate...", "all_open title=["+thisFile+"]");

			if(framesToGammaAdj!=0){
				print('gamma correcting: '+gammaAdjValue);
				for(frameNo=1; frameNo<=framesToGammaAdj; frameNo++) {
					setSlice(frameNo);
					for(runNo=1; runNo<=3; runNo++) {
						run("Gamma...", "value="+gammaAdjValue);
					}
					// run("Gamma...", "value=0.1");
					// run("Gamma...", "value=5 slice");
					// v = getResult("Mean",i-1);
					// print(v);
					// run("Subtract...", "value=&v");
				}
			}
			setSlice(11);

			run("Threshold...");
			setAutoThreshold(thresholdMethodType);
			waitForUser("select threshold, only vary min...");
			getThreshold(objMin,objMax);
			thresholdMinArray = Array.concat(thresholdMinArray,objMin);
			thresholdMaxArray = Array.concat(thresholdMaxArray,objMax);
			closeAllWindows();
		}
	}

	for(i=0; i<listOfFiles.length; i++){
		print('=======');
		thisFile = listOfFiles[i];
		print((i+1)+'/'+listOfFiles.length+': '+thisFile);
		// if user just wants to open a single frame, e.g. to measure px/cm
		if(openSingleFrame){
			open(thisFile);
			setTool("line");
			waitForUser("select threshold, only vary min...");
		}else{
			if(checkUseAviDialog){
				open(thisFile);
			}else{
				if (firstFrame!=0) {
					run("AVI...", "select=["+thisFile+"] first="+firstFrame+" last="+lastFrame);
				}else{
					run("AVI...", "select=["+thisFile+"]");
				}
			}
			// open(thisFile);
			if(checkUse8bit){
				run("8-bit");
			}
			// get stackID
			stackID = getTitle();
			// get current image directory
			stackDir = getDirectory("image");
			// ask user to crop image
			if(cropImageOption){
				cropImage(stackID,"NaN",rectArray_x[i],rectArray_y[i],rectArray_width[i],rectArray_height[i]);
			}
			// decide whether to subtract the background
			if(backgroundSubtract){
				subtractBackground(stackID,backgroundAvgOrMax);
			}else{
				selectWindow(stackID);
				run("Invert", "stack");
			}
			if(extraInvert){
				run("Invert", "stack");
			}else{
			}
			// normalize the image so threshold can be the same
			if(normalizeStackChoice){
				normalizeStack(stackID);
			}
			// threshold the image
			thresholdStack(stackID, objMinAdd,objThresHigh,objThresLow,useAutomaticThreshold,sliceToEstimateThreshold,framesToGammaAdj,gammaAdjValue,thresholdMethodType,thresholdMinArray[i],thresholdMaxArray[i]);
			// ask user to crop image
			if(cropImageOption){
				cropImage(stackID,"0",rectArray_x[i],rectArray_y[i],rectArray_width[i],rectArray_height[i]);
			}
			// erode and dilate image, remove small objects
			if(erodeDilateStack){
				for(i=1; i<=1; i++) {
					run("Erode", "stack");
				}
				for(i=1; i<=3; i++) {
					run("Dilate", "stack");
				}
			}
			// get x,y, etc.
			measureObj(stackID, measureOptions,analyzeOptions);
			// save results table
			saveResults(saveDir, stackID);
			print((getTime()-startTime)/1000 + ' seconds');
		}
		// close all windows
		closeAllWindows();
	}
	print((getTime()-startTime)/1000 + ' seconds');
}
function closeAllWindows(){
	while (nImages>0) {
		selectImage(nImages);
		close();
	}
}
function cropImage(stackID,cropValue,x,y,width,height){
	print("cropping...");
	selectWindow(stackID);

	// as user to crop image
	setTool("rectangle");
	makeRectangle(x, y, width, height);
	// waitForUser("select region to crop...");

	run("Make Inverse");
	run("Set...", "value="+cropValue+" stack");
	run("Select None");

	// run("Crop");

	return true;
}
function subtractBackground(stackID,backgroundAvgOrMax){
	print("subtracting background...");
	// substracts background from the input image. image must already be opened
	selectWindow(stackID);
	// get image properties
	Stack.getDimensions(width, height, channels, slices, frames);
	if(backgroundAvgOrMax){
		backgroundStackID = "AVG_" + stackID;
		// get average
		run("Z Project...", "start=1 stop=" + slices + " projection=[Average Intensity]");
	}else{
		backgroundStackID = "MAX_" + stackID;
		// get average
		run("Z Project...", "start=50 stop=" + slices + " projection=[Max Intensity]");
	}
	// invert the stack and the average
	selectWindow(stackID);
	run("Invert", "stack");
	selectWindow(backgroundStackID);
	run("Invert");
	// subtract the background
	imageCalculator("Subtract stack", stackID, backgroundStackID);
	// threshold the stack
	selectWindow(stackID);

	return true;
}
function normalizeStack(stackID){
	print("normalizing...");
	// this normalizes each stack by it's own mean then re-scales it. this allows absolute thresholding across all stacks.
	selectWindow(stackID);
	// convert to 32-bit so calculations are correct
	// run("32-bit");
	run ("Select None");
	// only measure the mean
	run("Set Measurements...", "  mean redirect=None decimal=3");
	// plot the mean for the entire stack
	run("Plot Z-axis Profile");
	// get image properties
	selectWindow(stackID);
	Stack.getDimensions(width, height, channels, slices, frames);
	// loop over each frame in movie and normalize the image values
	selectWindow(stackID);
	print(slices);
	for(i=1; i<=slices; i++) {
		setSlice(i);
		v = getResult("Mean",i-1);
		// print(v);
		run("Subtract...", "value=&v");
	}
	// reset the min-max so all images have the same range
	resetMinAndMax();
	// convert to 8-bit


	return true;
}
function thresholdStack(stackID, objMinAdd,objThresHigh,objThresLow,useAutomaticThreshold,sliceToEstimateThreshold,framesToGammaAdj,gammaAdjValue,thresholdMethodType,objMin,objMax){
	print("thresholding...");
	// thresholds a stack based on the gray value of an object

	// ask user for location
	selectWindow(stackID);

	// // ask user to select obj
	// // convert tool to free-hand temporarily
	// // setTool("freehand");
	// setTool("wand");
	// waitForUser("draw region or select obj");
	// run("Set Measurements...", "mean min max redirect=None decimal=3");
	// run("Measure");
	// store mean gray value
	// objMean = getResult("Mean");
	// objMin = getResult("Min");
	// objMax = getResult("Max");
	// sliceToEstimateThreshold = 100;
	// framesToGammaAdj = 7;
	if(framesToGammaAdj!=0){
		print('gamma correcting: '+gammaAdjValue);
		for(i=1; i<=framesToGammaAdj; i++) {
			setSlice(i);
			for(ii=1; ii<=3; ii++) {
				run("Gamma...", "value="+gammaAdjValue);
			}
			// run("Gamma...", "value=0.1");
			// run("Gamma...", "value=5 slice");
			// v = getResult("Mean",i-1);
			// print(v);
			// run("Subtract...", "value=&v");
		}
		// waitForUser("select threshold, only vary min...");
	}
	if(useAutomaticThreshold){
		// setThreshold(150, 255);
		// run("Convert to Mask", "method=MaxEntropy background=Dark calculate");
		// run("Convert to Mask", "method=Otsu background=Dark calculate");
		// run("Convert to Mask", "method=Minimum background=Dark calculate");
		setSlice(sliceToEstimateThreshold);
		setAutoThreshold(thresholdMethodType);
		run("Convert to Mask", "method="+thresholdMethodType+" background=Dark");
		// run("Erode", "stack");
	}else{
		// allow the user to set the threshold to be used
		// setThreshold(150, 255);
		// start movie
		// run("Animation Options...", "speed=500 loop start");
		// run("Threshold...");
		// waitForUser("select threshold, only vary min...");
		// getThreshold(objMin,objMax);
		// set the high/low values to threshold on
		objThresHigh = objMax;
		objThresLow = objMin+objMinAdd*objMin;
		setTool("rectangle");

		// threshold the image
		setAutoThreshold("Default");
		//run("Threshold...");
		setAutoThreshold("Default");
		setThreshold(objThresLow, objThresHigh);
		setOption("BlackBackground", false);
		run("Convert to Mask", "method=Default background=Light");
		print("low threshold: "+objThresLow);
		print("high threshold: "+objThresHigh);
	}
	return true;
}
function measureObj(stackID, measureOptions,analyzeOptions){
	print("getting obj measurements...");
	// measures the location of an object based on a binary stack
	selectWindow(stackID);
	// measure results
	run("Set Measurements...", measureOptions);
	run("Analyze Particles...", analyzeOptions);

	return true;
}
function saveResults(saveDir, stackID){
	print("saving results...");
	// save results to file
	// set io to comma-delineated file
	// run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file copy_column save_column");
	run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file save_column");
	// save the results
	saveAs("Results", saveDir+stackID+".tracking.csv");
	print('saved to: ' + saveDir+stackID+".tracking.csv");

	return true;
}
function getBaseFilename(file){
	splitPath = split(path,".");
	endOfPath = splitPath[splitPath.length-1];
	return endOfPath;
}