function [] = linearizePos(animaldir, animalprefix, days, shape, points,varargin)
%LINEARIZEPOS takes in the path to an animal directory, the animal name,
%the experiment days to process, the method (linear, circle, radial arm),
%and a set of coordinates from Ethovision, opens the pos file, calculates 
%the linearized pos, adds it to the pos cell array, and then saves the 
%file and closes it.
%
%'line': You need to supply the origin and one point. We decided for the
%linear track that these should be the reward port locations. You can get
%the points by going into EthoVision and looking at each track's Arena
%Settings. The coordinates are in EthoVision "World point"
%coordinates--i.e. calibrated using the calibration scale you supply for
%the arena.
%
%'circle': You need to supply three points, one will be the origin where
%all distances will be measured from and the others just need to be two
%points on the circle, approximately in the middle of the width. You can get
%the points by going into EthoVision and looking at each track's Arena
%Settings. The coordinates are in EthoVision "World point"
%coordinates--i.e. calibrated using the calibration scale you supply for
%the arena.
%
%Options:
%cmperpixel: Allows the user to update cmperpixel used in position strucutre.
%
%Written by Liz Otto Hamel, 2/21/2013, updated by Maggie Carr Larkin 1/15/2014
%
%--------------------------------------------------------------------------

if ~strcmpi(shape,'line')&&~strcmpi(shape, 'circle')
    disp('Please input a valid shape ("line" or "circle")');
    return
end

if strcmpi(shape, 'line')&&any(size(points)~=[2,2])
    disp('Please input the coordinates of 2 points for a linear arena.');
    return
elseif strcmpi(shape,'circle')&&any(size(points)~=[3,2])
    disp('Please input the coordinates of 3 points for a circular arena.');
    return
end

origin = points(1,:);

%Process options
cmperpixel = [];
for i = 1:2:length(varargin)
    val = lower(varargin{i});
    switch val
        case 'cmperpixel'
            cmperpixel = varargin{i+1};
        otherwise
            disp('Warning: Option is not defined');
    end
end

clear varargin i val
%append file separator if needed
if animaldir(length(animaldir))~=filesep
    animaldir = [animaldir, filesep];
end

%Main loop over experiment days
for dayInd=1:length(days)

	%Load pos file
    load([animaldir filesep animalprefix 'pos' num2str(days(dayInd), '%02g') '.mat']);
    
    %loop over sessions
    for sessionInd=1:length(pos{days(dayInd)})
        
        positions = pos{days(dayInd)}{sessionInd}.data(:,2:3);

        %If cmperpixel was provided as input, update cmperpixel
        if ~isempty(cmperpixel)
            positions = positions./pos{days(dayInd)}{sessionInd}.cmperpixel;
            positions = positions.*cmperpixel;
            pos{days(dayInd)}{sessionInd}.data(:,2:3) = positions;
            pos{days(dayInd)}{sessionInd}.cmperpixel = cmperpixel;
        end
        
        if strcmpi(shape,'line')
   
            %set the origin
            positions = positions - repmat(origin,size(positions,1),1);
            p1 = points(2,:)-origin;
            %create the matrix containing the vector defining the line
            line = repmat(p1,size(positions,1),1);
            %get the projections of the positions onto the line
            linpos = dot(positions,line,2)./sqrt(dot(line,line,2));
            
        elseif strcmpi(shape, 'circle')
            
            %get the center and radius of the circle that passes through
            %these points
            circle = createCircle(origin,points(2,:),points(3,:));
            %fill a matrix with the center coordinates
            center = repmat(circle(1:2), size(positions,1),1);
            %shift the data coordinate system to the circle center coordinates
            positions = positions - center;
            %get the polar angle of each data point in this coordinate system
            theta = atan2(positions(:,2),positions(:,1));
            %get the angle of the point we want to use as the origin
            thetaOrg = atan2(origin(2),origin(1));
            %get the angles of the data relative to the origin angle
            theta = theta - thetaOrg;
            %convert all angles to be between 0 and 2*pi
            theta(theta<0) = theta(theta<0)+2*pi;
            %get the arc lengths along the circle to each data point
            linpos = theta*circle(3);
        end 
    
        %Update position structure
        pos{days(dayInd)}{sessionInd}.fields{4} = 'Linearized Position';
        pos{days(dayInd)}{sessionInd}.data(:,4) = linpos;
        pos{days(dayInd)}{sessionInd}.origin = origin;
        pos{days(dayInd)}{sessionInd}.arenaPoints = points(2:end,:);
        pos{days(dayInd)}{sessionInd}.linearizationUsed = shape;
        if strcmpi(shape,'circle')
            pos{days(dayInd)}{sessionInd}.angle = theta;
        end
    end
    %Save position file
    save([animaldir filesep animalprefix 'pos' num2str(days(dayInd), '%02g') '.mat'], 'pos');
end

end
