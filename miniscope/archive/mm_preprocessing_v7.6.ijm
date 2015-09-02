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
	// updated: 2013.09.11 [12:16:17] script now checks for temp files already processed in the tmp directory in case you had to exit early, check is by filename (which should be unique given it is down to seconds)
	// updated: 2013.09.12 [15:38:10] some cosmetic changes (noting folders) and refactored script so inside a main() fxn, reduce global variable mess. Script can also now handle directories with only one tiff (doesn't fail on concatenating).
	// updated: 2013.09.14 [19:59:15] concat is based on actual array of tmp file locations, rather than an agreed upon naming scheme, more portable. other log related changes.
	// updated: 2013.09.15 [14:09:28] now operates from the command line

// start the script
// parameters = getParameters()
macro "registerFiles" {

	parameters = "";
	main(parameters);

	function main(parameters){
		// set the temporary directory
		tmpDirDialog = "C:\\tmp\\";

		// // create an options dialog box
		// Dialog.create("movie pre-processing parameters");
		// Dialog.addMessage("folder should have one trial in it (at present).\n");
		// Dialog.addNumber("downsampling factor:", 0.25);
		// Dialog.addNumber("FFT highpass in pixel:", 5);
		// Dialog.addNumber("FFT lowpass in pixel:", 80);
		// Dialog.addNumber("number of session folders to analyze:", 1);
		// Dialog.addCheckbox("skip FFT:", true);
		// Dialog.addCheckbox("save concatenated stacks as HDF5 (otherwise saves tif):", false);
		// Dialog.addCheckbox("use old method (sessionorder.tex and movieorder.tex?:", false);
		// Dialog.addString("temporary directory path:", tmpDirDialog,80);
		// Dialog.addCheckbox("use default temporary directory?", true);
		// Dialog.addCheckbox("concat only?", false);

		// // display the dialog box
		// Dialog.show();

		// get dialog box options
		dsfactor = 0.25;
		ffthp = 5;
		fftlp = 80;
		numSessions = 1;
		SFFT = true;
		HDF = false;
		oldInputMethod = false;
		tmpDir = "E:\\tmp\\";
		tmpDirUseDefault = true;
		onlyConcatFiles = false;

		// set how scaling should occur
		scalestr =  "x=" + dsfactor + " y=" + dsfactor + " z=1.0 width=720 height=540 interpolation=Bicubic average process create title=new";

		//Determine which sessions to process
		if(oldInputMethod == 1){
			mainDir = getDirectory("choose a Directory that includes the session folders and the sessionorder.txt ");
			slist = File.openAsString(mainDir+"sessionorder.txt");
			slist = split(slist,"\n");
		}else{
			slist = newArray();
			for(i=0; i<numSessions; i++){
				sessionStr = "select session folder " + i;
				slist = Array.concat(slist,getDirectory(sessionStr));
				print("added session folder " + i + ": " + slist[i]);
				concatName = getEndPathName(slist[i]);
				print("concat filename: concatenated_" + concatName + ".tif");
			}
		}
		// get the temporary directory
		if(tmpDirUseDefault == 1){
			tmpFileDir = tmpDir;
		}else{
			tmpFileDir = getDirectory("choose a temp directory for pre-processing the imaging data");
		}
		// verify that it ends with \
		if(!endsWith(tmpFileDir,"\\")){
			tmpFileDir = tmpFileDir + "\\";
		}
		print("temp directory: " + tmpFileDir);

		setBatchMode(true);
		sepline("starting analysis...",1);
		if(onlyConcatFiles == 0){
			// go through the session folders
			for(j=0; j<slist.length; j++){
				startTime = getTime();
				sepline("folder: " + (j+1) + "/" + (slist.length),1);
				// change how the directory is obtained based on method
				if(oldInputMethod == 1){
					tiffFileDir = mainDir + slist[j] + "\\" ;
					//Determine which images to process
					dirImages = tiffFileDir+"movieorder.txt";
					arrayOfFiles = File.openAsString(dirImages);
					arrayOfFiles = split(arrayOfFiles,"\n");
				}else{
					tiffFileDir = slist[j];
					sepline("directory: " + tiffFileDir,3);
					tmpList = getFileList(slist[j]);
					tmpArray = newArray();
					// filter for only TIFF files
					for(i=0; i<tmpList.length; i++){
						testStr = toLowerCase(tmpList[i]);
						if(startsWith(testStr, "recording_")&&(endsWith(testStr, ".tif")||endsWith(testStr, ".tiff"))){
							tmpArray = Array.concat(tmpArray, testStr);
						}
					}
					arrayOfFiles = tmpArray;
				}
				// check we have the correct starting file
				arrayOfFiles = checkCorrectStartFile(arrayOfFiles,"-000.tif");
				// print list of all files to analyze
				printArray(arrayOfFiles);

				// process files, skip if only concatenating
				tmpFileList = processFiles(tiffFileDir,arrayOfFiles,tmpFileDir,oldInputMethod);

				// concatenate the processed files, images need to actually be open for Concatenate to work, hence batch is false
				setBatchMode(false);
				concatSaveDir = concatenateAllFiles(tmpFileDir,tiffFileDir,arrayOfFiles,onlyConcatFiles,tmpFileList);
				setBatchMode(true);

				// perform log operations
				sepline("",2);
				print(getTime()-startTime);
				// save the log for this folder
				selectWindow("Log");
				saveAs("Text", concatSaveDir + "log.txt");
				// clear log file
				print("\\Clear");
				// print the list of folder to analyze for next log file
				printArray(slist);
			}
		}else{
			// get the tiff directory to place concatenated file
			tiffFileDir = slist[0];
			arrayOfFiles = getFileList(tmpFileDir);
			// print list of all files to analyze
			printArray(arrayOfFiles);
			// concatenate the processed files
			setBatchMode(false);
			concatenateAllFiles(tmpFileDir,tiffFileDir,arrayOfFiles, onlyConcatFiles);
			setBatchMode(true);
		}
		sepline('all done!',1);
	}
	function getParameters(){
		// get parameters
		// // get dialog box options
		// List.setList(parameters);
		// dsfactor = List.getValue();
		// ffthp = List.getValue();
		// fftlp = List.getValue();
		// numSessions = List.getValue();
		// SFFT = List.get();
		// HDF = List.get();
		// oldInputMethod = List.get();
		// tmpDir = List.get();
		// tmpDirUseDefault = List.get();
		// onlyConcatFiles = List.get();
	}
	// function makeArrayUnique(array){

	// }
	function checkCorrectStartFile(arrayOfFiles,start){
		if(!endsWith(arrayOfFiles[0],start)){
			lenList = lengthOf(arrayOfFiles)-1;
			lastElement = newArray(arrayOfFiles[lenList]);
			trimList = Array.trim(arrayOfFiles,lenList);
			arrayOfFiles = Array.concat(lastElement, trimList);
			print("first file is: " + arrayOfFiles[0]);
		}
		return arrayOfFiles;
	}
	function printArray(inputArray){
		arrayLen = inputArray.length;
		print("going to analyze the following files");
		for(i=0; i<arrayLen; i++){
			thisFile = inputArray[i];
			print((i+1) + "/" + arrayLen + ": " + thisFile);
		}
	}
	function processFiles(tiffFileDir,arrayOfFiles,tmpFileDir,oldInputMethod){
		//Go through all files in directory in the order listed in movieorder.txt (you will need to create this file)
		//Spatial downsample all files, perform column-row normalization, concatenate together, and save
		//biafra: i moved this outside the above for...loop, no need to redefine on each pass...
		sepline("starting scaling...",1);
		arrayLen = arrayOfFiles.length;
		n = 0;
		tmpFileList = newArray();
		for(i=0; i<arrayLen; i++){
			thisFile = arrayOfFiles[i];
			// showProgress(n++, arrayOfFiles.length);
			if(oldInputMethod == 1){
				path = thisFile;
			}else{
				path = tiffFileDir+thisFile;
			}
			if(i<10){
				savei = "0" + i;
			}else{
				savei = i;
			}
			tmpPath = tmpFileDir + savei + "_normalized_" + thisFile;
			tmpFileList = Array.concat(tmpFileList, tmpPath);
			// skip if file already in tmp directory, crash recovery
			if(File.exists(tmpPath)){
				print("already processed (skipping) file " + (i+1) + "/" + arrayLen + ": " + path);
				print("temp file: " + tmpPath);

			}else{
				print("processing file " + (i+1) + "/" + arrayLen + ": " + path);

				// open image
				// open(path);
				run("TIFF Virtual Stack...","open="+path);
				// rename("new");

				// run FFT (or not)
				if(SFFT != 1){
					bpstr= " filter_large=" + fftlp + " filter_small=" + ffthp + " suppress=None tolerance=5 autoscale saturate process";
					run("Bandpass Filter...",bpstr);
				}

				// scale
				//selectWindow(list[i]);
				run("Scale...", scalestr);

				// save
				selectWindow("new");
				print("saving to: " + tmpPath);
				save(tmpPath);
				// close 'window'
				close();
				close();
			}
		}
		sepline("finished scaling...",0);

		return tmpFileList;
	}

	function concatenateAllFiles(tmpFileDir,tiffFileDir,arrayOfFiles,onlyConcatFiles,tmpFileList){
		// loop over all temporary files and concat one-by-one
		// list = getFileList(tmpFileDir);
		concatenatestr = "title=[concat] ";
		numCat=1;
		arrayLen = arrayOfFiles.length;
		for(i=0; i<arrayLen; i++){
			// showProgress(n++, arrayOfFiles.length);
			// get string for filename and for Concatenate fxn
			thisFile = arrayOfFiles[i];
			if(onlyConcatFiles==0){
				nextImg = tmpFileList[i];
				tmpFile = getEndPathName(tmpFileList[i]);
				imgStr = " image"+ numCat + "=" + tmpFile;
			}else{
				nextImg = tmpFileDir + thisFile;
				imgStr = " image"+ numCat + "=" + thisFile;
			}
			// print("adding file " + (i+1) + " of " + arrayLen + ": " + thisFile);
			print("adding " + (i+1) + "/" + arrayLen + ": " + nextImg);
			concatenatestr = concatenatestr + imgStr;
			// load each temporary image
			open(nextImg);
			// add each loaded image to concat tif file
			if(i!=0){
				// print(concatenatestr);
				run("Concatenate..." , concatenatestr);
				numCat=1;
				concatenatestr = "title=[concat] image1=concat ";
				selectWindow("concat");
			}else if(arrayLen==1){
				rename("concat");
			}
			numCat++;
		}

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

		if(HDF == 0){
			print("concat location: " + pathTiff);
			save(pathTiff);
		} else {
			print("concat location: " + pathhdffin);
			pathhdf=replace(pathhdf, File.separator, "q");
			pathhdf=replace(pathhdf, "q", "qq");
			pathhdf=replace(pathhdf, "q", "\\");
			pathhdffin="save=" + pathhdf + " concatenated_stacks=movie" ;
			//print(pathhdffin);
			run("Save HDF5 File", pathhdffin);
		}

		selectWindow("concat");
		close();

		return concatSaveDir;
	}
	function getEndPathName(path){
		splitPath = split(path,"\\");
		endOfPath = splitPath[splitPath.length-1];
		return endOfPath;
	}
	function sepline(text,seplineBefore){
		if(seplineBefore==1){
			print("-------------------------------------------------");
			print(text);
		}else if(seplineBefore==2){
			print("-------------------------------------------------");
			print("-------------------------------------------------");
		}else if(seplineBefore==3){
			print(text);
		}else{
			print(text);
			print("-------------------------------------------------");
		}

	}
}