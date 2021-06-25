function labels_out = get_labels(label_file,sheet)

if exist('label_file','var')~=1
    % Load plate map
    [file, folder] =  uigetfile('.xlsx','Select plate map','MultiSelect','on');
    opts = detectImportOptions([folder file]);
    opts = setvartype(opts, 'char');
    opts.DataRange = 'A1';
    if exist('sheet','var')==1
        opts.Sheet = sheet;
    else
        opts.Sheet = 'plate_map';
    end
    plate_map_raw = readtable([folder file], opts);
else
    opts = detectImportOptions(label_file);
    opts = setvartype(opts, 'char');
    opts.DataRange = 'A1';
    if exist('sheet','var')==1
        opts.Sheet = sheet;
    else
        opts.Sheet = 'plate_map';
    end
    plate_map_raw = readtable(label_file, opts);
end

% Create well name combos
plateDim = [8, 12];
R = {'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H'};
C = num2cell(1:12);
C = cellfun(@(x) sprintf('%02d',x),C,'UniformOutput',false);
C = string(C);
[c, r] = ndgrid(1:numel(C),1:numel(R));

well_list = [R(r(:)).' C(c(:)).'];
well_list = join(well_list);
well_list = strrep(well_list,' ','');
map.well = reshape(well_list,12,8)';

% Correct for plate dimension
map.well = map.well(1:plateDim(1),1:plateDim(2));

%% Add labels from plate map

if strcmp(opts.Sheet,'plate_map')
    label_list = regexp(plate_map_raw{:,:},'map_\w*','match');
    label_list = string(label_list(~cellfun('isempty',label_list)));
elseif strcmp(opts.Sheet,'optoplate_config')
    label_list = regexp(plate_map_raw{:,:},'LED1_\w*','match');
    label_list = string(label_list(~cellfun('isempty',label_list)));
end

labels_out = table();
labels_out.well = reshape(map.well',96,1);

for n = 1:numel(label_list)
    label = label_list{n};
    [w, kc] = find(strcmp(label,plate_map_raw{:,:}));
    w = w+1:w+plateDim(1);
    kc = kc+1:kc+plateDim(2);
    if strcmp(opts.Sheet,'plate_map')
        label = erase(label,'map_');
    elseif strcmp(opts.Sheet,'optoplate_config')
        label = regexprep(label,'LED1_','');
    end
    
    map.(label) = string(plate_map_raw{w,kc});
    
    labels_out.(label) = reshape(map.(label)',96,1);
end

% Remove unused
idx = ~any(cellfun(@isempty,labels_out{:,:}),2);
labels_out = labels_out(idx,:);

% If optoplate parameters conver strings to double
if strcmp(opts.Sheet,'optoplate_config')
    variable_list = labels_out.Properties.VariableNames;
    for i = 2:numel(variable_list)
        labels_out.(variable_list{i}) = str2double(labels_out.(variable_list{i}));
    end
% else
%     stringvar_idx = ismember(varfun(@class,labels_out,'OutputFormat','cell'),'string');
%     stringvar_names = labels_out.Properties.VariableNames(stringvar_idx);
%     labels_out = convertvars(labels_out,stringvar_names,'categorical');
end


