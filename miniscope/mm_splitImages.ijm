// biafra ahanonu
// started: 2013.09.08 [01:38:25]
// bisects an open image and saves to current directory
// updated: 2013.10.04 [22:04:12] made into actual macro with options and ability to run automatically on selected files
// updated: 2013.11.05 [12:53:14] added the ability to select a file that contains paths to all files that need splitting

// TODO: add ability for script to detect file-size and base split on that

// OUTPUT: outputs into the same directory as selected file, adds split_0x_ where x={1,...,n} to beginning of filename

// start the script
// parameters = getParameters()
parameters = "";
main(parameters);

function main(parameters){
	print("\\Clear");

	// set the temporary directory
	tmpDirDialog = "C:\\tmp\\";

	// create an options dialog box
	Dialog.create("image splitting");
	Dialog.addMessage("movies should be <8GB currently.\n");
	Dialog.addNumber("number of images to split:", 1);
	Dialog.addCheckbox("use file with list of movies?", false);

	// display the dialog box
	Dialog.show();

	// get dialog box options
	numFiles = Dialog.getNumber();
	useFileMovieList = Dialog.getCheckbox();

	if (useFileMovieList == 1) {
		fileWithList = File.openDialog("select file with list of movies");
		listOfFiles = File.openAsString(fileWithList);
		listOfFiles = split(listOfFiles,"\n");
	}else{
		listOfFiles = getUserFileList(numFiles);
	}
	// setBatchMode(true);
	for(i=0; i<listOfFiles.length; i++){
		print('+++');
		thisFile = listOfFiles[i];
		print((i+1) + '/' + listOfFiles.length + ': ' + thisFile);
		if(startsWith(thisFile, "#")){
			print("commented out, skipping...");
		}else{
			open(thisFile);
			// get stackID
			stackID = getTitle();
			// get current image directory
			stackDir = getDirectory("image");
			// split the stack
			splitStack(stackID,stackDir);
		}
	}
	print('terminado!');
	// setBatchMode(false);
}
function getUserFileList(numFiles){
	// gets the requested numFiles from a user
	listOfFiles = newArray();
	for(i=0; i<numFiles; i++){
		fileStr = "select file " + i + "/" + numFiles;
		listOfFiles = Array.concat(listOfFiles,File.openDialog(fileStr));
		print("added file " + i + ": " + listOfFiles[i]);
		// concatName = getEndPathName(listOfFiles[i]);
	}

	return listOfFiles;
}
function splitStack(stackID,stackDir){
	// splits the stack represented by stackID, must already be open

	selectWindow(stackID);
	// get image properties
	Stack.getDimensions(width, height, channels, slices, frames);
	// estimate size in GB, assume 32-bit (4-byte) image
	imageSize = width*height*slices*(32/8)/(1024*1024*1024);
	// make size of a tiff file in GB
	maxTiffSize = 4;
	// estimate number of stacks needed
	numStacks = -floor(-imageSize/maxTiffSize);
	print("image: " + imageSize + "GB, split: " + numStacks + " stacks");
	// slice the stack in half
	substackCmd = "delete slices=1-" + round(slices/2);
	run("Make Substack...", substackCmd);
	// run("Stack Splitter", "number="+numStacks);
	// save first substack
	for (i=1; i<=numStacks; i++) {
		// thisStack = "stk_000" + i + "_" + stackID;
		// selectWindow(thisStack);
		thisStackSave = stackDir+"split_0" + i + "_"+stackID;
		print(thisStackSave);
		saveAs("Tiff", thisStackSave);
		close();
	}
	// selectWindow(stackID);
	// close();
	return true;
}