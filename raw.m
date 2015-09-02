g = loadMovieList('B:\data\pav\p104\m999\131003-M999-PAV01\concatenated_recording_20131003_154007.h5','convertToDouble',0);
fid = fopen('A:\image.raw', 'w');
fwrite(fid, g, 'uint16');
fclose(fid);