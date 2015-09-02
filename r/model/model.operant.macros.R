# biafra ahanonu
# 2013.02.08
# create med-pc macros for the day
#________________________________________________________
# Set working directory
# setwd("C:/Users/B/Dropbox/biafra/Stanford/Lab/schnitzer/scripts/R/")
#________________________________________________________
# Load libraries and dependencies
# For plotting
library(ggplot2)
# Add time-stamped footnote to graphs
source("view.footnote.R")
# Function to get directory info and create folders
source("helper.getDir.R")
# Set directory information, create appropriate directories
c(data_dir,data_sub_dir,data_main_dir,current_date,analysis_dir):=getDirectoryInfo(dataMainDir="../../data/",dataSubDir="training/macros/",analysisDir="../../analysis/temp/biafra/")
# _________________________________________________
# program name loaded with this set
PROGRAM_NAME = "WORKING_MEM7_JP"
# _________________________________________________
# Setup a hash table to help lookup particular phase's data
phaseHashTableFile = "database.mice.phases.discimination.wm.csv"
# Read in hash file
phaseHashTable = read.table(paste(data_dir,"training/",phaseHashTableFile,sep=""),header=T,sep=",",row.names="phase")
# _________________________________________________
# Ask user for groups and animals
groups = strsplit(winDialogString("Enter group ID, separate by comma","X,Y,Z"),",")[[1]]
miceAnimals = strsplit(winDialogString("Enter mice IDs, separate by comma","1,2,3,4"),",")[[1]]
# Make vector of animal-group pairs
animals=list();for(i in groups){animals[[i]]=paste(i,miceAnimals,sep="")}
# _________________________________________________
# Loop through and ask for phase,
for (group in names(animals)) {
	# Ask user to enter phases, to be take from phaseHashTable
	phases = strsplit(winDialogString(paste("Enter animal phases for group ",group,", separate by comma",sep=""),paste(animals[[group]],sep=",",collapse=",")),",")[[1]]
	# Only proceed if user enters correct input.
	# while(){

	# }
	# Initialize the output data
	phaseHashInfo = c()
	# Add macro code to load the boxes for each animal, auto make filename
	for(mice in as.numeric(miceAnimals)){
		# Load the box
		phaseHashInfo = c(phaseHashInfo,paste("LOAD BOX  ",mice," SUBJ 0 EXPT 0 GROUP 0 PROGRAM ",PROGRAM_NAME,sep=""))
		# Get mouse ID
		fileMiceID = animals[[group]][mice]
		# Correct for alternative mice names
		fileMiceID = ifelse(fileMiceID=="X1", "X1B", fileMiceID)
		fileMiceID = ifelse(fileMiceID=="X2", "X2B", fileMiceID)
		# Load filename for this box-trial
		phaseHashInfo = c(phaseHashInfo,paste("FILENAME BOX  ",mice," ",current_date,"_",fileMiceID,"_",phases[mice],sep=""))

	}
	# Go through each parameter and add box specific changes
	for(mice in as.numeric(miceAnimals)){
		phase = paste("X",phases[mice],sep="")
		phaseHashInfo = c(phaseHashInfo,paste("SET",paste("",row.names(phaseHashTable),"",sep='"'),"VALUE",as.vector(phaseHashTable[[phase]]),"MAINBOX",mice,"BOXES",mice))
	}
	# Add line to start all the boxes
	phaseHashInfo = c(phaseHashInfo,"START BOXES  1 2 3 4")
	# Choose filename to output
	outputFile = paste(data_main_dir,current_date,group,".MAC",sep="")
	# Write the macro to file
 	write(file=outputFile,x=phaseHashInfo)
}