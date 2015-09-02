{\rtf1\ansi\ansicpg1252\cocoartf1138\cocoasubrtf510
{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
\margl1440\margr1440\vieww19260\viewh13120\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural

\f0\b\fs24 \cf0 ## Main file:\
## EM_main.m\
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural

\b0 \cf0 \
# Function call \
\pard\pardeftab720
\cf0 [allCellImages, allCellTraces, allCellParams] =...\
    EM_main(imgs, framerate, pixelSize, sqSize, options)\
 \
# General info\
This function will execute the cell-finding algorithm.\
It chunks the field of view and does the estimation on each chunk\
separately, then resolves border conflicts by collapsing cells that\
have similar shapes. After the collapse, it recalculates the most \
likely traces for all cells.\
\
# Inputs:\
movie: the data. should be a 3D matrix, space x space x time. \
       - Should be centered around 1, ie DFOF.\
       - I have only test on lowpass-divisive-normalized movies. Others\
       might work. Need to test.\
       - 20hz and 5hz both seem to work. Need to test.\
       - Spatial downsampling does not significantly speed things up and\
       might be throwing out information. Need to test.\
framerate: in hz. 5hz and 20hz movies both seem to work.\
pixelSize: size of the edge of one pixel, in um. take downsampling into\
	account. \
sqSize: size of the chunk of data that the algorithm will work with at\
	one time. sqSize=30 means the algorithm will run on a 30x30 square chunk.\
	- For each chunk, the data will be tripled in RAM, so if your computer can't\
	handle tripling a 40 x 40 x nFrames single matrix, don't use sqSize=40\
	- Optimal for speed, RAM, and accuracy is about 30-40. Using less than 25\
	will be inaccurate.\
options:\
	- options.suppressOutput - set to 1 to suppress command line output (default is 0)\
   	- options.suppressProgressFig - set to 1 to suppress the figure that\
       	displays progress in the movie\
	- options.icImgs - images of ICA output to use in EM initialization. (optional)\
	- options.icTraces - traces of ICA output to use in EM initialization. (optional)\
   	- options.initWithICsOnly - set to 1 to initialize ONLY with the ICA\
       	results, and not use the initialization based on max val timing\
\
# Outputs:\
allCellImages: images of the estimated shape of each cell. \
	array size: nypixels x nxpixels x total # cells.\
allCellTraces: estimated fluorescence values for all cells.\
	array size: total # cells x # frames.\
allCellParams: parameters of the estimated shape of each cell.\
	array size: total # cells x 5 (x centroid, y centroid, x std dev, y std dev, angle)\
\
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural
\cf0 \
\
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural

\b \cf0 ## Make a movie of the results:\
## makeResultsMovie.m
\b0 \
\
# Function call \
\pard\pardeftab720
\cf0 makeResultsMovie(movie, estParams, estCellTraces,options)\
\
# Inputs\
movie: real data. nypix x nxpix x nFrames\
estParams: parameters estimated by algorithm. nCells x 5 (or 6)\
estCellTraces: estimated fluorescence traces. nCells x nFrames\
\
options:\
-options.writeAVI: Toggle. if on, makes an AVI file with filename specified by aviName\
-options.markCentroids: Toggle. if on, marks the centroids of the estimated cells.\
-options.plotTraces: Toggle. if on, plots the traces of all cells below movies.\
-options.lims: limits for a subregion of movie, [ymin ymax xmin xmax]\
     ie [20 50 40 60] restricts movie to pixels imgs(20:50,40:60,:)\
-options.aviName: filename (string) for writing avi file\
-options.framerate: framerate for writing AVI file\
-options.compareTraces: actual/ROI cell traces, same size as estCellTraces\
\
}