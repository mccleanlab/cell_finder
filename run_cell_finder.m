% Run this script to execute cell tracking functions.
%% 
clearvars; close all; clc
tnet = tic;
warning('off', 'images:imfindcircles:warnForLargeRadiusRange');
warning('off', 'images:imfindcircles:warnForSmallRadius');
warning('off', 'images:initSize:adjustingMag');

%% Set parameters
params.sizeNuc = [2 8];
params.sizeCell = [9 18];
params.nucGamma = .75;
params.cellGamma = 0.8;
params.nucSensitivity = 0.85;
params.cellSensitivity = 0.85;
params.nucEdgeThresh = 0.5;
params.cellEdgeThresh = 0.4;
params.nucDilate = 3;
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
params.displayCellNumber = 0;
params.measureLocalization = 1;

%%
channellist = {'DIC','iRFP','mRuby','GFP'}; % Specify image channels (in order)
numFrames = []; % Specify number of frames to load (optional)
imagelist = selectImages(); % Load images for analysis (selection prompt)

%% Loop through image list and track/measure cells
for imidx = 1:numel(imagelist)
    cellData = [];cellMeasurements = []; % Clear variables for use   
    [images, params] = loadTIFF(imagelist,imidx,channellist,numFrames,params); % Load images  
    cellData = findCells(images, 'iRFP','DIC', params); % Find ROIs   
    cellDataTrack = trackCells(cellData, 'Cells',15,4); % Track ROIs    
    cellDataTrack = interpolateTracks(cellDataTrack,params,1); % Interpolate tracks   
    images.mRuby = simpleBGsubtract(images,'mRuby'); % BG subtraction       
    cellMeasurements = measureCells(images,'mRuby',cellDataTrack,params);% Measure cells   
    exportCellMeasurements(cellMeasurements,params); % Export measurements  
    exportCellDisplay(cellMeasurements,images,'mRuby','DIC',params);  % Export movie of tracked cells
end

%% Clean up
tnet = toc(tnet);
disp(['Total elapsed time is ' num2str(tnet) ' seconds'])
clearvars -except images params cellData celldataTrack cellMeasurements