// Andrea Lui (October 22, 2007)
// Laurie Burns (June 6, 2010)
// Liz Otto Hamel (*May 1, 2013)
// expanded
// biafra ahanonu
// updated: 2013.08.30 [10:17:20]
// changelog:
// notifies which step it is currently at
// updated: 2013.09.12 [11:35:08] started refactoring code to make easier for later modification
// updated: 2013.09.12 [11:35:23] started implementing command-line input to the script
// updated: 2013.09.12 [19:23:23] script altered so it now should be called run("GCaMP Register Multiple Days Same Target 4",getArgument);
// TODO: refactor code to allow parallelization of several parts in later runs

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

/*
+This plugin allows you to register a batch of imaging files to a single target.
+It will ask for the folders where the raw data is located and make folders to store the motion corrected files, DFOFs, and some temporary files.
+You can load a target file previously written or make one anew. Several preprocessing steps are applied to the target and the source to improve the registration.
+The final output will be 4x downsampled relative to the original and also will have undergone a divisive normalization by a low-pass filtered version of itself, frame by frame.
+To create the DFOFs, a mean is taken of each movie over time, and the mean of the means for each folder is used as an overall "average".
+Every movie in the folder is divided by this "average" to get the DFOF.
+Then the code concatenates the movies that constitute one imaging trial, according to the movies' titles (if you are using something other than the default naming scheme used by Inscopix, you will want to check that this part of the code is finding the appropriate substring).
+The code also writes a downsampled DFOF file that includes all the trials concatenated together.
*/

public class processMiniscopeMovies_1 implements PlugIn {

