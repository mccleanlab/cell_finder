function export_cell_measurements(cell_measurements,params)

disp('Exporting cell measurements');

% Create output folder
if ~exist(params.outputFolder,'dir')
    mkdir(params.outputFolder)
end

% Set data path for output
if isempty(params.tableType)
    ext = '.xlsx';
else
    ext = params.tableType;
end

file_name_out = fullfile(params.outputFolder, strcat(params.sourceFile,'_cell_meausurements',ext));

% Delete previously exported data (otherwise appends)
if exist(file_name_out)~=0
    delete(file_name_out);
end

% Write data into .xls file
cell_measurements.sourceFile(:,1) = string(params.sourceFile);
if strcmp(ext,'.mat')
    save(file_name_out,'cell_measurements');
else
    writetable(cell_measurements, file_name_out);
end