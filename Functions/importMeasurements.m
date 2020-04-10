function dataOut = importMeasurements(varargin)

dataOut = [];

% Instantiate inputParser
p = inputParser;
addParameter(p, 'Files', '');
addParameter(p, 'Folder', '', @isfolder);
parse(p, varargin{:});

% Parse inputs
parse(p, varargin{:});

if strcmp(p.Results.Folder,'') && strcmp(p.Results.Files,'')
    % If folder and files not specified, open UI
    [files, folder] =  uigetfile('*xlsx;*.csv','MultiSelect','on');
    if ischar(files)==1
        files = {files};
    end
    
else
   % Select specified files and folders
    folder = p.Results.Folder;
    folder = folder{1};
    files = p.Results.Files;
end

for i = 1:length(files)
    file = files{i};
    data0 = readtable([folder ,'\' file]);
    try
        dataOut = [dataOut; data0];
    catch
        disp(['ERROR: ' file]);
    end
end

