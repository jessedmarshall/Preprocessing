// downsample inscopix movies
// bennie
// 2012.10.08
//
// biafra ahanonu
// updated: 2013.08.16 [10:09:13]
// modified starting 2013.06.24
	// 2013.06.25: automated file list, ask the user for session folders (manual option still exists), moved processFiles() (incorrectly nested), renamed variables/re-organized code (readability), changed concat to load files one-by-one and concat that way (speed), and can just concat if fails (avoid re-normalizing).
	// 2013.06.26: filters for  .tiff/.tif files, auto adds backslash to directories, adds directory name to concatenated file, and finds first file if not named -000.
	// 2013.07.05: fix some bugs related to saving files, filters for only 'recording_.*\.tiff' files, so can have snapshots in the same folder sans errors.
	// 2013.07.23: fixed bug where the last item in the list was removed, causing the last imaging file to not be analyzed
	// 2013.08.21 [21:50:32] now save concatenated file to a sub-folder for quicker later processing, also fixed multi-folder bug, now works
	// 2013.09.04 [21:45:55] fixed bug in checkCorrectStartFile() that caused it to NOT move the last file to the beginning
	// updated: 2013.09.09 [14:46:27] added folder number to output

// set the temporary directory
tmpDirDialog = "E:\\tmp\\";

// create an options dialog box
Dialog.create("Paramters for image pre-processing");
// Dialog.addMessage("First tiff should be *-000.tiff to make sure order is correct.\n");
Dialog.addNumber("Downsampling factor:", 0.25);
Dialog.addNumber("FFT highpass in pixel:", 5);
Dialog.addNumber("FFT lowpass in pixel:", 80);
Dialog.addNumber("number of session folders to analyze:", 1);
Dialog.addCheckbox("Skip FFT:", true);
Dialog.addCheckbox("Save concatenated stacks as HDF5 (otherwise saves tif):", false);
Dialog.addCheckbox("Use old method (sessionorder.tex and movieorder.tex?:", false);
Dialog.addString("Temporary directory path:", tmpDirDialog,80);
Dialog.addCheckbox("Use default temporary directory?", true);
Dialog.addCheckbox("Concat only?", false);

// display the dialog box
Dialog.show();

// get dialog box options
dsfactor = Dialog.getNumber();
ffthp = Dialog.getNumber();
fftlp = Dialog.getNumber();
numSessions = Dialog.getNumber();
SFFT = Dialog.getCheckbox();
HDF = Dialog.getCheckbox();
oldInputMethod = Dialog.getCheckbox();
tmpDir = Dialog.getString();
tmpDirUseDefault = Dialog.getCheckbox();
onlyConcatFiles = Dialog.getCheckbox();

// set variables
imagelist= " ";
imagelistB= " ";
bpstr = " ";
concatenatestr =  " ";
scalestr= " ";

// set how scaling should occur
scalestr =  "x=" + dsfactor + " y=" + dsfactor + " z=1.0 width=720 height=540 interpolation=Bicubic average process create title=new";

//Determine which sessions to process
if (oldInputMethod == 1) {
	mainDir = getDirectory("Choose a Directory that includes the session folders and the sessionorder.txt ");
	slist = File.openAsString(mainDir+"sessionorder.txt");
	slist = split(slist,"\n");
}else{
	slist = newArray();
	for (i=0; i<numSessions; i++) {
		sessionStr = "Select session folder " + i;
		slist = Array.concat(slist,getDirectory(sessionStr));
		print("Added session folder " + i + ": " + slist[i]);
		concatName = getEndPathName(slist[i]);
		print("concat filename: concatenated_" + concatName + ".tif");
	}
}
// get the temporary directory
if (tmpDirUseDefault == 1) {
	tmpFileDir = tmpDir;
}else{
	tmpFileDir = getDirectory("Choose a temp directory for pre-processing the imaging data");
}
// verify that it ends with \
if ( !endsWith(tmpFileDir,"\\") ){
	tmpFileDir = tmpFileDir + "\\";
}
print("temp directory: " + tmpFileDir);

