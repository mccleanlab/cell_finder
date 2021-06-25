% Run this script to execute cell tracking functions.
%%
clearvars;close all;clc
tnet = tic;

warning('off', 'images:imfindcircles:warnForLargeRadiusRange');
warning('off', 'images:imfindcircles:warnForSmallRadius');
warning('off', 'images:initSize:adjustingMag');

%% Set parameters
params.sizeNuc = [4 24];
params.sizeCell = [12 30];
params.nucGamma = 1;
params.cellGamma = 0.5;
params.nucSensitivity = 0.9;
params.cellSensitivity = 0.85;
params.nucEdgeThresh = 0.25;
params.cellEdgeThresh = 0.25;
params.nucDilate = 5;
params.sizeNucForce = [4 12];
params.sizeCellForce = [];
params.sizeCellScale = 1;
params.nucOverlapThresh = -0.9;  params.nucOverlapThresh = 0;
params.cellOverlapThresh = 0.25;
params.nucCellOverlapThresh = 0.5;
params.lifespan = 1;

params.trackGap = 5;
params.trackMaxDist = 6;

params.smoothFilterSize = [5, 5, 5, 5, 5, 3]; % params.smoothFilterSize = [5, 5, 3];
params.medFilterSize = 0;
params.displayCells = 0;
params.displayCellNumber = 1;
params.measureLocalization = 1;

%% Select images
imagelist = selectImages();

%% Load images
channellist = {'iRFP','mScarlet','DIC'};
numFrames = [];
numPositions = 5;
for imidx = 1:numel(imagelist)
    images = [];
    cellData = [];
    cellMeasurements = [];
    
    [images, params, ~] = loadND(imagelist,imidx,channellist,numFrames,numPositions,params);
    
    %% Register images
    % [images.iRFP, xform] = registerImagesFast(images,'iRFP',[]);
    % [images.mScarlet, ~] = registerImagesFast(images,'mScarlet',xform);
    % [images.DIC, ~] = registerImagesFast(images,'DIC',xform);
    
    %% Find ROIs
    % cellData = findCells(images, [],'DIC', params);
    cellData = findCells(images, 'iRFP','DIC', params);
    
    %% Track ROIs
    % [cellDataTrack, tracksFinal] = utrack(cellData,'Cells',params);
    % maxLinkDist = 15;
    % maxGapClose = 4;
    % cellDataTrack = trackCells(cellData, 'Cells',maxLinkDist,maxGapClose);
    
    %% Interpolate tracks
    % cellDataTrack = interpolateTracks(cellDataTrack,params,1);
    
    %% BG subtraction
    images.mScarlet = simpleBGsubtract(images,'mScarlet');
    
    %% Measure cells
    cellMeasurements = measureCells(images,'mScarlet',cellData,params);
    
    %% Export measurements
    exportCellMeasurements(cellMeasurements,params)
    
    %% Export movie of tracked cells
    exportCellDisplay(cellMeasurements,images,[],'mScarlet',params)
end

%% Clean up
tnet = toc(tnet);
disp(['Total elapsed time is ' num2str(tnet) ' seconds'])
clearvars -except images params cellData celldataTrack cellMeasurements