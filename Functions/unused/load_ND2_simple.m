function [images, params, im] = load_ND2_simple(imagelist,imidx,channellist,params)
% numFrames = [];
% numPositions = 8;
% imidx = 1;
% imagelist = selectImages();

imfile = imagelist{imidx};
[~, filename] = fileparts(imfile);
disp(['Loading ' filename]);
im = bfopen(imfile);

channel = channellist{1};

images.(channel) = im{1,1};
images.([channel '_mode']) =  cellfun(@(x) mode(x,'all'),images.(channel),'UniformOutput',false);
images.(channel) = cat(3,images.(channel){:,1});
params.outputFolder = [pwd '\output'];

images.iminfo.h = size(images.(channellist{1}),1);
images.iminfo.w = size(images.(channellist{1}),2);
images.iminfo.nf = size(images.(channellist{1}),3);
images.iminfo.np = size(images.(channellist{1}),4);

[folder, filename, ext] = fileparts(imfile);
match = [ext, channellist];
params.sourceFile = filename;
params.outputFilenameBase = erase(filename, match);
params.outputFolder = [folder '\output\'];

