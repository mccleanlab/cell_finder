function [images, params] = loadImages(channels,nf)
% Set file paths
[files, images.folder] =  uigetfile('.tif','Select files','MultiSelect','on');

if ischar(files)==1
    files = {files};
end

for i = 1:length(channels)
    VOI = channels{i};
    images.paths.(VOI)= contains(files,VOI);
    images.paths.(VOI) = [images.folder files{images.paths.(VOI)}];
    images.info.(VOI) = imfinfo(images.paths.(VOI));
end

% Extract parameters from images
params.w = images.info.(channels{1}).Width;
params.h = images.info.(channels{1}).Height;
if isempty(nf)
    params.nf = length(images.info.(channels{1}));
else
    params.nf = nf;
end
match = [".nd2", ".tif", ".tiff", channels];
params.prefix = erase(files{1}, match);
params.prefix = params.prefix(1:end-1);
clearvars match files;
params.outputFolder = [images.folder 'output\'];
params.outputDataPath = [params.outputFolder params.prefix '_cellMeasurements' '.xls'];
params.paths = images.paths;

%% Create output folder
if ~exist(params.outputFolder)
    mkdir(params.outputFolder)
end

%% Load timeseries images into workspace
for i = 1:length(channels)
    VOI = channels{i};
    for t = 1:params.nf        
        images.(VOI)(:,:,t)=imread(images.paths.(VOI),'Index',t);
    end
end