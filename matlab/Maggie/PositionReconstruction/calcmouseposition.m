function calcmouseposition(animaldir,animalprefix,days,varargin)
%CALCMOUSEPOSITION This function loads behavior movies, tracks the position
%of the mouse based on simple thresholding, and creates and saves to a pos
%structure.
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
%   To ensure the same calibration across multiple days of an experiment,
%   only run for days with the same behavior at once (i.e. all Fear
%   Conditioning days together and all Reward track days together). A
%   single calibration will be applied to all movies.
%
%Options:
%   FramesPerSecond: FramesPerSecond of the movie. Default = 19.99.
%   BackgroundLength: The number of frames used to estimate the background.
%       Default = 500.
%   InteriorMask: Determines whether an interior mask needs to be applied
%       to define the environment (such as when the track is a circle). 
%       Default = 0.
%   CmPerPixel: Applies the value to transform pixel units to cm. Default
%       is to calculate cmperpixel using the first movie. Useful when
%       1) You've already processed some days and want to use the same 
%           value on newly acquired / processed data.
%       2) You want to use a different environment mask on each day of an
%           experiment with the same camera settings (sleep experiment)
%           track experiments) or 
%
% Written by Maggie Carr Larkin, September 2013
%--------------------------------------------------------------------------


%Set default options
fps = 19.99; %Initialize frames per second
background_length = 500; %Initialize number of frames used to estimate the background
environment_interior = 0; %Does this environment have an interior (i.e. circle tracks)?
cmperpixel = []; %Initialize cmperpixel
use_background = 1; %Initialize whether to use a background image or not
nstd = 3; %Initialize threshold to use for detecting mouse vs. background

%Process options
for i = 1:2:length(varargin)
    val = lower(varargin{i});
    switch val
        case 'framespersecond'
            fps = varargin{i+1};
        case 'interiormask'
            environment_interior = varargin{i+1};
        case 'backgroundlength'
            background_length = varargin{i+1};
        case 'nstd'
            nstd = varargin{i+1};
        case 'cmperpixel'
            cmperpixel = varargin{i+1};
        case 'background'
            use_background = varargin{i+1};
        otherwise
            disp('Warning: Option is not defined');
    end
end
clear varargin i val
if ~isempty(cmperpixel)
    MouseSize = 7./cmperpixel; %Mice are ~7cm
    MouseSizeDisk = strel('disk',round(MouseSize));
