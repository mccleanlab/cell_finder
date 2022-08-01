function data_out = import_mat_table(folder,variable_names,condition_variable,condition_value,condition_type)
% data_out = {};

% Define datastore
data_store = fileDatastore(fullfile(folder,'*.mat'),'ReadFcn',@load);
data_out = cell(size(data_store.Files,1),1);
idx = 1;

% Loop through files in datastore and load
while hasdata(data_store)
    data_temp = read(data_store);
    
    field_name = fieldnames(data_temp);
    data_temp = data_temp.(field_name{:});
    
    if exist('variable_names','var') && ~isempty(variable_names)
        data_temp = data_temp(:,variable_names);
    end
    
    if exist('condition_variable','var') && exist('condition_value','var') && exist('condition_type','var')
        if strcmp(condition_type,'exclude')
            data_temp(ismember(data_temp.(condition_variable),condition_value),:) = [];
        elseif strcmp(condition_type,'keep')
            data_temp(~ismember(data_temp.(condition_variable),condition_value),:) = [];
        end
    end
    
    
    stringvar_idx = ismember(varfun(@class,data_temp,'OutputFormat','cell'),'string');
    stringvar_names = data_temp.Properties.VariableNames(stringvar_idx);
    data_temp = convertvars(data_temp,stringvar_names,'categorical');
    data_out{idx,1} = data_temp;
    idx = idx + 1;
end

data_out = vertcat(data_out{:});

% variable_names = {'Frame','mCitrine_cell_median'};
% % fds = fileDatastore(fullfile(pwd,'\output'),'ReadFcn',@(x)struct2table(load(x)),'UniformRead', true,'FileExtensions','.mat');
% fds = fileDatastore(fullfile(pwd,'\output','*.mat'),'ReadFcn',@load);
% data = read(fds);
% data = data.cellMeasurements;
% data = data(:,variable_names)