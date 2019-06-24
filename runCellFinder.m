% Run this script to execute cell tracking functions.
%%
clearvars;close all;clc
tnet = tic;

warning('off', 'images:imfindcircles:warnForLargeRadiusRange');
warning('off', 'images:imfindcircles:warnForSmallRadius');
warning('off', 'images:initSize:adjustingMag');

%% Load images
tic;
disp('Loading images into MATLAB');
channels = {'iRFP','mCh'};
[images, params] = loadImages(channels,[]);
toc;

%% Set parameters
params.sizeNuc = [3 12]; 
params.sizeCell = [18 30];
params.nucGamma = 3;
params.cellGamma = 0.75;
params.nucSensitivity = 0.95; 
params.cellSensitivity = 0.85;
params.nucEdgeThresh = 0.5;
params.cellEdgeThresh = 0.5;
params.nucDilate = 5;
params.sizeNucForce = []; 
params.sizeCellForce = []; 
params.sizeCellScale = 0.9;
params.nucOverlapThresh = -0.9;
params.cellOverlapThresh = 0.5;
params.nucCellOverlapThresh = 0.5;
params.lifespan = 5;
params.smoothFilterSize = [5, 5, 5, 5, 5, 3]; % params.smoothFilterSize = [5, 5, 3];
params.medFilterSize = 0;
params.displayCells = 1;
params.writeImages = 1;
params.displayCellNumber = 1;

%% Register images
tic
disp('Registering images');
[images.iRFP, xform] = registerImagesFast(images.iRFP,[]);
[images.mCh, ~] = registerImagesFast(images.mCh,xform);
clearvars xform
toc;

%% Find cell and nuclei ROIs
tic
disp('Finding paired cell/nucleus ROIs')
cellData = findCells(images.iRFP,images.mCh,'mCh',params);
% cellData = findCells([],images.mCh,'mCh',params);
toc;

%% Track cell ROIs
tic
maxLinkDist = 30;
maxGapClose = 25;
cellData = trackCells(cellData, 'Cells',maxLinkDist,maxGapClose);
disp(['Tracking ' num2str(length(unique(cellData.TrackID))) ' ROIs']);
clearvars maxLinkDist maxGapClose
toc;

%% Remove repeated nuclei
tic
disp('Removing repeated nuclear ROIs');
cellData = removeRepeatNuclei(cellData);
toc;

%% Interpolate cell tracks and remove tracks with duration < lifespan
tic
disp('Interpolating ROI tracks');
cellData = interpolateTracks(cellData,params,1);
toc;

%% Smooth tracks
tic
disp('Smoothing ROI tracks');
cellData = smoothTracks(cellData,params.smoothFilterSize,params.medFilterSize);
toc;

%% BG subtract images
tic
disp('Background subtraction')
[params.BG.YFP, ~] = calcBG(images.DIC,images.YFP,1,params);
images.YFP = images.YFP - cellFinderProperties.BG.YFP;
[params.BG.mCh, ~] = calcBG(images.DIC,images.mCh,1,params);
images.mCh = images.mCh - params.BG.mCh;
params.BG = images.mCh(:,:,1);
params.BG = mode(params.BG(:));
images.mCh = images.mCh - params.BG;
toc

%% Measure cells within tracked ROIs
tic
cellMeasurements = cellData;
cellMeasurements = measureCells(images.mCh,'mCh',1,cellMeasurements,params);
toc;

%% Export data
tic
disp('Exporting cell measurements');
% Delete previously exported data (otherwise appends)
if exist(params.outputDataPath)~=0
    delete(params.outputDataPath);
end
% Write data into .xls file
cellMeasurements.SourceFile = repmat(params.paths.mCh,height(cellMeasurements),1);
writetable(cellMeasurements, params.outputDataPath);
toc;

%% Display tracked cells
tic
disp('Displaying tracked cells');
displayCells(cellMeasurements,images.mCh,images.mCh,params);
toc;

%%
tnet = toc(tnet);
disp(['Total elapsed time is ' num2str(tnet) ' seconds'])
clearvars -except images params cellData cellMeasurements