	public void run(String arg) {

		if (IJ.isMacro() && Macro.getOptions() != null && !Macro.getOptions().trim().isEmpty()) {
		}
		String args = Macro.getOptions().trim();
		IJ.log(args);
		IJ.log("starting plugin");

		// IJ.log(String[] IJ.getArgs());

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

		// choose whether to save the coordinates
		String[] yn = {"Yes","No"};
		// NonBlockingGenericDialog saveCoords = new NonBlockingGenericDialog("Save coordinates?");
		// saveCoords.addMessage("Do you want to save the registration coordinates?");
		// saveCoords.addChoice("Choice: ", yn, "No");
		// saveCoords.showDialog();
		// if (saveCoords.wasCanceled()) return;
		// scyn = saveCoords.getNextChoice();
		scyn = "No";

		// do {
			//--------------------------------------------------------
			//ESTABLISH WORKING DIRECTORIES
			//Choose a directory where the downsampled and normalized tifs are (no other tifs should be there).
			// DirectoryChooser dc = new DirectoryChooser("Select a source directory:");
			// sourcedir.add(dc.getDirectory());
			// if (dc.getDirectory()==null) return;

		String inputDir = args;
		sourcedir.add(inputDir);
		//--------------------------------------------------------
		// Get the file list
		FilenameFilter only = new KeywordExt("", "tif");
		filelist.add(new File((String) sourcedir.get(folderCounter)).list(only));
		String[] fl = (String[]) filelist.get(folderCounter);
		IJ.log(fl[0]);
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
		//--------------------------------------------------------
		//Establish destination directory
		String parent = new File((String) sourcedir.get(folderCounter)).getParentFile().toString();
		String destdirect = parent + File.separator + "MotionCorrected" + File.separator;
		String destdirectNew = parent + File.separator + "MotionCorrected-new" + File.separator;
		File destdirNew = new File(destdirectNew);
		File destdir = new File(destdirect);
		if (destdir.exists()==false) {
			destdir.mkdir();
			destF.add(destdirect);
		}
		else if (destdirNew.exists()==false){
			destdirNew.mkdir();
			destF.add(destdirectNew);
		}
		else {IJ.showMessage("Please clean up your old motion correction folders!"); return;}
		//--------------------------------------------------------
		//Make a new directory for the DFOFs
		String dfofdirect = parent + File.separator + "DFOF" + File.separator;
		File dfofdir = new File(dfofdirect);
		String dfofdirectNew = parent + File.separator + "DFOF-new" + File.separator;
		File dfofdirNew = new File(dfofdirectNew);
		if (dfofdir.exists()==false) {
			dfofdir.mkdir();
			dfofF.add(dfofdirect);
		}
		else if (dfofdirNew.exists()==false){
			dfofdirNew.mkdir();
			dfofF.add(dfofdirectNew);
		}
		else {
			IJ.showMessage("Please clean up your old DFOF folders!");
			return;
		}

		String tempdirect = parent + File.separator + "Temp" + File.separator;
		File tempFolder = new File(tempdirect);
		tempFolder.mkdir();
		tempF.add(tempdirect);
			//--------------------------------------------------------
			// NonBlockingGenericDialog anotherFolder = new NonBlockingGenericDialog("Another?");
			// anotherFolder.addMessage("Do you want to process an additional folder?");
			// anotherFolder.addChoice("Choice: ", yn, "No");
			// anotherFolder.showDialog();
			// if (anotherFolder.wasCanceled()) return;
			// another = anotherFolder.getNextChoice();
			// another = "No";

		folderCounter++;
		// } while (another=="Yes");
		//--------------------------------------------------------
		// this was modified to look for target.tif in ./parentDir/target/target.tif instead of asking the user for input
		IJ.log("getting target file");

		String targetDir = parent + File.separator + "target" + File.separator;
		String targetFile = parent + File.separator + "target" + File.separator + "target.tif";
		File targetDirectory = new File(targetDir);
		if (targetDirectory.exists()==false) {
			targetDirectory.mkdir();
		}

		//Open the 100th slice of the selected file
		ImagePlus targFull = new Opener().openImage(targetFile, 1);
		String targTitle = targFull.getShortTitle();
		targFull.show();

		//Get dimensions
		width=(int) Math.round(targFull.getWidth()/1);
		height=(int) Math.round(targFull.getHeight()/1);

		roi = new Roi(targFull.getProcessor().getRoi());
		if (roi==null) return;

		targFull.hide();
		ImagePlus targFinal = new ImagePlus("Target", targFull.getProcessor().crop());
		targFull.show();

		targetpath=temp+ targTitle + "-target.tif";

		new FileSaver(targFinal).saveAsTiff((String) targetpath);

		targFull.close();
		targFull.flush();

		targFinal.close();
		targFinal.flush();

		IJ.log("found target file and saved!");

		// int slicesTarget = targFull.getNSlices();
		// //Downsample by 4 in height and width dimensions
		// IJ.run(targFull, "Scale...", "x=1.00 y=1.00 z=1.0 width=" + String.valueOf(width) + " height=" + String.valueOf(height) + " depth=" + String.valueOf(slicesTarget)+" interpolation=Bilinear average process create title=Target");
		// targFull.close();
		// targFull.flush();
		// ImagePlus targ = WindowManager.getImage("Target");

		// targ.show();

		//--------------------------------------------------------
		//Loop over directories to register
		for (int folderNo=0; folderNo<folderCounter; folderNo++) {

			IJ.log("starting analysis");

			String[] flCurrent = (String[]) filelist.get(folderNo);

			ImageStack F0s = new ImageStack((int) width, (int) height, flCurrent.length);
			ImageStack mins = new ImageStack((int) width, (int) height, flCurrent.length);

			//BATCH REGISTER TO THE TARGET FILE

			//Main loop over the images in the directory
			for (int z=0; z<flCurrent.length; z++) {
				IJ.log("-------");
				IJ.log("starting analysis");
				//--------------------------------------------------------
				int maxVal;
				int minVal;

				//Show status
				int num = z+1;
				int fNum = folderNo + 1;
				IJ.log("+processing folder " + fNum + " of " + folderCounter + ", image " + num + " of " + flCurrent.length + ".");
				//--------------------------------------------------------
				//Open selected stack
				String path = sourcedir.get(folderNo) + flCurrent[z];
				ImagePlus imOrig = new Opener().openImage(path);
				printTime(startTime);
				IJ.log("+opening:" + path);
				if (imOrig==null) {
					IJ.error("Error opening image.");
					return;
				}
				int slices=imOrig.getNSlices();
				String title = imOrig.getShortTitle();
				//--------------------------------------------------------
				//Downsample by 4 in each dimension
				//IJ.run(imOrig, "Scale...", "x=1.00 y=1.00 z=1.0 width=" + String.valueOf(width) + " height=" + String.valueOf(height) + " depth=" + String.valueOf(slices) + " interpolation=Bilinear average process create title=Source");
				//imOrig.close();
				//imOrig.flush();
				//ImagePlus imSource = WindowManager.getImage("Source");
				//imSource.hide();

				//Do Laurie's image preprocessing

				ImagePlus imSourceDup = new Duplicator().run(imOrig);
				//--------------------------------------------------------
				// Do the mean filtering on the image, slice by slice
				//for (int i=1; i<=slices; i++){
					//IJ.log("Mean filter loop number " + i);
					//new RankFilters().rank(imSourceDup.getImageStack().getProcessor(i),(double) 20,RankFilters.MEAN);
				//}
				printTime(startTime);
				IJ.log("+getting the mean...");
				IJ.run(imSourceDup, "Mean...", "radius=20 stack");

				// Subtract the mean filtered image from the original
				printTime(startTime);
				IJ.log("+subtracting mean-filtered image");
				ImagePlus img;
				dkslts = "Darks";
				if (dkslts=="Darks"){
					img = new ImageCalculator().run("Subtract create 32-bit stack",imSourceDup,imOrig);
				}
				else if (dkslts=="Lights"){
					img = new ImageCalculator().run("Subtract create 32-bit stack",imOrig,imSourceDup);
				}
				else{
					return;
				}
				imOrig.close();
				imOrig.flush();
				imSourceDup.close();
				imSourceDup.flush();
				//--------------------------------------------------------
				// Do the gaussian blur on the image, slice by slice
				printTime(startTime);
				IJ.log("+gaussian blur...");
				for (int i=1; i<=slices; i++){
					new GaussianBlur().blurGaussian(img.getImageStack().getProcessor(i),(double) 2, (double) 2, (double) 0.02);
				}
				//--------------------------------------------------------
				img.getProcessor().setMinAndMax((double) -30, (double) 30);
				// convert image to 8-bit
				new StackConverter(img).convertToGray8();
				//--------------------------------------------------------
				printTime(startTime);
				IJ.log("+cropping stack...");
				img.setRoi(roi);
				Rectangle cropRect = roi.getBounds();
				// make the cropped stack
				ImageStack cropstack = new ImageStack( (int) ((Rectangle) cropRect).getWidth(), (int) ((Rectangle) cropRect).getHeight());

				img.getImageStack().setRoi((Rectangle) cropRect);
				for (int i=1; i<=slices; i++) {
					ImageProcessor ip = img.getImageStack().getProcessor(i);
					ip.setRoi(roi);
					cropstack.addSlice("crop",ip.crop());
				}

				img.close();
				img.flush();

				img.setStack(title,cropstack);
				//--------------------------------------------------------
				//Finished Laurie's preprocessing

				//--------------------------------------------------------
				int depth=img.getBitDepth();
				int cropr = width-1;
				int cropb = height-1;
				img.hide();
				//Loop over slices in the open image
				double[][] allsourcepts=new double[2][slices];
				printTime(startTime);
				IJ.log("+running turboreg...");
				for (int q=1; q<=slices; q++) {
					if ((q % Math.round(slices/20)) == 0) {
						IJ.log("+currently at slice "+q+" of "+slices);
					}
					img.setSlice(q);
					ImagePlus source = new ImagePlus(null, img.getProcessor());

					new FileSaver(source).saveAsTiff(sourcepath);
					//--------------------------------------------------------
					// run Turboreg
					String callstr = "-align -file "+sourcepath+" 0 0 "+cropr+" "+cropb+" -file "+targetpath +" 0 0 "+cropr+" "+cropb+" -translation 0 0 0 0 -hideOutput";
					Object myTurboRegObject = IJ.runPlugIn("TurboReg_", callstr);

					double[][] mySourcePoints=null;
					//get the image from TurboReg
					try {
						Method method = myTurboRegObject.getClass().getMethod("getSourcePoints", (Class<?>[])null);
						mySourcePoints = (double[][])method.invoke(myTurboRegObject, (Object[])null);
					}
					catch (NoSuchMethodException e) {
						e.printStackTrace();
						IJ.error("NoSuchMethodException");
					}
					catch (IllegalAccessException e) {
						e.printStackTrace();
						IJ.error("IllegalAccessException");
					}
					catch (InvocationTargetException e) {
						e.printStackTrace();
						IJ.error("InvocationTargetException");
					}

					allsourcepts[0][q-1]=((int)(Math.rint(mySourcePoints[0][0]*1000)))/1000.0; //x translation of pt (0,0) rounded to 3 dec places
					allsourcepts[1][q-1]=((int)(Math.rint(mySourcePoints[0][1]*1000)))/1000.0; //y translation of pt (0,0) rounded to 3 dec places

					source.close();
					source.flush();
				}
				img.close();
				img.flush();
				//--------------------------------------------------------
				//Save coordinates, if parameter entered was "yes"
				if (scyn == "Yes"){
					try {
						PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(destF.get(folderNo)+title+"_coords.txt")));
						for (int v=0; v<slices; v++) {
							out.println(allsourcepts[0][v]+"\t"+allsourcepts[1][v]);
						}
						out.close();
					}
						catch (IOException e){
						e.printStackTrace();
					}
				}
				//--------------------------------------------------------
				//Open a fresh copy of the image (without processing)
				ImagePlus imFresh = new Opener().openImage(path);
				if (imFresh==null) {
					IJ.error("Error opening image.");
					return;
				}
				//Downsample by 4 in each dimension
				//IJ.run(imFresh, "Scale...", "x=1.00 y=1.00 z=1.0 width=" + width + " height=" + height + " depth=" + String.valueOf(slices) + " interpolation=Bilinear average process create title="+title);
				//imFresh.close();
				//imFresh.flush();
				//ImagePlus imReg = WindowManager.getImage(title);
				//imReg.hide();
				//--------------------------------------------------------
				//Low-pass filter normalization
				printTime(startTime);
				IJ.log("low-pass filtering...");
				ImagePlus lpnimg = new Duplicator().run(imFresh);
				IJ.run(lpnimg, "Bandpass Filter...", "filter_large=10000 filter_small=80 suppress=None tolerance=5 process");
				ImagePlus imgnorm = new ImageCalculator().run("Divide create 32-bit stack", imFresh, lpnimg);
				imFresh.close();
				imFresh.flush();
				lpnimg.close();
				lpnimg.flush();
				//--------------------------------------------------------
				//Normalize each frame by its own mean
				//Analyzer a = new Analyzer(imFresh);
				//a.setRedirectImage(imFresh);
				//a.getResultsTable().reset();
				//a.setMeasurements(Measurements.MEAN);
				//IJ.run(imFresh, "Plot Z-axis Profile", "");
				//double[] ztrend = ResultsTable.getResultsTable().getColumnAsDoubles(ResultsTable.getResultsTable().getColumnIndex("Mean"));
				//new StackConverter(imFresh).convertToGray32();
				//for (int i=1;i<=slices;i++){
					//imFresh.getImageStack().getProcessor(i).multiply(1/ztrend[i-1]);
				//}
				//imFresh.getProcessor().setMinAndMax((double) 0.25, (double) 1.75);
				//new StackConverter(imFresh).convertToGray16();
				//--------------------------------------------------------
				//Register the image to the coords from TurboReg
				printTime(startTime);
				IJ.log("registering image to turboreg coords...");
				for (int k=0; k<slices; k++) {
					imgnorm.setSlice(k+1);
					ImageProcessor origIP = imgnorm.getProcessor().duplicate();
					ImageProcessor newIP=imgnorm.getProcessor().createProcessor(width, height);
					newIP.setValue(0);
					newIP.fill();
					for (int f=0; f<width; f++) {
						for (int g=0; g<height; g++) {
							if ((f+allsourcepts[0][k]>=0)&&(f+allsourcepts[0][k]<=cropr)&&(g+allsourcepts[1][k]>=0)&&(g+allsourcepts[1][k]<=cropb)) {
								double newpix = origIP.getInterpolatedValue(f+allsourcepts[0][k],g+allsourcepts[1][k]);
								newIP.putPixelValue(f,g,newpix);
							}
						}
					}
					imgnorm.getProcessor().insert(newIP, 0, 0);
				}
				//--------------------------------------------------------
				//Save the registered file
				printTime(startTime);
				IJ.log("saving registered file...");
				if (imgnorm.getNSlices()==1)
					new FileSaver(imgnorm).saveAsTiff(destF.get(folderNo)+title+".tif");
				else
					new FileSaver(imgnorm).saveAsTiffStack(destF.get(folderNo)+title+".tif");
				//--------------------------------------------------------
				//Get the average for this image, rename, leave open
				printTime(startTime);
				IJ.log("getting image average...");
				ZProjector zp = new ZProjector(imgnorm);
				zp.setMethod(zp.AVG_METHOD);
				zp.doProjection();
				ImagePlus f0 = zp.getProjection();
				ImageProcessor f0process = f0.getProcessor();
				F0s.setPixels(f0process.getPixels(), z+1);
				f0.flush();
				//--------------------------------------------------------
				//Get the minimum projection for this image, leave open
				printTime(startTime);
				IJ.log("getting minimum for image...");
				zp.setMethod(zp.MIN_METHOD);
				zp.doProjection();
				ImagePlus min = zp.getProjection();
				ImageProcessor minprocess = min.getProcessor();
				mins.setPixels(minprocess.getPixels(), z+1);
				min.flush();
				//--------------------------------------------------------
				imgnorm.close();
				imgnorm.flush();
				allsourcepts=null;
			} //End of loop over images in current directory