setBatchMode(true);
sepline("starting analysis",1);
if (onlyConcatFiles == 0) {
	// go through the session folders
	for (j=0; j<slist.length; j++) {
		print("folder " + j + " of " + slist.length);
		if (oldInputMethod == 1) {
			tiffFileDir = mainDir + slist[j] + "\\" ;
			//Determine which images to process
			dirImages = tiffFileDir+"movieorder.txt";
			arrayOfFiles = File.openAsString(dirImages);
			arrayOfFiles = split(arrayOfFiles,"\n");
		}else{
			tiffFileDir = slist[j];
			sepline("directory: " + tiffFileDir,1);
			tmpList = getFileList(slist[j]);
			tmpArray = newArray();
			// filter for only TIFF files
			for (i=0; i<tmpList.length; i++) {
				testStr = toLowerCase(tmpList[i]);
				if (startsWith(testStr, "recording_")&&endsWith(testStr, ".tif")||endsWith(testStr, ".tiff")) {
					tmpArray = Array.concat(tmpArray, testStr);
				}
			}
			arrayOfFiles = tmpArray;
		}
		// check we have the correct starting file
		arrayOfFiles = checkCorrectStartFile(arrayOfFiles,"-000.tif");
		// print list of all files to analyze
		printFileList(arrayOfFiles);

		// process files, skip if only concatenating
		processFiles(tiffFileDir,arrayOfFiles,tmpFileDir,oldInputMethod);

		// concatenate the processed files
		setBatchMode(false);
		ConcatenateAllFiles(tmpFileDir,tiffFileDir,arrayOfFiles, onlyConcatFiles);
		setBatchMode(true);
		sepline("",2);
	}
}else{
	// get the tiff directory to place concatenated file
	tiffFileDir = slist[0];
	arrayOfFiles = getFileList(tmpFileDir);
	// print list of all files to analyze
	printFileList(arrayOfFiles);
	// concatenate the processed files
	setBatchMode(false);
	ConcatenateAllFiles(tmpFileDir,tiffFileDir,arrayOfFiles, onlyConcatFiles);
	setBatchMode(true);
}
function makeArrayUnique(array){

}
function checkCorrectStartFile(arrayOfFiles,start){
	if ( !endsWith(arrayOfFiles[0],start) ) {
		lenList = lengthOf(arrayOfFiles)-1;
		lastElement = newArray(arrayOfFiles[lenList]);
		trimList = Array.trim(arrayOfFiles,lenList);
		arrayOfFiles = Array.concat(lastElement, trimList);
		print("first file is: " + arrayOfFiles[0]);
	}
	return arrayOfFiles;
}
function printFileList(arrayOfFiles){
	arrayLen = arrayOfFiles.length;
	print("going to analyze the following files");
	for (i=0; i<arrayLen; i++) {
		thisFile = arrayOfFiles[i];
		print("file " + (i+1) + " of " + arrayLen + ": " + thisFile);
	}
}
function processFiles(tiffFileDir,arrayOfFiles,tmpFileDir,oldInputMethod) {
	//Go through all files in directory in the order listed in movieorder.txt (you will need to create this file)
	//Spatial downsample all files, perform column-row normalization, concatenate together, and save
	//biafra: i moved this outside the above for...loop, no need to redefine on each pass...
	sepline("starting scaling...",1);
	arrayLen = arrayOfFiles.length;
	n = 0;
	for (i=0; i<arrayLen; i++) {
		thisFile = arrayOfFiles[i];
		// showProgress(n++, arrayOfFiles.length);
		if(oldInputMethod == 1){
			path = thisFile;
		}else{
			path = tiffFileDir+thisFile;
		}
		print("processing file " + (i+1) + " of " + arrayLen + ": " + path);
		// open image
		open(path);
		// run FFT (or not)
		if ( SFFT != 1) {
			bpstr= " filter_large=" + fftlp + " filter_small=" + ffthp + " suppress=None tolerance=5 autoscale saturate process";
			run("Bandpass Filter...",bpstr );
		}
		// scale
		//selectWindow(list[i]);
		run("Scale...", scalestr);
		selectWindow("new");
		if (i<10) {
			savei = "0" + i;
		}else{
			savei = i;
		}
		tmpPath = tmpFileDir + savei + "_normalized_" + thisFile;
		print("saving to: " + tmpPath);
		save(tmpPath);
		// close 'window'
		close();close();
	}
	sepline("finished scaling...",0);
}

