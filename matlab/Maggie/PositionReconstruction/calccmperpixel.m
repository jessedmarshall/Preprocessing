function cmperpixel = calccmperpixel(animaldir,animalprefix,days,varargin)
%CALCCMPERPIXEL This function loads a behavior movie, asks for user input,
%and returns the cmperpixel value to use.
%
%Inputs
%   animaldir: Path to the animals data (Example: /data/A_000/')
%   animalprefix: Animal's name (Example: 'A_000')
%   days: Experimental days to be processed. (Example: [1 2 3])
%
%   Note: This function assumes that all videos wil be in a foder named
%   A_000_behavior_10 where A_000 is the mouse name (can be any length) and
%   10 is the experiment day. This function will write the position data to
%   a file named A_000_pos10.mat in the animaldir folder.
%   The pos structure is organized as a series of nested cells: pos{day}{session}
%   with a field caled data with columns corresponding to time, x position,
%   y position, blank, and velocity. The blank field will be filled with 
%   the linearized position when running lineardayprocess.m
%
%
%Options:
%
% Written by Maggie Carr Larkin, September 2013
%--------------------------------------------------------------------------
%Set default options

%Process options
for i = 1:2:length(varargin)
    val = lower(varargin{i});
    switch val
        otherwise
            disp('Warning: Option is not defined');
    end
end
clear varargin i val

%Identify folders to process
cd(animaldir) %Go to animals directory
foldername = cell(length(days),1); %Pre-allocate
for d = 1:length(days)
    tmpfiles = dir([animalprefix,'_behav*',num2str(days(d)),'*']); %Find behavior folder for this day
    if ~isempty(tmpfiles)
        foldername{d} = tmpfiles(1).name; %Assign folder name corresponding to this day
        clear tmpfiles
    else
        display(['No folder matching day ',num2str(days(d))])
        keyboard
    end
end

%Go through each days folder
for d = 1
    
    %Identify movies
    cd([animaldir,filesep,foldername{d}]) %Go to days behavior folder
    filenames = dir('*.avi'); %Find all avi files
    mov = VideoReader(filenames(1).name); %Movie object
    thisFrame = read(mov,1); %Read in frame
    
    %Calculate cm/pixel if this is the first day
    figure
    reply = ''; %Set default
    while ~strcmpi(reply,'y') %Repeat calibration until the user is happy
        imshow(thisFrame)
        title('Click on two points a known distance apart')
        [X,Y] = ginput(1); %Get first coordinate
        hold on
        plot(X,Y,'r',X,Y,'r*') %Show user coordinate so clicking is easier
        [X(2),Y(2)] = ginput(1); %Get second coordinate
        plot(X,Y,'r',X,Y,'r*') %Show user both coordinates to verify calibration
        title('Calculating cm / pixel...')
        calibration = input('What is this distance in cm?  ');
        text('Position',[mean(X),mean(Y)],'String',num2str(calibration),'FontSize',24,'Color','y');
        reply = input('Are you happy with this calibration? y/n: ', 's');
        clf
    end
    
    cmperpixel = calibration ./ pdist([X(:) Y(:)]); %Caculate cm per pixel
end
