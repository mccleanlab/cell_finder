function exportCellMeasurements(cellMeasurements,params)
tic
disp('Exporting cell measurements');

% Create output folder
if ~exist(params.outputFolder)
    mkdir(params.outputFolder)
end

% Set data path for output
if isempty(params.tabletype)
    ext = '.xlsx';
else
    ext = params.tabletype;
end

outputDataPath = [params.outputFolder '\' params.outputFilenameBase '_cellMeasurements' ext];
% outputDataPath = fullfile('E:\microscopy\20210207_2\output\',strcat(params.outputFilenameBase,'_cellMeasurements',ext));

% Delete previously exported data (otherwise appends)
if exist(outputDataPath)~=0
    delete(outputDataPath);
end

% Write data into .xls file
cellMeasurements.sourceFile = repmat(params.sourceFile,height(cellMeasurements),1);
if strcmp(ext,'.mat')
    save(outputDataPath,'cellMeasurements');
else
    writetable(cellMeasurements, outputDataPath);
end
toc;