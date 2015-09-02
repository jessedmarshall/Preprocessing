imagej processing scripts
biafra ahanonu
started: 2013.08.05
updated: 2014.01.11 [14:28:15]

batch pre-processing - the TIF route
	installing
	0. miniscope
		+ move the entire folder over to the ~/Plugins folder in the imageJ directory.
	1. ~/batch_pre_processing/registerFiles.ijm
		+ place in the root imageJ /macros folder, this is a dummy function to pass command-line parameters to mm_processMovies_1.
	2. ~/batch_pre_processing/mm_processMovies_1.java
		+ compile the code, it should cause imageJ to exit (this is normal).
		+ The function contains system exit codes that aren't seen unless calling via the command line.
	3. ~/batch_pre_processing/mm_make_targets_1.java
		+ compile, should ask you for a folder, you can exit until the main run
	4. HDF5 plugin
		+ Install http://lmb.informatik.uni-freiburg.de/lmbsoft/imagej_plugins/hdf5.html
	5. Everything
		+ Installing Everything will help speed-up searching for files/making lists
		+ http://www.voidtools.com/

	doing
	1. Inscopix Image Decompressor
		+ Decompress all files for a particular set of experiments/trials into a single folder.
		+ Ideally the name should be recording.*.tif
	2. ~/pre_processing/mm_preprocessing_v7.7.ijm
		+ macro is largely self-explanatory, it will downsample the .tif files separated by trial (e.g. it looks for files in directory with same base recording_DATETIME.*.tif).
	3. ~/batch_pre_processing/mm_make_targets_1.java
		+ run the .class via the Plugins->miniscope->...
		+ will ask for a root folder containing ~/concat folder where the concatenated tifs are stored
		+ select 'No' when it asks you to continue to proceed to choosing regions to turboreg
		+ open the concat files you want to turboreg to in each folder, select region and click dialog
		+ repeat for all folders
		+ function creates ~/target in each root folder where the target.tif is located, DO NOT change the name, as mm_processMovies_1.java looks for this (and skips that folder if it can't find it)
	4. ~/batch_pre_processing/registerAndDfofMovies.bat
		+ create a text file (easiest to do in a ~/analyze subdirectory of the miniscope folder) containing paths (one per line) to ~/concat folder for each trial
		+ open the command-line (Win+R, type 'cmd') and cd to the directory containing registerAndDfofMovies.bat, run it
		+ when it asks for the location of the paths text file, input it (relative paths also work)
		+ it will pass each path to registerFiles.ijm, which passes them to mm_processMovies_1.java
		+ mm_processMovies_1.java will run a modified version of Liz/Maggie's pre-processing code, any errors will cause it to exit and the batch program will proceed to the next folder
	5. ~/batch_pre_processing/mm_batch_saveHDF5.ijm
		+ create a list that points to the individual movies
		+

tracking
	1. mm_tracking.ijm
		+
	2. removing bad objs
		+ assuming one mouse per tracking file, each table needs to be factored by Slice and the largest obj in that slice kept.
