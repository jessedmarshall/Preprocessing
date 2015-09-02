// biafra ahanonu
// 2013.11.13 [18:39:11]
// batch saves files as HDF5
//

//changelog
	// 2014.05.13 - deals with opening avi and tiff in a more consistent manner. Fixed path passing to HDF5 saving to also deal with server.

// NOTE FIX SO YOU CAN SPECIFY A DIFFERENT DIRECTORY
// NOTE: 8 bit should be a check

altSaveDir = '';
Dialog.create("batch conversion");
Dialog.addMessage("each trial is saved to its own concat file.\n");
// convert to 8 bit?
Dialog.addCheckbox("convert movie to 8-bit?", false);
// open avi dialog?
Dialog.addCheckbox("open avi dialog?", true);
// is user saving to a network drive? changes options
Dialog.addCheckbox("saving to network drive?", false);
// use alternative save directory?
Dialog.addCheckbox("use alternative save directory?", true);
// alt save directory
Dialog.addString("temporary directory path:",altSaveDir,80);
// display the dialog box
Dialog.show();

checkUse8bit = Dialog.getCheckbox();
checkUseAviDialog = Dialog.getCheckbox();
checkSaveNetworkDrive =
checkUseAltDir = Dialog.getCheckbox();
altSaveDir = Dialog.getString();
if(!endsWith(altSaveDir,"\\")){
	altSaveDir = altSaveDir + "\\";
}

fileList = File.openDialog('select file with list of movie (tiff, avi, etc.) to convert');
listOfFiles = File.openAsString(fileList);
listOfFiles = split(listOfFiles,"\n");
for(i=0; i<listOfFiles.length; i++){
	thisFile = listOfFiles[i];
	if(endsWith(thisFile, 'avi')){
		if(checkUseAviDialog){
			open(thisFile);
		}else{
			//run("AVI...", "select=["+thisFile+"] first=1 last=5");
			run("AVI...", "select=["+thisFile+"]");
		}
	}else if(endsWith(thisFile, 'tiff')||endsWith(thisFile, 'tif')){
		open(thisFile);
		// run("TIFF Virtual Stack...","open="+thisFile);
	}else if(endsWith(thisFile, 'h5')||endsWith(thisFile, 'hdf5')){
		run("Load HDF5 File","open="+thisFile+" 1");
	}
	if(checkUse8bit){
		run("8-bit");
	}
	rename("concat");
	if(checkUseAltDir){
		thisFilename = getTitle();
		newHDF5 = altSaveDir+thisFilename;
		newHDF5 = newHDF5+"_new.h5";
	}else{
		newHDF5 = replace(thisFile, ".tif", ".h5");
		newHDF5 = replace(newHDF5, ".avi", ".h5");
		pathhdffin = "save=" + newHDF5 + " concat=1";
		//pathhdf=replace(pathhdffin , File.separator, "q");
		//pathhdf=replace(pathhdf, "q", "qq");
		//pathhdf=replace(pathhdf, "q", "\\");
		//pathhdf='"'+pathhdf+'"';
	}
	print(pathhdffin);
	run("Save HDF5 File", pathhdffin);
	close();
}


