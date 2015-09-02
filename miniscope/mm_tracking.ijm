// biafra ahanonu
// updated: 2013.10.04 [13:43:25]
// tracks an obj assuming it can be isolated via background subtraction and thresholding
// the resulting txt file should be filtered by finding the largest area for each Slice
// changelog
	// 2013.12.15 [19:22:11] several improvements to the workflow (now ask user to crop image, set the trheshold [the auto threshold wasn't very robust]) and a couple bug fixes.

// start the script
// parameters = getParameters()
parameters = "";
main(parameters);

function main(parameters){

	// set the temporary directory
	saveDir = "A:\\biafra\\data\\behavior\\open_field\\p97\\tracking\\tmp\\";

	// create an options dialog box
	Dialog.create("tracking parameters");
	Dialog.addNumber("number of session folders to analyze:", 1);
	Dialog.addString("tracking save path:", saveDir,80);
	Dialog.addCheckbox("use default temporary directory?", true);
	Dialog.addNumber("pct to add to obj mean gray value: ", 0);
	Dialog.addNumber("min pixel area for obj: ", 10);
	Dialog.addCheckbox("background subtract?", true);
	Dialog.addCheckbox("normalize stack?", true);

	// display the dialog box
	Dialog.show();

	// get dialog box options
	numFiles = Dialog.getNumber();
	saveDir = Dialog.getString();
	tmpDirUseDefault = Dialog.getCheckbox();
	objMinAdd = Dialog.getNumber();
	minObjArea = Dialog.getNumber();
	backgroundSubtract = Dialog.getCheckbox();
	normalizeStackChoice = Dialog.getCheckbox();
	// options for analyzing the obj
	measureOptions = "area center fit stack redirect=None decimal=3";
	analyzeOptions = "size=" + minObjArea + "-Infinity circularity=0.00-1.00 show=Outlines display clear stack";

	listOfFiles = newArray();
	for(i=0; i<numFiles; i++){
		fileStr = "select file " + i + "/" + numFiles;
		listOfFiles = Array.concat(listOfFiles,File.openDialog(fileStr));
		print("added file " + i + ": " + listOfFiles[i]);
		// concatName = getEndPathName(listOfFiles[i]);
	}

	startTime = getTime();

	for(i=0; i<listOfFiles.length; i++){
		thisFile = listOfFiles[i];
		open(thisFile);
		// get stackID
		stackID = getTitle();
		// get current image directory
		stackDir = getDirectory("image");
		// ask user to crop image
		cropImage(stackID);
		// decide whether to subtract the background
		if(backgroundSubtract == 1){
			subtractBackground(stackID);
		}else{
			selectWindow(stackID);
			run("Invert", "stack");
		}
		// normalize the image so threshold can be the same
		if(normalizeStackChoice == 1){
			normalizeStack(stackID);
		}
		// threshold the image
		thresholdStack(stackID, objMinAdd);
		print((getTime()-startTime)/1000 + ' seconds');
		// get x,y, etc.
		measureObj(stackID, measureOptions,analyzeOptions);
		// save results table
		saveResults(saveDir, stackID);
	}
	print((getTime()-startTime)/1000 + ' seconds');
}
function cropImage(stackID){
	print("cropping...");
	selectWindow(stackID);

	// as user to crop image
	setTool("rectangle");
	waitForUser("select region to crop...");
	run("Crop");

	return true;
}
function subtractBackground(stackID){
	print("subtracting background...");
	// substracts background from the input image. image must already be opened
	avgstackID = "AVG_" + stackID;
	selectWindow(stackID);
	// get image properties
	Stack.getDimensions(width, height, channels, slices, frames);
	// get average
	run("Z Project...", "start=1 stop=" + slices + " projection=[Average Intensity]");
	// invert the stack and the average
	selectWindow(stackID);
	run("Invert", "stack");
	selectWindow(avgstackID);
	run("Invert");
	// subtract the background
	imageCalculator("Subtract stack", stackID, avgstackID);
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
function thresholdStack(stackID, objMinAdd){
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

	// allow the user to set the threshold to be used
	setThreshold(150, 255);
	// start movie
	// run("Animation Options...", "speed=500 loop start");
	run("Threshold...");
	waitForUser("select threshold, only vary min...");
	getThreshold(objMin,objMax);

	// set the high/low values to threshold on
	objThresHigh = 255;
	objThresLow = objMin+objMinAdd*objMin;
	setTool("rectangle");

	// threshold the image
	setAutoThreshold("Default");
	//run("Threshold...");
	setAutoThreshold("Default");
	setThreshold(objThresLow, objThresHigh);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Light");

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