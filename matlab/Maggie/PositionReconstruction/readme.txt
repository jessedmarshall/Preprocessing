Note that linearizePos requires the geometry libraries that can be downlowded here:
http://www.mathworks.com/matlabcentral/fileexchange/7844-geom2d



Example of how to process position:

%% Define animal specific information
animaldir = '/H_962';
animalprefix = 'H_962';

%% Process position
%Linear Track:
Options.LinearTrackDays = [1 2 3 5]; %List of days the animal ran on the linear track
cmperpixel = calccmperpixel(animaldir,animalprefix,Options.LinearTrackDays(1));
for i = 1:length(Options.LinearTrackDays)
    calcmouseposition(animaldir,animalprefix,Options.LinearTrackDays(i),'FramesPerSecond',20,'CmPerPixel',cmperpixel); %Run for each experimental set up separately
    if i == 1
        Options.LinearTrackPoints = [571.5*cmperpixel 252*cmperpixel; 203*cmperpixel 368*cmperpixel];
    elseif i == 2
        Options.LinearTrackPoints = [571.5*cmperpixel 252*cmperpixel; 154*cmperpixel 223*cmperpixel];
    elseif i == 3
        Options.LinearTrackPoints = [571.5*cmperpixel 252*cmperpixel; 370*cmperpixel 40*cmperpixel];
    elseif i == 4
        Options.LinearTrackPoints = [571.5*cmperpixel 252*cmperpixel; 223*cmperpixel 85*cmperpixel];
    else
        display('Linear Track Experiment only defined for 4 experiment days!')
    end
    linearizePos(animaldir,animalprefix,Options.LinearTrackDays(i), 'line', Options.LinearTrackPoints,'cmperpixel',0.275);
end

%Reward Track: Completed 12/5/2013
Options.RewardDays = 7:15; %Reward track days
calcmouseposition(animaldir,animalprefix,Options.RewardDays,'FramesPerSecond',20,'InteriorMask',1); %Run for each experimental set up separately
cmperpixel = calccmperpixel(animaldir,animalprefix,Options.RewardDays(1));
Options.RewardTrackPoints = [471.5*cmperpixel 358*cmperpixel; 316*cmperpixel 223*cmperpixel; 463.5*cmperpixel 215*cmperpixel]; %Coordinates that define the circle of the reward track, the first pair will be the origin (trigger location)
linearizePos(animaldir,animalprefix,Options.RewardDays,'circle', Options.RewardTrackPoints,'cmperpixel',cmperpixel);

%Fear conditioning:
Options.FearDays = 19:23; %Fear Days
cmperpixel = calccmperpixel(animaldir,animalprefix,Options.FearDays(1));
calcmouseposition(animaldir,animalprefix,Options.FearDays,'FramesPerSecond',20,'CmPerPixel',cmperpixel); %Run for each experimental set up separately

