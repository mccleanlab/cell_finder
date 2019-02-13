% Run this script to execute cell tracking functions.
%%
clearvars;close all;clc
tnet = tic;

warning('off', 'images:imfindcircles:warnForLargeRadiusRange');
warning('off', 'images:imfindcircles:warnForSmallRadius');
warning('off', 'images:initSize:adjustingMag');

%% Load images
tic;
channels = {'DIC', 'iRFP', 'mCh', 'YFP'};
[images, params] = loadImages(channels);
disp('Loading images into MATLAB');
toc;
%% Set parameters
params.sizeNuc = [3 9];
params.sizeCell = [16 36];
params.nucSensitivity = 0.95;
params.cellSensitivity = 0.85;
params.sizeNucForce = [8 12];
params.sizeCellForce = [16 36];
params.sizeCellScale = 1;
params.nucOverlapThresh = -0.9;
params.cellOverlapThresh = 0.25;
params.nucCellOverlapThresh = 0.5;
params.lifespan = 5;
params.displayCells = 0;
params.writeImages = 1;
%% Register images
tic
[images.DIC, xform] = registerImagesFast(images.DIC,[]);
[images.iRFP, ~] = registerImagesFast(images.iRFP,xform);
[images.mCh, ~] = registerImagesFast(images.mCh,xform);
clearvars xform
disp('Registering images');
toc;
%% Find cell and nuclei ROIs
tic
cellData = findCells(images.iRFP,images.DIC,'DIC',params);
disp('Finding paired cell/nucleus ROIs')
toc;

%% Track cell ROIs
tic
maxLinkDist = 30;
maxGapClose = 25;
cellData = trackCells(cellData, 'Cells',maxLinkDist,maxGapClose);
clearvars maxLinkDist maxGapClose
disp(['Tracking ' num2str(length(unique(cellData.TrackID))) ' ROIs']);
toc;
%% Remove repeated nuclei
tic
cellData = removeRepeatNuclei(cellData);
disp('Removing repeated nuclear ROIs');
toc;
%% Interpolate cell tracks and remove tracks with duration < lifespan
tic
cellData = interpolateTracks(cellData,params,1);
disp('Interpolating ROI tracks');
toc; 
%% Smooth tracks
tic
cellData = smoothTracks(cellData);
disp('Smoothing ROI tracks');
toc;
%% BG subtract images
% tic 
% [params.BG.YFP, ~] = calcBG(images.DIC,images.YFP,1,params);
% images.YFP = images.YFP - cellFinderProperties.BG.YFP;
% [params.BG.mCh, ~] = calcBG(images.DIC,images.mCh,1,params);
% images.mCh = images.mCh - params.BG.mCh;
% toc
% disp('Background subtraction')
%% Measure cells within tracked ROIs
tic
cellMeasurements = measureCells(images.YFP,'YFP',0,cellData,params);
cellMeasurements = measureCells(images.mCh,'mCh',1,cellMeasurements,params);
toc;
%% Export data
tic
% Delete previously exported data (otherwise appends)
if exist(params.outputDataPath)~=0
    delete(params.outputDataPath);
end
% Write data into .xls file
cellMeasurements.SourceFile = repmat(params.paths.DIC,height(cellMeasurements),1);
writetable(cellMeasurements, params.outputDataPath);
disp('Exporting cell measurements');
toc;
%% Display tracked cells
tic
displayCells(cellMeasurements,images.DIC,images.DIC,params);
disp('Displaying tracked cells');
toc; 
%%
tnet = toc(tnet);
disp(['Total elapsed time is ' num2str(tnet) ' seconds'])
clearvars -except images params cellData cellMeasurements