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

//This plugin is useful when the output of "GCaMP_Register_Multiple_Days_Same_Target" is no good. We discovered that when this registration
//didn't work, it was often because the FOV had moved too far. Thus, this code registers each movie to its own target, and registers each target to 
//a "common" target. The overall translation is applied to the movie. The code will ask for the folders where the raw data is located
//and make folders to store the motion corrected files, DFOFs, and some temporary files. You can load a target file previously 
//written or make one anew. Several preprocessing steps are applied to the target and the source to improve the registration.
//The final output will be 4x downsampled relative to the original and also will have undergone a divisive normalization by a low-pass
//filtered version of itself, frame by frame. To create the DFOFs, a mean is taken of each movie over time, and the mean of the means for each folder
//is used as an overall "average". Every movie in the folder is divided by this "average" to get the DFOF. Then the code concatenates the
//movies that constitute one imaging trial, according to the movies' titles (if you are using something other than the default naming scheme
//used by Inscopix, you will want to check that this part of the code is finding the appropriate substring). The code also writes a downsampled DFOF
//file that includes all the trials concatenated together. 


//Written by Liz Otto Hamel (May 1, 2013), as an expansion upon previous code written by Laurie Burns (June 6, 2010) and Andrea Lui (October 22, 2007).

public class GCaMP_Redo_Registration implements PlugIn {

