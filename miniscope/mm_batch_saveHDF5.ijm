// biafra ahanonu
// 2013.11.13 [18:39:11]
// batch saves files as HDF5

// fileList = 'A:\p97.txt'
fileList = File.openDialog('select file with list of .tiff to convert');
listOfFiles = File.openAsString(fileList);
listOfFiles = split(listOfFiles,"\n");
for(i=0; i<listOfFiles.length; i++){
	thisFile = listOfFiles[i];
	// open(thisFile);
	run("TIFF Virtual Stack...","open="+thisFile);
	rename("concat");
	// t = getTitle();
	newHDF5 = replace(thisFile, ".tif", ".h5");
	pathhdffin = "save=" + newHDF5 + " concat=1";
	pathhdf=replace(pathhdffin , File.separator, "q");
	pathhdf=replace(pathhdf, "q", "qq");
	pathhdf=replace(pathhdf, "q", "\\");
	print(pathhdf);
	run("Save HDF5 File", pathhdf);
	close();
}
