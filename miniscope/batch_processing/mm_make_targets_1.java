/*
Andrea Lui (October 22, 2007)
Laurie Burns (June 6, 2010)
Liz Otto Hamel (*May 1, 2013)
expanded
biafra ahanonu
updated: 2013.08.30 [10:17:20]
changelog:
+ stripped away all code except the targets portion and refactored a bit to allow just making of targets
+
TODO: refactor code (e.g. original base code hates functions) to allow parallelization of several parts in later runs
*/

import ij.*;
import ij.process.*;
import ij.gui.*;
import ij.measure.*;
import ij.text.*;
import ij.plugin.*;
import ij.plugin.filter.*;
import ij.plugin.frame.*;
import ij.io.*;
import java.awt.*;
import java.io.*;
import javax.swing.*;
import java.lang.reflect.*;
import java.lang.System.*;
import java.util.*;

public class mm_make_targets_1 implements PlugIn {

	public void run(String arg) {

		long startTime = System.nanoTime();

		//Create ArrayLists which will hold items/parameters from the directory-choosing target-making phase and keep them for the later, motion-correcting phase
		ArrayList<String> sourcedir = new ArrayList<String>();
		ArrayList<String[]> filelist = new ArrayList<String[]>();
		ArrayList<String> destF = new ArrayList<String>();
		ArrayList<String> dfofF = new ArrayList<String>();
		ArrayList<String> tempF = new ArrayList<String>();

		String scyn = "";
		String targetpath = "";
		String dkslts = "";
		int width;
		int height;
		Roi roi;
		String tLoadDir = "";

		int folderCounter = 0;

		String another = "";
		final String temp = IJ.getDirectory("temp");
		final String sourcepath=temp+"ROIsource.tif";

		String[] yn = {"Yes","No"};
		// NonBlockingGenericDialog saveCoords = new NonBlockingGenericDialog("Save coordinates?");
		// saveCoords.addMessage("Do you want to save the registration coordinates?");
		// saveCoords.addChoice("Choice: ", yn, "No");
		// saveCoords.showDialog();
		// if (saveCoords.wasCanceled()) return;
		// scyn = saveCoords.getNextChoice();

		do {
			//--------------------------------------------------------
			//ESTABLISH WORKING DIRECTORIES
			//Choose a directory where the downsampled and normalized tifs are (no other tifs should be there).
			DirectoryChooser dc = new DirectoryChooser("Select a source directory:");
			// assume user picked parent directory and add sub-directory onto that.
			String currentChosenDir = dc.getDirectory() + "concat" + File.separator;
			IJ.log(currentChosenDir);
			sourcedir.add(currentChosenDir);
			if (currentChosenDir==null) return;
			//--------------------------------------------------------
			// Get the file list
			FilenameFilter only = new KeywordExt("", "tif");
			filelist.add(new File((String) sourcedir.get(folderCounter)).list(only));
			String[] fl = (String[]) filelist.get(folderCounter);
			if (fl.length==0) {
			IJ.showMessage("No files in this folder!");
			return;
			}

			//Sort file list
			for (int i = 0; i< fl.length; i++){
				int endIndex = fl[i].length()-4;
				fl[i] = fl[i].substring((int)0, (int) endIndex);
			}
			Arrays.sort(fl);
			for (int i = 0; i< fl.length; i++){
				fl[i] = fl[i] + ".tif";
			}


			String parent = new File((String) sourcedir.get(folderCounter)).getParentFile().toString();
			String targetDir = parent + File.separator + "target" + File.separator;
			String targetFile = parent + File.separator + "target" + File.separator + "target.tif";
			File targetDirectory = new File(targetDir);
			if (targetDirectory.exists()==false) {
				targetDirectory.mkdir();
			}
			//--------------------------------------------------------
			NonBlockingGenericDialog anotherFolder = new NonBlockingGenericDialog("Another?");
			anotherFolder.addMessage("Do you want to process an additional folder?");
			anotherFolder.addChoice("Choice: ", yn, "Yes");
			anotherFolder.showDialog();
			if (anotherFolder.wasCanceled()) return;
			another = anotherFolder.getNextChoice();
			folderCounter++;

		} while (another=="Yes");
		for (int folderNo=0; folderNo<folderCounter; folderNo++) {
			// get current directory
			String currentDir = sourcedir.get(folderNo);
			// get parent
			String currentParentDir = new File((String) currentDir).getParentFile().toString();
			// get current target.tif path
			String currentTargetFile = currentParentDir + File.separator + "target" + File.separator + "target.tif";
			// set the default directory
			OpenDialog.setDefaultDirectory(currentDir);
			//--------------------------------------------------------
			// CREATE THE REGISTRATION TARGET FILE

			OpenDialog od = new OpenDialog("Choose the file you want to use to make the target","");
			String tdir = od.getDirectory();
			String tname = od.getFileName();

			//Open the 100th slice of the selected file
			ImagePlus targFull = new Opener().openImage(tdir + tname, 1);
			if (targFull==null) {
				IJ.error("Error opening image.");
				return;
			}

			String targTitle = targFull.getShortTitle();
			targFull.show();

			//Get dimensions
			width=(int) Math.round(targFull.getWidth()/1);
			height=(int) Math.round(targFull.getHeight()/1);
			int slicesTarget = targFull.getNSlices();

			//Downsample by 4 in height and width dimensions
			IJ.run(targFull, "Scale...", "x=1.00 y=1.00 z=1.0 width=" + String.valueOf(width) + " height=" + String.valueOf(height) + " depth=" + String.valueOf(slicesTarget)+" interpolation=Bilinear average process create title=Target");
			targFull.close();
			targFull.flush();
			ImagePlus targ = WindowManager.getImage("Target");

			targ.show();

			//Close this image window
			targ.hide();

			//Duplicate the image
			ImagePlus targDup = new Duplicator().run(targ);

			//Mean filter, radius 20
			new RankFilters().rank(targ.getProcessor(),(double) 20,RankFilters.MEAN);

			//Perform the image subtraction
			ImagePlus targFilt;
			// if (res=="Darks"){
			targFilt = new ImageCalculator().run("Subtract create 32-bit stack",targ,targDup);
			// }
			// else if (res=="Lights"){
			// targFilt = new ImageCalculator().run("Subtract create 32-bit stack",targDup,targ);
			// }
			// else{return;}
			targ.close();
			targ.flush();
			targDup.close();
			targDup.flush();

			//Perform Gaussian blur, radius 2
			new GaussianBlur().blurGaussian(targFilt.getProcessor(),(double) 2, (double) 2, (double) 0.02);

			//Adjust Brightness/Contrast
			targFilt.getProcessor().setMinAndMax((double) -30, (double) 30);

			//Change to 8-bit image
			new ImageConverter(targFilt).convertToGray8();

			//Get user roi
			targFilt.show();
			WaitForUserDialog wfu = new WaitForUserDialog("Please select a region of the image to be used for registration.");
			wfu.show();
			roi = new Roi(targFilt.getProcessor().getRoi());
			if (roi==null) return;

			// DirectoryChooser dct = new DirectoryChooser("Where do you want to save the target?");
			// String tSaveDir = dct.getDirectory();
			new FileSaver(targFilt).saveAsTiff(currentTargetFile);

			targFilt.hide();
			ImagePlus targFinal = new ImagePlus("Target", targFilt.getProcessor().crop());
			targFinal.show();

			targetpath=temp+ targTitle + "-target.tif";

			new FileSaver(targFinal).saveAsTiff((String) targetpath);

			//Clear all the stuff used in creating the target
			targFilt.close();
			targFilt.flush();

			targFinal.close();
			targFinal.flush();

		}
		// save the file list to a log file for later processing
		try {
			// get current directory
			String currentDir = sourcedir.get(0);
			// get parent
			String currentParentDir = new File((String) currentDir).getParentFile().toString();
			// get current target.tif path
			String logFile = currentParentDir + File.separator + "fileList.txt";
			//
			PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(logFile)));
			for (int v=0; v<folderCounter; v++) {
				out.println(sourcedir.get(v));
			}
			out.close();
			IJ.log(logFile);
		}
			catch (IOException e){
			e.printStackTrace();
		}

		IJ.log("-------");
		IJ.log("+no hay mas para hacer.");
		printTime(startTime);
	}
	private void printTime(long startTime){
		double estimatedTime = (double) (System.nanoTime() - startTime)/3600000000000L;
		double hrs = (double) Math.floor(estimatedTime);
		double min = (double) Math.floor((estimatedTime - hrs)*60);
		double sec = (double) Math.floor(((estimatedTime - hrs)*60 - min)*60);
		IJ.log(hrs + " hour(s), " + min + " minute(s), and " + sec + " second(s).");
	}

}
