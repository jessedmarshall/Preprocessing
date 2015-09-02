// dfof movies
// biafra ahanonu
// started: 2014.04.12

Dialog.create("dfof parameters");
Dialog.addMessage("select options.\n");
Dialog.addChoice("dfof type", newArray("divide","subtract"));
Dialog.show();
dfofType = Dialog.getChoice();

thisFile = getTitle();
selectWindow(thisFile);
// get F0
run("Z Project...", "projection=[Average Intensity]");
if(dfofType=="subtract"){
	imageCalculator("Subtract create 32-bit stack", thisFile ,"AVG_"+thisFile);
}else if(dfofType=="divide"){
	imageCalculator("Divide create 32-bit stack", thisFile ,"AVG_"+thisFile);
	// subtract 1 to make true dfof
	run("Subtract...", "value=1 stack");
}
rename("dfof");
selectWindow("AVG_"+thisFile);
close();
selectWindow("dfof");
doCommand("Start Animation [\\]");