function ConcatenateAllFiles(tmpFileDir,tiffFileDir,arrayOfFiles, onlyConcatFiles) {
	// loop over all temporary files and concat one-by-one
	// list = getFileList(tmpFileDir);
	concatenatestr = "title=[concat] ";
	numCat=1;
	arrayLen = arrayOfFiles.length;
	for (i=0; i<arrayLen; i++) {
		// showProgress(n++, arrayOfFiles.length);
		// get string for filename and for Concatenate fxn
		if (i<10) {
			savei = "0" + i;
		}else{
			savei = i;
		}
		thisFile = arrayOfFiles[i];
		print("adding file " + (i+1) + " of " + arrayLen + ": " + thisFile);
		if (onlyConcatFiles==0) {
			nextImg = tmpFileDir + savei + "_normalized_" + thisFile;
			imgStr = " image"+ numCat + "=" + savei + "_normalized_" + thisFile;
		}else{
			nextImg = tmpFileDir + thisFile;
			imgStr = " image"+ numCat + "=" + thisFile;
		}
		concatenatestr = concatenatestr + imgStr;
		// load each temporary image
		open(nextImg);
		// add each loaded image to concat tif file
		if (i!=0) {
			//print(concatenatestr);
			run("Concatenate..." , concatenatestr);
			numCat=1;
			concatenatestr = "title=[concat] image1=concat ";
			selectWindow("concat");
		}
		numCat++;
	}

	// run("Concatenate..." , concatenatestr);
	// selectWindow("Concatenated_Stacks");
	//path to save as a TIFF
	concatSaveFile = getEndPathName(tiffFileDir);
	// pathTiff = tiffFileDir + "Concatenated_" +  slist[j] +".tif";
	concatSaveDir = tiffFileDir + "concat\\";
	// create sub directory
	File.makeDirectory(concatSaveDir);
	pathTiff = concatSaveDir +"concatenated_" + concatSaveFile + ".tif";
	//path to save as HDF5
	// pathhdf = tiffFileDir + "Concatenated_" +  slist[j] + ".h5";
	pathhdffin = concatSaveDir + "concatenated_" + concatSaveFile + ".hd5";

	if (HDF == 0) {
		print("concat filename: concatenated_" + concatName + ".tif");
		save(pathTiff);
	} else {
		print("concat filename: concatenated_" + concatName + ".hd5");
		pathhdf=replace(pathhdf, File.separator, "q");
		pathhdf=replace(pathhdf, "q", "qq");
		pathhdf=replace(pathhdf, "q", "\\");
		pathhdffin="save=" + pathhdf + " concatenated_stacks=movie" ;
		//print(pathhdffin);
		run("Save HDF5 File", pathhdffin);
	}

	selectWindow("concat");
	close();

	selectWindow("Log");  //select Log-window
	saveAs("Text", concatSaveDir + "log.txt");
}
function getEndPathName(path){
	splitPath = split(path,"\\");
	folderName = splitPath[splitPath.length-1];
	return folderName;
}
function sepline(text,seplineBefore){
	if(seplineBefore==1){
		print("-------------------------------------------------");
		print(text);
	}
	if(seplineBefore==2){
		print("-------------------------------------------------");
		print("-------------------------------------------------");
	}
	}else{
		print(text);
		print("-------------------------------------------------");
	}

}