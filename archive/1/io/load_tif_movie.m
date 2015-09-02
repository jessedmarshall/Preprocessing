function out = load_tif_movie(filename,downsample_xy)
%loads filename movie, downsamples in space by factor downsample_xy

%Written by Jerome Lecoq for SpikeE
%--------------------------------------------------------------------------

%First load a single frame of the movie to get generic information
TifLink = Tiff(filename, 'r'); %Create the Tiff object
TmpImage = TifLink.read();%Read in one picture to get the image size and data type
TifLink.close(); clear TifLink

LocalImage = imresize(TmpImage, 1/downsample_xy); clear TmpImage; %Resize
SizeImage=size(LocalImage);%xy dimensions
ClassImage= class(LocalImage); clear LocalImage; %Get the class of the movie

% Pre-allocate the movie
out.Numberframe=size(imfinfo(filename),1);% Number of frames
out.Movie =zeros(SizeImage(1),SizeImage(2),out.Numberframe,ClassImage);

% We use low-level access to the tifflib library file to avoid duplicating
% Access to the Tif properties while reading long list of directories in Tiffs
FileID = tifflib('open',filename,'r');
rps = tifflib('getField',FileID,Tiff.TagID.RowsPerStrip);
hImage = tifflib('getField',FileID,Tiff.TagID.ImageLength);
rps = min(rps,hImage);

for j=1:out.Numberframe
    tifflib('setDirectory',FileID,1+j-1);

    % Go through each strip of data.
    for r = 1:rps:hImage
        row_inds = r:min(hImage,r+rps-1);
        stripNum = tifflib('computeStrip',FileID,r);
        if downsample_xy~=1
            TmpImage(row_inds,:) = tifflib('readEncodedStrip',FileID,stripNum);
        else
            out.Movie(row_inds,:,j)= tifflib('readEncodedStrip',FileID,stripNum);
        end
    end
    if downsample_xy~=1
        out.Movie(:,:,j)=imresize(TmpImage,1/downsample_xy);
    end
end
tifflib('close',FileID);