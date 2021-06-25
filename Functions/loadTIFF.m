function [images, params] = loadTIFF(imagelist,imidx,channellist,nFrames,params)
% clearvars -except imagelist params numFrames
tic
% nFrames = [];
% imidx = 1;
% channellist = {'mCherry','GFP','DIC'};

imfile = imagelist{imidx};


iminfo = imfinfo(imfile);
nSeries = size(iminfo,1);
nChannels = numel(channellist);
nPositions = 1;


if isempty(nFrames)
    nFrames = nSeries./nChannels;
end

h = iminfo(1).Height;
w = iminfo(1).Width;

im = zeros(h,w,nFrames,nPositions,nChannels,'uint16');
immode = zeros(nFrames,nPositions,nChannels,'uint16');

for p = 1:nPositions
    for c = 1:nChannels
        flist = c:nChannels:(nFrames*nChannels);
        parfor f = 1:numel(flist)
            fidx = flist(f);
            im0 = imread(imfile,fidx);
            im(:,:,f,p,c) = im0;
            immode(f,p,c) = mode(im0,'all');
        end
    end
end

for c = 1:nChannels
    channel = channellist{c};
    images.(channel)=im(:,:,:,:,c);
    images.([channel '_mode']) = immode(:,:,c);
end

images.iminfo.h = iminfo(1).Height;
images.iminfo.w = iminfo(1).Width;
images.iminfo.np = nPositions;
images.iminfo.nf = nFrames;

[folder, filename, ext] = fileparts(imfile);
match = [ext, channellist];
params.sourceFile = filename;
params.outputFilenameBase = erase(filename, match);
params.outputFolder = [folder '\output\'];
toc

% function [images, params] = loadTIFF(imagelist,imidx,channellist,nFrames,params)
% % clearvars -except imagelist params numFrames
% tic
% % nFrames = [];
% 
% imidx = 1;
% imfile = imagelist{imidx};
% channellist = {'mCherry','GFP','DIC'};
% iminfo = imfinfo(imfile);
% nSeries = size(iminfo,1);
% nChannels = numel(channellist);
% nPositions = 1;
% 
% 
% if isempty(nFrames)
%     nFrames = nSeries./nChannels;
% end
% 
% h = iminfo(1).Height;
% w = iminfo(1).Width;
% 
% im = zeros(h,w,nFrames,nPositions,nChannels,'uint16');
% immode = zeros(nFrames,nPositions,nChannels,'uint16');
% 
% for p = 1:nPositions
%     for c = 1:nChannels
%         flist = c:nChannels:(nFrames*nChannels);
%         parfor f = 1:numel(flist)
%             fidx = flist(f);
%             im0 = imread(imfile,fidx);
%             im(:,:,f,p,c) = im0;
%             immode(f,p,c) = mode(im0,'all');
%         end
%     end
% end
% 
% for c = 1:nChannels
%     channel = channellist{c};
%     images.(channel)=im(:,:,:,:,c);
%     images.([channel '_mode']) = immode(:,:,c);
% end
% 
% images.iminfo.h = iminfo(1).Height;
% images.iminfo.w = iminfo(1).Width;
% images.iminfo.np = nPositions;
% images.iminfo.nf = nFrames;
% 
% [folder, filename, ext] = fileparts(imfile);
% match = [ext, channellist];
% params.sourceFile = filename;
% params.outputFilenameBase = erase(filename, match);
% params.outputFolder = [folder '\output\'];
% toc