	public void run(String arg) {	

		long startTime = System.nanoTime();

		//Create ArrayLists which will hold items/parameters from the directory-choosing target-making phase and keep them for the later, motion-correcting phase
		ArrayList<String> sourcedir = new ArrayList<String>();

		ArrayList<String[]> filelist = new ArrayList<String[]>();
		ArrayList<String> targetpath = new ArrayList<String>();
		ArrayList<String> destF = new ArrayList<String>();
		ArrayList<String> dfofF = new ArrayList<String>();
		ArrayList<String> tempF = new ArrayList<String>();
		ArrayList<String> dkslts = new ArrayList<String>();
		ArrayList<Rectangle> cropRect = new ArrayList<Rectangle>();
		ArrayList<Integer> width = new ArrayList<Integer>();
		ArrayList<Integer> height = new ArrayList<Integer>();

		int folderCounter = 0;

		String[] yn = {"Yes", "No"};
		String another = "";
		final String temp = IJ.getDirectory("temp");
		final String sourcepath=temp+"ROIsource.tif";
		String targTitle;

		do {
			//ESTABLISH WORKING DIRECTORIES	
			//Choose a directory where the downsampled and normalized tifs are (no other tifs should be there).
			DirectoryChooser dc = new DirectoryChooser("Select the source directory:");
			sourcedir.add(dc.getDirectory());
			if (dc.getDirectory()==null) return;

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
			else {IJ.showMessage("Please clean up your old DFOF folders!"); return;}

			String tempdirect = parent + File.separator + "Temp" + File.separator;
			File tempFolder = new File(tempdirect);
			tempFolder.mkdir();
			tempF.add(tempdirect);

			// CREATE THE REGISTRATION TARGET FILE

			//Get the first file in the list, open it
			String targetPath = sourcedir.get(folderCounter) + fl[0];
			ImagePlus targFull = new Opener().openImage(targetPath, 100);
			if (targFull==null) {
				IJ.error("Error opening image.");
				return;
			}

			targTitle = targFull.getShortTitle();
			targFull.show();

			//Get dimensions
			width.add((int) Math.round(targFull.getWidth()/1));
			height.add((int) Math.round(targFull.getHeight()/1));
			int slicesTarget = targFull.getNSlices();

			//Downsample by 4 in height and width dimensions
			IJ.run(targFull, "Scale...", "x=1.00 y=1.00 z=1.0 width=" + String.valueOf(width.get(folderCounter)) + " height=" + String.valueOf(height.get(folderCounter)) + " depth=" + String.valueOf(slicesTarget)+" interpolation=Bilinear average process create title=Target");
			targFull.close();
			targFull.flush();
			ImagePlus targ = WindowManager.getImage("Target");
	
			targ.show();	

			//Create a dialog that asks whether the registration should be based on dark features (e.g. blood vessels) or light features (e.g. visible/filled cells)
			String[] choices = {"Darks", "Lights"};
			NonBlockingGenericDialog dksOrLts = new NonBlockingGenericDialog("Darks or lights?");
			dksOrLts.addMessage("Please indicate whether the registration should be based on\ndark (e.g. blood vessels) or light features (e.g. visible/filled cells)?");
			dksOrLts.addChoice("Choice: ", choices, "Darks");
			dksOrLts.showDialog();
			if (dksOrLts.wasCanceled()) return;
			String res = dksOrLts.getNextChoice();
			dkslts.add(res);	

			//Close this image window
			targ.hide();

			//Duplicate the image
			ImagePlus targDup = new Duplicator().run(targ);

			//Mean filter, radius 20
			new RankFilters().rank(targ.getProcessor(),(double) 20,RankFilters.MEAN);	
			//Perform the image subtraction
			ImagePlus targFilt;
			if (res=="Darks"){
			targFilt = new ImageCalculator().run("Subtract create 32-bit stack",targ,targDup);
			}
			else if (res=="Lights"){
			targFilt = new ImageCalculator().run("Subtract create 32-bit stack",targDup,targ);
			}
			else{return;}
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
			Rectangle r = targFilt.getProcessor().getRoi();
			if (r==null) return;
			cropRect.add(r);
			targFilt.hide();
			ImagePlus targFinal = new ImagePlus("Target", targFilt.getProcessor().crop());
			targFinal.show();

			//Clear all the stuff used in creating the target
			targFilt.close();
			targFilt.flush();

			targetpath.add(temp+ targTitle + "-target.tif");

			new FileSaver(targFinal).saveAsTiff((String) targetpath.get(folderCounter));
			targFinal.close();
			targFinal.flush();

			NonBlockingGenericDialog anotherFolder = new NonBlockingGenericDialog("Another?");
			anotherFolder.addMessage("Do you want to process an additional folder?");
			anotherFolder.addChoice("Choice: ", yn, "No");
			anotherFolder.showDialog();
			if (anotherFolder.wasCanceled()) return;
			another = anotherFolder.getNextChoice();

			folderCounter++;

		} while (another=="Yes");

		//CREATE COMMON REGISTRATION TARGET FILE
			
		//Use a dialog to determine which file to create the common target from
		OpenDialog od = new OpenDialog("Choose the file you want to use to make the common target","");
		String ctdir = od.getDirectory();
		String ctname = od.getFileName();
			
		ImagePlus targFull = new Opener().openImage(ctdir + ctname, 100);
		if (targFull==null) {
			IJ.error("Error opening image.");
			return;
		}

		String ctargTitle = targFull.getShortTitle();

		//Get dimensions
		int ctwidth = Math.round(targFull.getWidth()/4);
		int ctheight = Math.round(targFull.getHeight()/4);
		int slicesTarget = targFull.getNSlices();

		//Downsample by 4 in height and width dimensions
		IJ.run(targFull, "Scale...", "x=1.00 y=1.00 z=1.0 width=" + String.valueOf(ctwidth) + " height=" + String.valueOf(ctheight) + " depth=" + String.valueOf(slicesTarget)+" interpolation=Bilinear average process create title=Target");
		targFull.close();
		targFull.flush();
		ImagePlus targ = WindowManager.getImage("Target");

		//Close this image window
		targ.hide();

		//Duplicate the image
		ImagePlus targDup = new Duplicator().run(targ);

		//Mean filter, radius 20
		new RankFilters().rank(targ.getProcessor(),(double) 20,RankFilters.MEAN);	
		//Perform the image subtraction, create a copy for each case (highlight darks or lights)
		ImagePlus targFiltDks;
		ImagePlus targFiltLts;

		targFiltDks = new ImageCalculator().run("Subtract create 32-bit stack",targ,targDup);

		targFiltLts = new ImageCalculator().run("Subtract create 32-bit stack",targDup,targ);

		targ.close();
		targ.flush();
		targDup.close(); 
		targDup.flush();		

		//Perform Gaussian blur, radius 2
		new GaussianBlur().blurGaussian(targFiltDks.getProcessor(),(double) 2, (double) 2, (double) 0.02);
		new GaussianBlur().blurGaussian(targFiltLts.getProcessor(),(double) 2, (double) 2, (double) 0.02);

		//Adjust Brightness/Contrast
		targFiltDks.getProcessor().setMinAndMax((double) -30, (double) 30);
		targFiltLts.getProcessor().setMinAndMax((double) -30, (double) 30);

		//Change to 8-bit image
		new ImageConverter(targFiltDks).convertToGray8();
		new ImageConverter(targFiltLts).convertToGray8();

		String ctargetpathdks = temp+ targTitle + "-ctargetdks.tif";
		String ctargetpathlts = temp+ targTitle + "-ctargetlts.tif";

		new FileSaver(targFiltDks).saveAsTiff((String) ctargetpathdks);
		new FileSaver(targFiltLts).saveAsTiff((String) ctargetpathlts);

		//Clear all the stuff used in creating the target
		targFiltDks.close(); targFiltLts.close();
		targFiltDks.flush(); targFiltDks.close();

		//Loop over directories to register
		for (int folderNo=0; folderNo<folderCounter; folderNo++) {

			String[] flCurrent = (String[]) filelist.get(folderNo);

			ImageStack F0s = new ImageStack((int) width.get(folderNo), (int) height.get(folderNo), flCurrent.length);
			ImageStack mins = new ImageStack((int) width.get(folderNo), (int) height.get(folderNo), flCurrent.length);


			//REGISTER TARGET TO COMMON TARGET

			int cropr = width.get(folderNo)-1;
			int cropb = height.get(folderNo)-1;

			//Register target to common target
			double[] alltargpts=new double[2];

			String ctargetpath;

			if (dkslts.get(folderNo)=="Darks"){
				ctargetpath=ctargetpathdks;
			}
			else if (dkslts.get(folderNo)=="Lights"){
				ctargetpath=ctargetpathlts;					}
			else{return;}

			ImagePlus target = new Opener().openImage(ctargetpath);
			target.setRoi((Rectangle) cropRect.get(folderNo));
			ImageProcessor tcropIP = target.getProcessor().crop();
			ImagePlus targetCrop = new ImagePlus("targetCrop", tcropIP);

			targetCrop.show();

			String callstr = "-align -file "+targetpath.get(folderNo)+" 0 0 "+cropr+" "+cropb+" -window targetCrop 0 0 "+cropr+" "+cropb+" -translation 0 0 0 0 -hideOutput";
			Object myTurboRegObject = IJ.runPlugIn("TurboReg_", callstr);

			double[][] myTargPoints=null;
			//get the image from TurboReg
			try {
				Method method = myTurboRegObject.getClass().getMethod("getSourcePoints", (Class<?>[])null);
				myTargPoints = (double[][])method.invoke(myTurboRegObject, (Object[])null);
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

			targetCrop.hide();

			alltargpts[0]=((int)(Math.rint(myTargPoints[0][0]*1000)))/1000.0; //x translation of pt (0,0) rounded to 3 dec places
			alltargpts[1]=((int)(Math.rint(myTargPoints[0][1]*1000)))/1000.0; //y translation of pt (0,0) rounded to 3 dec places


			//BATCH REGISTER TO THE TARGET FILE

			//Main loop over the images in the directory
			for (int z=0; z<flCurrent.length; z++) {

				//Show status
				int num = z+1;
				int fNum = folderNo + 1;
				IJ.log("Processing folder " + fNum + " of " + folderCounter + ", image " + num + " of " + flCurrent.length);	

				//Open selected stack
				String path = sourcedir.get(folderNo) + flCurrent[z];
				ImagePlus imOrig = new Opener().openImage(path);
				if (imOrig==null) {
					IJ.error("Error opening image.");
					return;
				}

				int slices=imOrig.getNSlices();
				String originalTitle = imOrig.getShortTitle();

				//int widthOrig = imOrig.getWidth();
				//int heightOrig = imOrig.getHeight();
				//int width = (int) Math.round(widthOrig/4);
				//int height = (int) Math.round(heightOrig/4);

				//Downsample by 4 in each dimension
				//IJ.run(imOrig, "Scale...", "x=.25 y=.25 z=1.0 width=" + String.valueOf(width.get(folderNo)) + " height=" + String.valueOf(height.get(folderNo)) + " depth=" + String.valueOf(slices) + " interpolation=Bilinear average process create title=Source");
				//imOrig.close();
				//imOrig.flush();
				//ImagePlus imSource = WindowManager.getImage("Source");
				//imSource.hide();

				//Do Laurie's image preprocessing
				
				ImagePlus imSourceDup = new Duplicator().run(imOrig);
				
				IJ.run(imSourceDup, "Mean...", "radius=20 stack");

				// Subtract the mean filtered image from the original
				ImagePlus img;
				if (dkslts.get(folderNo)=="Darks"){
				img = new ImageCalculator().run("Subtract create 32-bit stack",imSourceDup,imOrig);
				}
				else if (dkslts.get(folderNo)=="Lights"){
				img = new ImageCalculator().run("Subtract create 32-bit stack",imOrig,imSourceDup);
				}
				else{return;}
				imOrig.close();
				imOrig.flush();
				imSourceDup.close();
				imSourceDup.flush();
				
				// Do the gaussian blur on the image, slice by slice
				for (int i=1; i<=slices; i++){
					new GaussianBlur().blurGaussian(img.getImageStack().getProcessor(i),(double) 2, (double) 2, (double) 0.02);
				}
 
				img.getProcessor().setMinAndMax((double) -30, (double) 30);

				new StackConverter(img).convertToGray8();		

				// get the rectangle of the roi
				Roi roi = new Roi((Rectangle) cropRect.get(folderNo));
				img.setRoi(roi);

				// make the cropped stack
				ImageStack cropstack = new ImageStack( (int) ((Rectangle) cropRect.get(folderNo)).getWidth(), (int) ((Rectangle) cropRect.get(folderNo)).getHeight());

				img.getImageStack().setRoi((Rectangle) cropRect.get(folderNo));
				for (int i=1; i<=slices; i++) {
					ImageProcessor ip = img.getImageStack().getProcessor(i);
					ip.setRoi(roi);
					cropstack.addSlice("crop",ip.crop());
				}

				img.close();
				img.flush();
				
				img.setStack(originalTitle,cropstack);		
				
				//Finished Laurie's preprocessing
		
				int depth=img.getBitDepth();

				cropr = width.get(folderNo)-1;
				cropb = height.get(folderNo)-1;
				
				img.hide();

				//Loop over slices in the open image
				double[][] allsourcepts=new double[2][slices];
				for (int q=1; q<=slices; q++) {
					img.setSlice(q);
					ImagePlus source = new ImagePlus(null, img.getProcessor());

					new FileSaver(source).saveAsTiff(sourcepath);

					callstr = "-align -file "+sourcepath+" 0 0 "+cropr+" "+cropb+" -file "+targetpath.get(folderNo) +" 0 0 "+cropr+" "+cropb+" -translation 0 0 0 0 -hideOutput";
					myTurboRegObject = IJ.runPlugIn("TurboReg_", callstr);

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



				//OPEN A FRESH COPY OF THE IMAGE (WITHOUT PROCESSING)
				ImagePlus imFresh = new Opener().openImage(path);
				if (imFresh==null) {
					IJ.error("Error opening image.");
					return;
				}

				String title = imFresh.getShortTitle();

				//Downsample by 4 in each dimension
				//IJ.run(imFresh, "Scale...", "x=.25 y=.25 z=1.0 width=" + width.get(folderNo) + " height=" + height.get(folderNo) + " depth=" + String.valueOf(slices) + " interpolation=Bilinear average process create title="+originalTitle);
				//imFresh.close();
				//imFresh.flush();
				//ImagePlus imReg = WindowManager.getImage(originalTitle);
				//imReg.hide();
				
				//Low-pass filter normalization
				ImagePlus lpnimg = new Duplicator().run(imFresh);
				IJ.run(lpnimg, "Bandpass Filter...", "filter_large=10000 filter_small=80 suppress=None tolerance=5 process");
				ImagePlus imgnorm = new ImageCalculator().run("Divide create 32-bit stack", imFresh, lpnimg);
				imFresh.close();
				imFresh.flush();
				lpnimg.close();
				lpnimg.flush();	

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
				//imFresh.getProcessor().setMinAndMax((double) 0.75, (double) 1.25);
				//new StackConverter(imFresh).convertToGray16();

				//Register the image to the coords from TurboReg
				for (int k=0; k<slices; k++) {
					imgnorm.setSlice(k+1);
					ImageProcessor origIP = imgnorm.getProcessor().duplicate();
					ImageProcessor newIP=imgnorm.getProcessor().createProcessor(width.get(folderNo), height.get(folderNo));
					newIP.setValue(0);
					newIP.fill();
					for (int f=0; f<width.get(folderNo); f++) {
						for (int g=0; g<height.get(folderNo); g++) {
							if ((f+allsourcepts[0][k]+alltargpts[0]>=0)&&(f+allsourcepts[0][k]+alltargpts[0]<=cropr)&&(g+allsourcepts[1][k]+alltargpts[1]>=0)&&(g+allsourcepts[1][k]+alltargpts[1]<=cropb)) {
								double newpix = origIP.getInterpolatedValue(f+allsourcepts[0][k]+alltargpts[0],g+allsourcepts[1][k]+alltargpts[1]);
								newIP.putPixelValue(f,g,newpix);
							}
						}
					}
					imgnorm.getProcessor().insert(newIP, 0, 0);
				}

				//Save the registered file
				if (imgnorm.getNSlices()==1)
					new FileSaver(imgnorm).saveAsTiff(destF.get(folderNo)+title+".tif");
				else
					new FileSaver(imgnorm).saveAsTiffStack(destF.get(folderNo)+title+".tif");

				//Get the average for this image, rename, leave open
				ZProjector zp = new ZProjector(imgnorm);
				zp.setMethod(zp.AVG_METHOD);
				zp.doProjection();
				ImagePlus f0 = zp.getProjection();
				ImageProcessor f0process = f0.getProcessor();
				F0s.setPixels(f0process.getPixels(), z+1);
				f0.flush();

				//Get the minimum projection for this image, leave open
				zp.setMethod(zp.MIN_METHOD);
				zp.doProjection();
				ImagePlus min = zp.getProjection();
				ImageProcessor minprocess = min.getProcessor();
				mins.setPixels(minprocess.getPixels(), z+1);
				min.flush();

				imgnorm.close();
				imgnorm.flush();
				allsourcepts=null;

			} //End of loop over images in current directory

			ImagePlus F0sip = new ImagePlus("F0s", F0s);
			ImagePlus minsip = new ImagePlus("Mins", mins);	

			//GET DFOFS FOR EACH TRIAL AND A TIME-DOWNSAMPLED MASTER DFOF

			//Get average of individual averages, which will be the overall F0
			ZProjector zpF0 = new ZProjector(F0sip);
			zpF0.setMethod(zpF0.AVG_METHOD);
			zpF0.doProjection();
			ImagePlus F0 = zpF0.getProjection();
			F0sip.close();
			F0sip.flush();

			//Get the minimum projection of the minimum projections, which will yield the minimum common non-zero area
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


			//Loop over images
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

				//Save the DFOF file
				new FileSaver(dfof).saveAsTiffStack(dfofF.get(folderNo)+firstName+"_DFOF"+".tif");
				loopCount=loopCount+1;

				//Temporally downsample & close original (leave open downsampled)
			
				int timeDS = (int) Math.round(dfof.getNSlices()/4);
				tempT = "Temp" + String.valueOf(w) + ".tif";
				IJ.run(dfof, "Scale...", "x=1.0 y=1.0 z=.25 width=" + width.get(folderNo) + " height=" + height.get(folderNo) + " depth=" + String.valueOf(timeDS)+" interpolation=Bilinear average process create title=" + tempT);		

				dfof.close();
				dfof.flush();
				fullConcat = fullConcat + "image_" + loopCount + "=" + tempT + " ";

				w = w+n-1;
			} //End of loop over images

			ImagePlus full;
			if (loopCount != 1) {
				IJ.run("Concatenate ", "  title=[Full Concat] " + fullConcat);
				full = WindowManager.getImage("Full Concat");
				full.hide();
			}
			else {
				full = WindowManager.getImage(tempT);
			}

			//Save the concatenated DFOF file
			new FileSaver(full).saveAsTiffStack(dfofF.get(folderNo)+"fullSession_DFOF"+".tif");
			full.close();
			full.flush();

			IJ.log("Motion correction completed! DFOF files written! Ready for PCA/ICA!");

		} //End of loop over directories

		double estimatedTime = (double) (System.nanoTime() - startTime)/3600000000000L;

		double hrs = (double) Math.floor(estimatedTime);

		double min = (double) Math.floor((estimatedTime - hrs)*60);

		double sec = (double) Math.floor(((estimatedTime - hrs)*60 - min)*60);

		IJ.log("Totally done!");
		IJ.log("This run took " + hrs + " hour(s), " + min + " minute(s), and " + sec + " second(s).");

	}

}
