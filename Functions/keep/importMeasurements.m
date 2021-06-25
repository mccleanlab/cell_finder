function dataOut = importMeasurements(varargin)

dataOut = [];

% Instantiate inputParser
p = inputParser;
addParameter(p,'folder', [], @isfolder);
addParameter(p,'ext',[])
parse(p, varargin{:});

% Parse inputs
parse(p, varargin{:});

if ~isempty(p.Results.folder) && ~isempty(p.Results.ext)
    % Load files with specified extension from specified folder
    files = dir(fullfile(p.Results.folder,strcat('*',p.Results.ext)));
    files = struct2table(files);
    
    % Change format if only one file
    if size(files,1)==1
        files.folder = string(files.folder);
        files.name = string(files.name);
        files.data = string(files.date);
    end
    
else
    % Open UI prompt to load files
    [file_list, folder] =  uigetfile('*xlsx;*.csv','MultiSelect','on');
    
    % Correct filename format if only loading one file
    if ~iscell(file_list)
        file_list = {file_list};
    end
    
    % Reorder filenames into vertical cell array if needed
    if size(file_list,2)>1
        file_list = file_list';
    end
    
    % Save list of files in table
    files = table();
    files.name = cellstr(file_list);
    files.folder(:,1) = string(folder);    
end


% else
%    % Select specified files and folders
%     folder = p.Results.Folder;
%     folder = folder{1};
%     files = p.Results.Files;
% end
%
for f = 1:size(files,1)
    
    data0 = readtable(fullfile(files.folder{f},files.name{f}));
%     try
        dataOut = [dataOut; data0];
%     catch
%         
%         disp(['ERROR: ' files.name{f}]);
%     end
end

