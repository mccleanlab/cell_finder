function [images, params] = loadTIFF(imagelist,imidx,channellist,numFrames,params)

imfile = imagelist{imidx};

iminfo = imfinfo(imfile);
neries = size(iminfo,1);
nChannels = numel(channellist);

nPositions = 1; % Could potentially modify image loading to account for multiple stage positions 

if isempty(numFrames)
   numFrames = neries./nChannels;
end

images.h = iminfo(1).Height;
images.w = iminfo(1).Width;
images.np = nPositions;
images.nf = numFrames;

for p = 1:nPositions
    position = p;
    for c = 1:nChannels
        channel = channellist{c};
        flist = c:nChannels:(numFrames*nChannels);
        for frame = 1:numel(flist)
            fidx = flist(frame);
            imdata = imread(imfile,fidx);
            images.(channel)(:,:,frame,position) = imdata;
            images.([channel '_mode'])(frame,position) = mode(imdata(:));
        end
    end
end

[folder, filename, ext] = fileparts(imfile);
match = [ext, channellist];
params.sourceFile = filename;
params.outputFilenameBase = erase(filename, match);
params.outputFolder = [folder '\output\'];


