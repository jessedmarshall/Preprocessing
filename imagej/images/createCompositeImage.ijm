// downsample inscopix movies
// biafra ahanonu
// modified starting 2013.06.24
//
// changelog
	//

// TODO
	// 2014.01.14 [21:17:30] make code so that it only calls colors that exist

// start the script
// parameters = getParameters()
parameters = "";
print("\\Clear");
// get user parameters and start main function
getParameters(parameters);

function getParameters(parameters){
	// gets user input then starts the main function

	// set the temporary directory
	tmpDirDialog = "C:\\tmp\\";
	fileType = ".tif";

	// create an options dialog box
	Dialog.create("movie pre-processing parameters");
	Dialog.addMessage("each trial is saved to its own concat file.\n");
	Dialog.addNumber("analysis folders:", 1);
	Dialog.addString("red: ", "tdTom",80);
	Dialog.addString("green: ", "eGFP",80);
	Dialog.addString("blue:", "DAPI",80);
	// display the dialog box
	Dialog.show();

	// get dialog box options
	numSessions = Dialog.getNumber();
	redStr = Dialog.getString();
	greenStr = Dialog.getString();
	blueStr = Dialog.getString();

	// run the main function
	main(numSessions,redStr,greenStr,blueStr);
}
function main(numSessions,redStr,greenStr,blueStr){
	//Determine which sessions to process
	analysisFolderArray = newArray();
	for(i=0; i<numSessions; i++){
		sessionStr = "select folder to analyze " + i;
		analysisFolderArray = Array.concat(analysisFolderArray,getDirectory(sessionStr));
		print("added folder " + i + ": " + analysisFolderArray[i]);
	}

	nFolders = analysisFolderArray.length;
	for(folder=0; folder<nFolders; folder++){
		//
		currentFolder = analysisFolderArray[folder];
		folderStr = "folder " + (folder+1) + "/" + (nFolders) + ": " + currentFolder;
		sepline(folderStr,1);

		// main controller for this macro
		currentFileArray = getFileList(currentFolder);

		// the below should be a dynamic loop...
		filteredArray = filterArray(currentFileArray, blueStr);
		openArrayOfFiles(filteredArray);
		run("Images to Stack", "name="+blueStr+" title=[] use");

		filteredArray = filterArray(currentFileArray, greenStr);
		openArrayOfFiles(filteredArray);
		run("Images to Stack", "name="+greenStr+" title=[] use");

		filteredArray = filterArray(currentFileArray, redStr);
		openArrayOfFiles(filteredArray);
		run("Images to Stack", "name="+redStr+" title=[] use");

		run("Merge Channels...", "c1="+redStr+" c2="+greenStr+" c3="+blueStr+" create");

		run("Brightness/Contrast...");
		waitForUser("adjust contrast...");
		// Stack.getDimensions(width, height, channels, slices, frames);
		run("Make Montage...", "scale=1 increment=1 border=0 font=12");
		run("Stack to RGB");
	}

	return 1;
}
function openArrayOfFiles(inputArray){
	arrayLen = inputArray.length;
	for(i=0; i<arrayLen; i++){
		thisFile = inputArray[i];
		open(thisFile);
	}
}
function printArray(inputArray){
	arrayLen = inputArray.length;
	print("analyzing...");
	for(i=0; i<arrayLen; i++){
		thisFile = inputArray[i];
		print((i+1) + "/" + arrayLen + ": " + thisFile);
	}
}
function getUniqueFileGroups(inputFileArray, inputDelms){
	// gets the unique IDs for a group of files among a list

	groupIDs = newArray();
	for (i=0; i<inputFileArray.length; i++) {
		tmpArray = split(inputFileArray[i], inputDelms);
		groupIDs = Array.concat(groupIDs, tmpArray[0]);
	}
	// remove duplicates from array
	uniqueGroupIDs = removeArrayDuplicates(groupIDs);

	return uniqueGroupIDs;
}
function removeArrayDuplicates(inputArray){
	// finds and removes duplicates from an input array
	uniqueArrayOutput = newArray();
	// loop over all elements of the array and determine which are duplicates
	for (i=0; i<inputArray.length; i++) {
		thisElement = inputArray[i];
		// print(thisElement);
		if(i==0){
			uniqueArrayOutput = Array.concat(uniqueArrayOutput, thisElement);
		}else{
			// check whether current array element is a duplicate
			duplicate = false;
			for (j=0; j<uniqueArrayOutput.length; j++) {
				g = indexOf(uniqueArrayOutput[j],thisElement);
				// print(uniqueArrayOutput[j] + " | " + thisElement +  " | "  + g);
				if(i==j){
					// skip, not needed
				}else{
					if(indexOf(uniqueArrayOutput[j],thisElement)==0){
						duplicate = true;
					}
				}
			}
			// print(duplicate);
			if(duplicate==false){
				uniqueArrayOutput = Array.concat(uniqueArrayOutput, thisElement);
			}
		}
		// print('+++++');
	}

	return uniqueArrayOutput;
}
function filterArray(tmpList, thisFilter){
	// filters array by the start and end filter
	tmpArray = newArray();
	for(i=0; i<tmpList.length; i++){
		// testStr = toLowerCase(tmpList[i]);
		testStr = tmpList[i];
		containsFilter = indexOf(testStr, thisFilter);
		// print(containsFilter);
		if(containsFilter>0){
			tmpArray = Array.concat(tmpArray, testStr);
		}
	}
	return tmpArray;
}
function getEndPathName(path){
	// get the end of an input path
	splitPath = split(path,"\\");
	endOfPath = splitPath[splitPath.length-1];
	// print(endOfPath);
	return endOfPath;
}
function sepline(text,seplineBefore){
	// different options for adding separating lines to the log
	longLine = "-------------------------------------------------";
	if(seplineBefore==1){
		print(longLine);
		print(text);
	}else if(seplineBefore==2){
		print(longLine);
		print(longLine);
	}else if(seplineBefore==3){
		print(text);
	}else if(seplineBefore==4){
		print(longLine);
	}else{
		print(text);
		print(longLine);
	}
}