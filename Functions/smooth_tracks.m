function data_smooth = smooth_tracks(data_in,variables_to_smooth_list,filter_size_list)

track_list = unique(data_in.track_ID,'stable');
% frame_list = unique(data_in.frame,'stable');
% position_list = unique(data_in.position,'stable');
% data_smooth = {};

number_variables_to_smooth = numel(variables_to_smooth_list);
number_tracks = numel(track_list);

% for i = 1:number_variables_to_smooth
data_smooth = cell(number_tracks,1);


parfor c = 1:number_tracks
    track_to_smooth = track_list(c);
    data_smooth_temp = data_in(data_in.track_ID==track_to_smooth,:);
    
    for jj = 1:number_variables_to_smooth
        variable_to_smooth_temp = variables_to_smooth_list{jj};
        filter_size_temp = filter_size_list{jj};
        data_smooth_temp.(variable_to_smooth_temp) = smooth(data_smooth_temp.(variable_to_smooth_temp),filter_size_temp)
    end
    
    data_smooth{c} = data_smooth_temp;
    
end
% end

data_smooth = vertcat(data_smooth{:});
