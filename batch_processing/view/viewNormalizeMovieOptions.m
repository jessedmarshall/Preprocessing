function [output] = viewNormalizeMovieOptions(varargin)
	% example function with outline for necessary components
	% biafra ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	options.exampleOption = '';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		% do something
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end



testRadius = 0;
if testRadius == 1
    n = 0;
    for i=[5:5:60]
        n = n + 1;
        h3 = fspecial('disk', i);
        thisFrame = squeeze(testMovie(:,:,n));
        filterImages1(:,:,n) = imfilter(thisFrame, h3,'circular');
    end
    testFilters = bsxfun(@ldivide,filterImages1,testMovie(:,:,1:n));
    montageImages = {testFilters,testMovie(:,:,1:n)};
    figure(11);close(11);figure(11)
    for i=1:2
        clear filterImageMontage
        subplot(1,2,i)
        filterImageMontage(:,:,:,1) = montageImages{i};
        montage(permute(filterImageMontage(:,:,:,1),[1 2 4 3]))
        filterImageMontage = getimage;
        % change zeros to ones, fixes range of image display
        filterImageMontage(filterImageMontage==0)=NaN;
        filterImageMontage = normalizeVector(filterImageMontage);
        imagesc(filterImageMontage );
    end
    return
end