function [X0, Y0, X1, Y1] = determinelineartrackcoords(animaldir,animalprefix, day)

currentdir = pwd;

%List of days the animal ran on the reward track
cd(animaldir) %Go to animals directory
tmpfiles = dir('*pos*'); %Find position file
load(tmpfiles(1).name)
cmperpixel = pos{end}{end}.cmperpixel;

tmpfiles = dir([animalprefix,'_behav*',num2str(day),'*']); %Find behavior folder for this day
foldername = tmpfiles(1).name; %Assign folder name corresponding to this day
cd([animaldir,filesep,foldername]) %Go to days behavior folder
filenames = dir('*.avi'); %Find all avi files
mov = VideoReader(filenames(1).name);
thisFrame = read(mov,1); %Read in first frame

figure
imshow(thisFrame)
title('Click on one reward port')
[X0,Y0] = ginput(1); %Get first coordinate
hold on
plot(X0,Y0,'r*') %Show user coordinate so clicking is easier
title('Click on the other reward port')
[X1,Y1] = ginput(1); %Get first coordinate
plot(X1,Y1,'r*') %Show user coordinate so clicking is easier
pause(1)
close all          

X0 = X0*cmperpixel; Y0 = Y0*cmperpixel;
X1 = X1*cmperpixel; Y1 = Y1*cmperpixel;

cd(currentdir)
end