end

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
for d = 1:length(days)
    
    %Identify movies
    cd([animaldir,filesep,foldername{d}]) %Go to days behavior folder
    filenames = dir('*.avi'); %Find all avi files

    %Sort movies by time
    movietime = zeros(length(filenames),1); %Pre-allocate
    for i = 1:length(filenames)
        movietime(i) = filenames(i).datenum; %Assign the datenum (which orders by time file was created)
    end
    [~, movieorder] = sort(movietime); clear movietime %Sort according to when the file was created. Work here if not all epochs have movies
    
    pos = cell(days(d),1); pos{days(d)} = cell(length(movieorder),1); %Pre-allocate pos structure for this day
    
    %Calculate background image from first movie of the day
    if d==1 && use_background
        mov = VideoReader(filenames(movieorder==1).name); %Movie object
        background = zeros(mov.Height,mov.Width,min(background_length,mov.NumberOfFrames)); %Pre-allocate background image
        backgroundframes = ceil(mov.NumberOfFrames*rand(min(background_length,mov.NumberOfFrames),1));
        for i = 1:length(backgroundframes)
            thisFrame = read(mov,backgroundframes(i)); %Read in background_length number of frames
            background(:,:,i) = thisFrame(:,:,1); %convert from RGB. With guppy camera, all three channels are the same
        end
        background = median(background,3); %The median is more accurate than the mean since it ignores rare events like the mouse or cable occupying a pixel
        clear backgroundframes
    else
        mov = VideoReader(filenames(movieorder==1).name); %Movie object
        thisFrame = read(mov,1);
    end
    
    %Calculate cm/pixel if this is the first day & user did not supply cmperpixel
    if d == 1 && isempty(cmperpixel)
        figure(1);
        hold off
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
        end
        cmperpixel = calibration ./ pdist([X(:) Y(:)]); %Caculate cm per pixel
        MouseSize = 7./cmperpixel; %Mice are ~7cm
        MouseSizeDisk = strel('disk',round(MouseSize));
    end
    if d == 1
        reply = ''; %Set default answer
        figure(1); hold off;
        imshow(thisFrame)
        while ~strcmpi(reply,'y') %Repeat identification until the user is happy
            title('Define the exterior border of the arena')
            EnvironmentMask = createMask(impoly);
            if environment_interior
                title('Define the interior border of the arena')
                EnvironmentMaskInterior = createMask(impoly);
                EnvironmentMask = EnvironmentMask-EnvironmentMaskInterior;
            end
            reply = input('Are you happy with the current selection? y/n: ', 's');
        end        
        clear mov thisFrame i calibration X Y reply
    end
    
    display(['Processing movies from day ', num2str(days(d))])

    for behavioraltrial = 1:length(movieorder)
        %Load movies frame by frame, subtract background, identify darkest spot
        mov = VideoReader(filenames(movieorder==behavioraltrial).name);
        tmpposition = nan(mov.NumberOfFrames,2);
        for i = 1:mov.NumberOfFrames
            thisFrame = read(mov,i);
            if use_background
                thresholdedImage = double(thisFrame(:,:,1))-background;
        
                thresholdedImage(~EnvironmentMask) = median(thresholdedImage(:)); %Restrict location to the EnvironmentMask
                threshold = mean(thresholdedImage(:))-nstd*std(thresholdedImage(:));
            
                thresholdedImage = thresholdedImage <threshold & EnvironmentMask; %Find all minimums
                thresholdedImage = bwareaopen(thresholdedImage,10); %get rid of small regions
                thresholdedImage = bwmorph(thresholdedImage,'close'); %dilate, then erode the binary image
                thresholdedImage = bwmorph(bwmorph(thresholdedImage,'erode'),'erode'); %erode the binary image to clean up cable
            else
                thresholdedImage = double(thisFrame(:,:,1));
                thresholdedImage(~EnvironmentMask) = NaN; %Restrict location to the EnvironmentMask
                threshold = prctile(thresholdedImage(:),2);
                thresholdedImage = thresholdedImage < threshold & EnvironmentMask; %Find all minimums
                thresholdedImage = bwareaopen(thresholdedImage,10); %get rid of small regions
               
            end
            if i == 1 %Get initial mouse location based on user input and restrict search for mouse to smaller region
                figure(1), hold off; imshow(thisFrame)
                title('Click on the mouse to initialize behavior tracking')
                [X0,Y0] = ginput(1);
                hold on
                plot(X0,Y0,'r*')
                X0 = round(X0); Y0 = round(Y0);
                pause(0.1);
                tmpposition(i,:) = [X0 Y0]; %This is a valid timepoint
                ind = 1;
            else %Restrict search for mouse to smaller region based on the last valid location of the mouse
                
                if (i - ind)<5
                    X0 = round(tmpposition(ind,1)); Y0 = round(tmpposition(ind,2)); %Get x,y indices
                else
                    figure(1), hold off;
                    imshow(thisFrame)
                    title('Click on the mouse to reinitialize behavior tracking')
                    [X0,Y0] = ginput(1);
                    hold on
                    plot(X0,Y0,'r*')
                    pause(0.1)
                    X0 = round(X0); Y0 = round(Y0);
                end

            
                localMask = zeros(size(thresholdedImage)); %Initialize mask
                localMask(Y0,X0) = 1;
                %Limit search to a disk of mouse size region around X0,Y0
                thresholdedImage = thresholdedImage & imdilate(localMask,MouseSizeDisk); %Limit search for mouse to valid locations
                clear localMask reply thisFrame

                [y,x] = find(thresholdedImage); %determine the x,y locations

                valid = 0;
                if (i-ind)<5
                    if  sqrt((mean(x)-X0)^2 + (mean(y)-Y0)^2) < 4*MouseSize
                        valid = 1; %Include if the mouse didn't move too far from last frame
                    end
                else
                    if sqrt((mean(x)-X0)^2 + (mean(y)-Y0)^2) < 2*MouseSize
                        valid = 1; %Include if the mouse didn't move too far from last frame
                    elseif (i-ind) > 10
                        x = X0; y = Y0;
                    end
                end

                %Exclude if too far from a detected dark patch
                if max(max(thresholdedImage(round(max(mean(y)-MouseSize/5,1)):round(min(mean(y)+MouseSize/5,mov.Height)), ...
                     round(max(mean(x)-MouseSize/5,1)):round(min(mean(x)+MouseSize/5,mov.Width))))) == 0;
                    valid = 0;
                end
                if valid
                    tmpposition(i,:) = [mean(x) mean(y)]; %This is a valid timepoint
                    ind = i;
                end
            end
            clear X0 Y0 x y valid validx validy
        end
        clear thresholdedImage
        
        %Identify times requiring human input
        invalid = isnan(tmpposition(:,1));

        invalid = regionprops(logical(bwareaopen(invalid,5)),'PixelList'); %Identify stretches of >4 NaNs in a row
        
        figure(1)
        hold off
        title('Click once on the mouse')
        for i = 1:length(invalid)
            framestocheck = invalid(i).PixelList(5:5:end,2);
            for f = framestocheck'
                thisFrame = read(mov,f);
                imshow(thisFrame)
                [X,Y] = ginput(1);
                tmpposition(f,1:2) = [X Y];
                hold on
                plot(X,Y,'r*')
                pause(0.1)
                hold off
            end
        end
        close all; clear invalid i framestocheck f thisFrame X Y mov
        
        %Perform Lowess smoothing
        time = (0:1:size(tmpposition,1)-1)./fps;
        smoothedposition = mslowess(time',tmpposition).*cmperpixel;
        
        %Calculate velocity
        vel = zeros(size(time));
        vel(2:end) = sqrt(diff(smoothedposition(:,1)).^2 + diff(smoothedposition(:,2)).^2).*fps;
        vel(1) = median(vel(1:50));
        
        %Add time, smoothed position, and velocity to the pos structure
        pos{days(d)}{behavioraltrial}.data = [time' smoothedposition zeros(size(vel')) vel'];
        pos{days(d)}{behavioraltrial}.fields = [{'Time (s)'},{'X (cm)'},{'Y (cm)'},{''},{'Velocity (cm/s)'}];
        pos{days(d)}{behavioraltrial}.cmperpixel = cmperpixel;
        clear time tmpposition smoothedposition
    end
    
    %Save position file for each day
    if days(d)<10
        savestring = [animaldir, filesep, animalprefix,'pos0',num2str(days(d)),'.mat'];
    else
        savestring = [animaldir, filesep, animalprefix,'pos',num2str(days(d)),'.mat'];
    end
    save(savestring,'pos');
    clear pos behavioraltrial movieorder 
end