			ImagePlus F0sip = new ImagePlus("F0s", F0s);
			ImagePlus minsip = new ImagePlus("Mins", mins);

			//GET DFOFS FOR EACH TRIAL AND A TIME-DOWNSAMPLED MASTER DFOF
			//--------------------------------------------------------
			//Get average of individual averages, which will be the overall F0
			printTime(startTime);
			IJ.log("obtaining F0 (avg of averages)...");
			ZProjector zpF0 = new ZProjector(F0sip);
			zpF0.setMethod(zpF0.AVG_METHOD);
			zpF0.doProjection();
			ImagePlus F0 = zpF0.getProjection();
			F0sip.close();
			F0sip.flush();
			//--------------------------------------------------------
			//Get the minimum projection of the minimum projections, which will yield the minimum common non-zero area
			printTime(startTime);
			IJ.log("obtaining min(common !0 area) or minimum projection of the minimum projections...");
			ZProjector zpmin = new ZProjector(minsip);
			zpmin.setMethod(zpmin.MIN_METHOD);
			zpmin.doProjection();
			ImagePlus Min = zpmin.getProjection();
			minsip.close();
			minsip.flush();

			Min.getProcessor().setThreshold((double)0,(double)0,Min.getProcessor().NO_LUT_UPDATE);
			IJ.run(Min, "Create Selection", "");
			Roi commonRoi = Min.getRoi();

