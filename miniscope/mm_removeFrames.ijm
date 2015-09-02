// biafra ahanonu
// updated: 2013.07.19
// removes substacks based on a file-list

// set the temporary directory
tmpDirDialog = "substack.remove.list";

// create an options dialog box
Dialog.create("frame removal!");
Dialog.addNumber("number of folders to analyze!? ", 1);
Dialog.addString("name of file with substack list!? ", tmpDirDialog,80);
// display the dialog box
Dialog.show();

// get dialog box options
numFolders = Dialog.getNumber();
substackFile = Dialog.getString();

//Determine which folders to process
folderList = newArray();
for (iFolder=0; iFolder<numFolders; iFolder++) {
	folderStr = "Select folder " + iFolder;
	tmpDir = getDirectory(folderStr);
	// verify that it ends with a backslash
	newDir = verifyPathCorrect(tmpDir);
	folderList = Array.concat(newDir, folderList);
	print("Added session folder " + iFolder + ": " + folderList[iFolder]);
}
setBatchMode(true);
for (folder=0; folder<folderList.length; folder++) {
	removeFrames(folderList[folder], substackFile);
}

// setBatchMode(false);
function removeFrames(currentDir, substackFile){
	// removes frames and saves movie.
	substackRemoveFile = currentDir + substackFile;
	// assumes one Tiff file in directory
	currentImageFile = getTiffFile(currentDir);
	print(currentImageFile);
	open(currentImageFile);
	// string to split stack into
	substacksToRemove = File.openAsString(substackRemoveFile);
	// just to make sure there is no newline at the end
	substacksToRemove = split(substacksToRemove,"\n");
	// stacks to keep
	stackStr = "channels=" + substacksToRemove[0];
	print(stackStr);
	// run the macro
	selectWindow(currentImageFile);
	run("Make Substack...", stackStr);
	// save cleaned file
	imgSavePath = currentDir + "cleaned_" + currentImageFile;
	save(imgSavePath);
	close();
	close();
}
function getTiffFile(path){
	tmpList = getFileList(path);
	tmpArray = newArray();
	// filter for only TIFF files
	for (i=0; i<tmpList.length; i++) {
		testStr = toLowerCase(tmpList[i]);
		// startsWith(testStr, "recording_")
		if (endsWith(testStr, ".tif")||endsWith(testStr, ".tiff")) {
			tmpArray = Array.concat(tmpArray, testStr);
		}
	}
	arrayOfFiles = tmpArray;
	print(arrayOfFiles[0]);
	return arrayOfFiles[0];
}
function verifyPathCorrect(path){
	// checks that path ends with a backslash
	if ( !endsWith(path,"\\") ){
		path = path + "\\";
	}
	return path;
}
function getEndPathName(path){
	// gets the last folder in a directory path name
	splitPath = split(path,"\\");
	folderName = splitPath[splitPath.length-1];
	return folderName;
}
function sepline(text,seplineBefore){
	// adds a separating line to output log
	if (seplineBefore==1) {
		print("-------------------------------------------------");
		print(text);
	}else{
		print(text);
		print("-------------------------------------------------");
	}

}