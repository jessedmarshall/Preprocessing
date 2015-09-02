// biafra ahanonu
// created: 2013.09.12 [19:25:19]
// script goes into each subdirectory of a parent folder, opens up the first tif file there, ask user to select an ROI, then saves the file
// modified starting 2013.06.24
	// 2013.06.25: automated file list, ask the user for session folders (manual option still exists), moved processFiles() (incorrectly nested), renamed variables/re-organized code (readability), changed concat to load files one-by-one and concat that way (speed), and can just concat if fails (avoid re-normalizing).
	// 2013.06.26: filters for  .tiff/.tif files, auto adds backslash to directories, adds directory name to concatenated file, and finds first file if not named -000.
	// 2013.07.05: fix some bugs related to saving files, filters for only 'recording_.*\.tiff' files, so can have snapshots in the same folder sans errors.
	// 2013.07.23: fixed bug where the last item in the list was removed, causing the last imaging file to not be analyzed
	// 2013.08.21 [21:50:32] now save concatenated file to a sub-folder for quicker later processing, also fixed multi-folder bug, now works
	// 2013.09.04 [21:45:55] fixed bug in checkCorrectStartFile() that caused it to NOT move the last file to the beginning
	// updated: 2013.09.09 [14:46:27] added folder number to output
	// updated: 2013.09.11 [12:16:17] script now checks for temp files already processed in the tmp directory in case you had to exit early, check is by filename (which should be unique given it is down to seconds)
	// updated: 2013.09.12 [15:38:10] some cosmetic changes (noting folders) and refactored main loop/script. Script can also now handle directories with only one tiff (doesn't fail on concatenating).

// start the script
main()

function main(){
	// set the temporary directory
	tmpDirDialog = "C:\\tmp\\";

	// create an options dialog box
	Dialog.create("Paramters for image pre-processing");
	// // Dialog.addMessage("First tiff should be *-000.tiff to make sure order is correct.\n");
	// Dialog.addNumber("Downsampling factor:", 0.25);
	// Dialog.addNumber("FFT highpass in pixel:", 5);
	// Dialog.addNumber("FFT lowpass in pixel:", 80);
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

	//
	Dialog.create("Select ROI");
	// display the dialog box
	Dialog.show();
}