			F0.getProcessor().setValue(1);
			F0.getProcessor().fill(commonRoi);

			new FileSaver(F0).saveAsTiff(tempF.get(folderNo)+"F0" + ".tif");
			new FileSaver(Min).saveAsTiff(tempF.get(folderNo)+"Min" + ".tif");
			//--------------------------------------------------------
			//Loop over images, concatenate images belonging to a common imaging trial, write to black the common outer area, DFOF and save
			printTime(startTime);
			IJ.log("concatenating images...");
			String fullConcat = "";
			int loopCount = 0;
			String firstName = "";
			String tempT = "";
			for (int w=0; w<flCurrent.length; w++){
				String x = flCurrent[w].substring(19, 25);
				int n = 0;
				String toconcat = "";
				for (int i = 0; i<flCurrent.length; i++){
					if (-1 != flCurrent[i].indexOf(x)){
						n = n+1;
						ImagePlus imConcat = new Opener().openImage(destF.get(folderNo) + flCurrent[i]);
						if (n==1) {firstName = imConcat.getShortTitle();}
						toconcat = toconcat + "image_" + n + "=" + flCurrent[i] + " ";
						imConcat.show(); //Image actually has to be open for concatenation to work
						//Write to black the common outer area
						ImageStack imS = imConcat.getStack();
						for (int sl = 1; sl<=imConcat.getNSlices(); sl++){
							ImageProcessor imSl = imS.getProcessor(sl);
							imSl.setValue(1);
							imSl.fill(commonRoi);
						}

					}
				}
				//--------------------------------------------------------
				//Concatenate images belonging to the same trial
				ImagePlus concT;
				if (n==1) {
					concT = WindowManager.getImage(firstName+".tif");
				}
				else {
					IJ.log("The single-trial concatenation string is: " + toconcat);
					IJ.run("Concatenate ", "  title=[Concat Temp] " + toconcat);
					concT = WindowManager.getImage("Concat Temp");
				}

				ImagePlus dfof = new ImageCalculator().run("Divide create 32-bit stack", concT, F0);
				concT.close();
				concT.flush();
				//--------------------------------------------------------
				//Save the DFOF file
				// new FileSaver(dfof).saveAsTiffStack(dfofF.get(folderNo)+firstName+"_DFOF"+".tif");
				loopCount=loopCount+1;
				//--------------------------------------------------------
				//Temporally downsample & close original (leave open downsampled)
				printTime(startTime);
				IJ.log("+downsampling in time...");

				int timeDS = (int) Math.round(dfof.getNSlices()/4);
				tempT = "Temp" + String.valueOf(w) + ".tif";
				IJ.run(dfof, "Scale...", "x=1.0 y=1.0 z=.25 width=" + width + " height=" + height + " depth=" + String.valueOf(timeDS)+" interpolation=Bilinear average process create title=" + tempT);

				dfof.close();
				dfof.flush();
				fullConcat = fullConcat + "image_" + loopCount + "=" + tempT + " ";

				w = w+n-1;
			} //End of loop over images
			//--------------------------------------------------------
			//Concatenate trials to yield a DFOF for the entire day
			ImagePlus full;
			if (loopCount != 1) {
				IJ.run("Concatenate ", "  title=[Full Concat] " + fullConcat);
				full = WindowManager.getImage("Full Concat");
				full.hide();
			}
			else {
				full = WindowManager.getImage(tempT);
			}
			//--------------------------------------------------------
			//Save the concatenated DFOF file
			new FileSaver(full).saveAsTiffStack(dfofF.get(folderNo)+firstName+"_fullSession_DFOF"+".tif");
			full.close();
			full.flush();

			IJ.log("folder " + folderCounter + " completed--motion corrected and DFOF files written.");

		} //End of loop over directories


		IJ.log("-------");
		IJ.log("+no hay mas para hacer.");
		printTime(startTime);
		// exit imagej, returns control back to the command line
		System.exit(0);
	}
	private void printTime(long startTime){
		double estimatedTime = (double) (System.nanoTime() - startTime)/3600000000000L;
		double hrs = (double) Math.floor(estimatedTime);
		double min = (double) Math.floor((estimatedTime - hrs)*60);
		double sec = (double) Math.floor(((estimatedTime - hrs)*60 - min)*60);
		IJ.log(hrs + " hour(s), " + min + " minute(s), and " + sec + " second(s).");
	}
	private void registerTurboReg(){

	}

}
