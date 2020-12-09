function labels_out = get_labels(label_file)

if exist('label_file','var')~=1    
    % Load plate map
    [file, folder] =  uigetfile('.xlsx','Select plate map','MultiSelect','on');
    opts = detectImportOptions([folder file]);
    opts = setvartype(opts, 'char');
    opts.DataRange = 'A1';
    opts.Sheet = 'plate_map';
    plate_map_raw = readtable([folder file], opts);
else
    opts = detectImportOptions(label_file);
    opts = setvartype(opts, 'char');
    opts.DataRange = 'A1';
    opts.Sheet = 'plate_map';
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
% well_list = reshape(map.well',plateDim(1)*plateDim(2),1);

%% Add labels from plate map
label_list = regexp(plate_map_raw{:,:},'map_\w*','match');
label_list = string(label_list(~cellfun('isempty',label_list)));

labels_out = table();
labels_out.well = reshape(map.well',96,1);

for n = 1:numel(label_list)
    label = label_list{n};
    [w, kc] = find(strcmp(label,plate_map_raw{:,:}));
    w = w+1:w+plateDim(1);
    kc = kc+1:kc+plateDim(2);
    label = erase(label,'map_');
    map.(label) = string(plate_map_raw{w,kc});
    
    labels_out.(label) = reshape(map.(label)',96,1);
end

% Remove unused
idx = ~any(cellfun(@isempty,labels_out{:,:}),2);
labels_out = labels_out(idx,:);
