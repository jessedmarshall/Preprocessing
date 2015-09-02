// biafra ahanonu
// updated: 2013.09.08 [12:25:25]
// normalizes all images in a stack

// get the means of each stack frame
//run("Plot Z-axis Profile");

// convert to 32-bit so calculations are correct
run("32-bit");
run ("Select None");
// only measure the mean
run("Set Measurements...", "  mean redirect=None decimal=3");
// plot the mean for the entire stack
run("Plot Z-axis Profile");
// get image properties
Stack.getDimensions(width, height, channels, slices, frames);
// loop over each frame in movie and normalize the image values
for(i=1; i<=slices; i++) {
	setSlice(i);
	v = getResult("Mean",i-1);
	run("Divide...", "value=&v");
}
// reset the min-max so all images have the same range
resetMinAndMax();
