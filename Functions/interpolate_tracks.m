function data_interpolate = interpolate_tracks(data_in,params,remove_overlap,max_gap)

data_in = sortrows(data_in,{'track_ID','frame'},{'Ascend','Ascend'});



% Get list of tracks, frames, and positions
track_list = unique(data_in.track_ID,'stable');
frame_list = unique(data_in.frame,'stable');
position_list = unique(data_in.position,'stable');

% Calculate number for tracks, frames, and positions
number_frames = numel(frame_list);
number_positions = numel(position_list);
number_tracks = numel(track_list);

data_interpolate = cell(number_tracks,1);

parfor track = 1:number_tracks
    
    % Load track data (no rows for frames where track does not exist)
    track_current = track_list(track);
    data_temp = data_in(data_in.track_ID==track_current,:);
    position = unique(data_temp.position);
    assignin('base','data_temp',data_temp);
    assignin('base','track',track);
    
    % Create new expanded table with rows for all frames
    data_interpolate_temp = table();
    data_interpolate_temp.frame(:,1) = frame_list;
    data_interpolate_temp.position(:,1) = position;
    data_interpolate_temp.track_ID(:,1) = track_current;    
    
    data_interpolate_temp.cCellX(:,1) = nan(number_frames,1);
    data_interpolate_temp.cCellY(:,1) = nan(number_frames,1);
    data_interpolate_temp.rCell = nan(number_frames,1);
    data_interpolate_temp.mCell = nan(number_frames,1);

    data_interpolate_temp.cCellX(data_temp.frame) = data_temp.cCellX;
    data_interpolate_temp.cCellY(data_temp.frame) = data_temp.cCellY;
    data_interpolate_temp.rCell(data_temp.frame) = data_temp.rCell;
    data_interpolate_temp.mCell(data_temp.frame) = data_temp.mCell;
    
    if contains('rNuc',data_in.Properties.VariableNames)
        data_interpolate_temp.cNucX(:,1) = nan(number_frames,1);
        data_interpolate_temp.cNucY(:,1) = nan(number_frames,1);
        data_interpolate_temp.rNuc = nan(number_frames,1);
        data_interpolate_temp.mNuc = nan(number_frames,1);
        
        data_interpolate_temp.cNucX(data_temp.frame) = data_temp.cNucX;
        data_interpolate_temp.cNucY(data_temp.frame) = data_temp.cNucY;
        data_interpolate_temp.rNuc(data_temp.frame) = data_temp.rNuc;
        data_interpolate_temp.mNuc(data_temp.frame) = data_temp.mNuc;
    end
    
    % Calculate track gap lengths
    connected_components = bwconncomp(isnan(data_interpolate_temp.rCell));
    assignin('base','connected_components',connected_components)
    number_values_connected = cellfun('prodofsize',connected_components.PixelIdxList);
    gap_length = zeros(size(data_interpolate_temp.rCell));
    for ii = 1:connected_components.NumObjects
        gap_length(connected_components.PixelIdxList{ii}) = number_values_connected(ii);
    end
    data_interpolate_temp.gap = gap_length;
    
    % Delete ROIs for gaps > max gap and remaining interpolate gaps 
    data_interpolate_temp(data_interpolate_temp.gap>max_gap,:) = []; % Delete rows for gaps > max gap
    data_interpolate_temp = fillmissing(data_interpolate_temp,'linear','EndValues','none'); % Interpolate tracks
    data_interpolate{track} = data_interpolate_temp; % Collect track into big table
    
end

% Collect data into table and remove rows with missing entries
data_interpolate = vertcat(data_interpolate{:});
data_interpolate = rmmissing(data_interpolate);

% Calculate track lifespan
track_ID_lifespan = grpstats(data_interpolate,'track_ID','numel','DataVars','track_ID');
track_ID_lifespan = clean_grpstats(track_ID_lifespan);
track_ID_lifespan.Properties.VariableNames(end) = {'lifespan'};

data_interpolate = join(data_interpolate,track_ID_lifespan);

% data_interpolate =  calcLifespan(data_interpolate); % Calculate lifespan of interpolated track
data_interpolate.ID(:,1) = randperm(size(data_interpolate,1)); % Generate new unique IDs

%% Remove overlaping cells created by interpolation

idx = 1;
track_ID_to_delete = cell(number_frames*number_positions,1);

if remove_overlap==true
    for p = 1:number_positions
        
        for f = 1:number_frames
            
            data_remove_overlap_temp = data_interpolate(data_interpolate.frame==f & data_interpolate.position==p,:);
            
            % Remove overlapping cell with shortest lifespan
            [centers_new, ~, ~] = remove_overlap_by_metric([data_remove_overlap_temp.cCellX, data_remove_overlap_temp.cCellY],data_remove_overlap_temp.rCell,0.5*params.sizeCell(2),4,data_remove_overlap_temp.lifespan);
            
            idx_delete_temp = ~ismember(data_remove_overlap_temp.cCellX,centers_new(:,1)) & ~ismember(data_remove_overlap_temp.cCellY,centers_new(:,2));
            track_ID_to_delete{idx,1} = data_remove_overlap_temp.ID(idx_delete_temp);
            idx = idx + 1;
        end
        
    end
end

track_ID_to_delete = vertcat(track_ID_to_delete{:});
idx_delete = ismember(data_interpolate.ID,track_ID_to_delete);

data_interpolate(idx_delete,:) = [];
