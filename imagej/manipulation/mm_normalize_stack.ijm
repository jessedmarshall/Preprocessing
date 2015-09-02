// biafra ahanonu
// updated: 2013.09.08 [12:25:25]
// normalizes all images in a stack

// changelog
	// 2014.02.13 - fixed problem

// get the means of each stack frame
//run("Plot Z-axis Profile");

// get stackID
stackID = getTitle();
print("normalizing...");
// this normalizes each stack by it's own mean then re-scales it. this allows absolute thresholding across all stacks.
selectWindow(stackID);
// convert to 32-bit so calculations are correct
// run("32-bit");
run ("Select None");
// only measure the mean
run("Set Measurements...", "  mean redirect=None decimal=3");
// plot the mean for the entire stack
run("Plot Z-axis Profile");
// get image properties
selectWindow(stackID);
Stack.getDimensions(width, height, channels, slices, frames);
// loop over each frame in movie and normalize the image values
selectWindow(stackID);
print(slices);
for(i=1; i<=slices; i++) {
	setSlice(i);
	v = getResult("Mean",i-1);
	// print(v);
	run("Subtract...", "value=&v");
}
// reset the min-max so all images have the same range
resetMinAndMax();