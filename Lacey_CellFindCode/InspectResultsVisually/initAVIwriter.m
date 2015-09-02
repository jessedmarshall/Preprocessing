function writerObj = initAVIwriter(fName, framerate)

if ~strcmp(fName(end-3:end), '.avi')
    fName=[fName, '.avi'];
end
fInd=1;
while exist(fName, 'file')
    fInd=fInd+1;
    if fInd==2
        fName=[fName(1:end-4), num2str(fInd), fName(end-3:end)];
    else
        fName=[fName(1:end-5), num2str(fInd), fName(end-3:end)];
    end
end
clear fInd
writerObj=VideoWriter(fName);
writerObj.FrameRate=framerate;
open(writerObj);