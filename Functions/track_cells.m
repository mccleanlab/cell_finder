function cell_tracks = track_cells(data_in,feature_to_track,max_link_dist,max_gap_close)

% dataIn = cellFilter;
% trackVar = 'Cells';
% maxLinkDist = 10;
% maxGapClose = 3;

number_frames = max(data_in.frame(:));
number_positions =  max(data_in.position(:));

idx = 1;
track_data = {};
% track_data = cell(number_positions*number_frames,1);


for p = 1:number_positions
    data_current_position = data_in(data_in.position==p,:);
    
    disp(strcat("Tracking cells: position ",num2str(p)," formatting data for simpletracker"));
%     disp('formatting data for simpletracker');
    
    % Format data for simpletracker
    
    track_ID_list_temp = cell(number_frames,1);
    feature_position = cell(number_frames,1);
    
    for f = 1:number_frames
        data_temp = data_current_position(data_current_position.frame==f,:);
        
        track_ID_list_temp(f) = {data_temp.ID};
        
        if strcmp(feature_to_track,'nuclei')
            feature_position(f) = {[data_temp.cNucX, data_temp.cNucY]};
        elseif strcmp(feature_to_track,'cells')
            feature_position(f) = {[data_temp.cCellX data_temp.cCellY]};
        end
    end
    
    if size(feature_position,1)<size(feature_position,2)
        feature_position = feature_position';
    end
    
    disp(strcat("Tracking cells: position ",num2str(p)," running simpletracker"));
    
    % Track data with simpletracker
    [~, idx_global] = simpletracker(feature_position,'MaxLinkingDistance', max_link_dist,'MaxGapClosing', max_gap_close);
    
    % Format output data
    disp(strcat("Tracking cells: position ",num2str(p)," formatting tracks for output"));
    
%     all_points = vertcat(points{:});
    track_ID_list = vertcat(track_ID_list_temp{:});
    
    
    for c = 1:numel(idx_global)
        track_data_temp = table();
        idx_cell = idx_global{c,1};
        
        track_data_temp.ID(:,1) = track_ID_list(idx_cell);
        track_data_temp.position(:,1) = p;
        track_data_temp.track_ID(:,1) = idx;
        
        track_data{idx} = track_data_temp;
        idx = idx + 1;
    end
end

% Collect tracks and append to data table
track_data = vertcat(track_data{:});
cell_tracks = innerjoin(data_in,track_data);

% Calculate lifespan per track ID
track_ID_lifespan = grpstats(cell_tracks,'track_ID','numel','DataVars','track_ID');
track_ID_lifespan = clean_grpstats(track_ID_lifespan);
track_ID_lifespan.Properties.VariableNames(end) = {'lifespan'};
cell_tracks = outerjoin(cell_tracks, track_ID_lifespan, 'Type', 'Left', 'MergeKeys', true);

% Sort data for output
cell_tracks = sortrows(cell_tracks,{'track_ID','frame'},{'Ascend','Ascend'});
