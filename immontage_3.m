%% Select images
clearvars; close all; clc
imagelist = selectImages();
channellist = {'iRFP','mScarlet','mCitrine','DIC'};
channels2montage = {'mScarlet','mCitrine'};
nf = [];
numPositions = 3;
position = 3;
imScale = 0.5;
bgsubtract = 1;
%% Load images
images = struct();
for imidx = 1:numel(imagelist)
    [~, imname,~] = fileparts(imagelist{imidx});
    [im, ~, ~] = loadND(imagelist,imidx,channellist,nf,numPositions,[]);
    images.(imname) = im;
end

%% Load images
imMontage = {};
nimages = length(fieldnames(images));

for imidx = 1:nimages
    imname0 = fieldnames(images);
    imname0 = imname0{imidx};
    im0 = images.(imname0);   
    for cidx = 1:numel(channels2montage) 
        channel = channels2montage{cidx};
        im00 = im0.(channel)(:,:,f,p);
        s = size(im00);
        imBlock{cidx} = reshape(im00,s(1)*s(4),s(2)*s(3));
    end
end

%
% clearvars -except im imagelist position channels2montage

