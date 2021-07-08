function [images, params] = load_ND2_metadata(image_list,im_idx,channel_list,number_positions,params)
% image_list = selectImages();
% n_frames = [];
% n_positions = 4;
% im_idx = 1;
% channel_list = {'DIC','GFP','mCherry'};

% Select image from list
im_file = image_list{im_idx};
[folder, filename, ext] = fileparts(im_file);

disp(['Loading ' filename]);

% Load selected image
im = bfopen(im_file);
number_series = size(im,1);

% Set number of positions to one if needed
if isempty(number_positions)
    number_positions =1;
end

im_metadata = cell(number_series,1);

% Loop through series/planes and extract images.
for series = 1:number_series
    number_planes = size(im{series,1},1);
    
    metadata_raw = string(im{series,2});
    timestamps = regexp(metadata_raw,'((?<=timestamp #).*?(?=\,))','match');
    time_list = string(regexp(timestamps,'\=\d*\.\d*','match'));
    time_list = double(string(regexp(time_list,'\d*\.\d*','match')));
    time_list = flip(time_list)';
    
    for plane = 1:number_planes
        
        % Reset variables
%         im_data = [];
%         plane_label = [];
        
        % Get image data and plane label
        im_data = im{series,1}{plane,1};
        plane_label = im{series,1}{plane,2};
        
        % Get channel info
        channel = regexp(plane_label,'C\?=\d*/\d*|C=\d*/\d*','match');
        channel = regexprep(channel,'\C=|\C\?=','');
        channel = regexprep(channel,'\/\d*','');
        channel = str2double(channel);
                
        channel_name = channel_list(channel);
        channel_name = channel_name{:};
        
        % Get frame info
        frame = regexp(plane_label,'T\?=\d*/\d*|T=\d*/\d*','match');
        frame = regexprep(frame,'\T=|\T\?=','');
        frame = regexprep(frame,'\/\d*','');
        frame = str2double(frame);
        
        % Set frame to one if not found
        if isempty(frame)
            frame = 1;
        end
        
        % Set number of positions
        if number_positions~=1
            position = series;
        elseif any(ismember(fieldnames(params),'frame_position_switch')) && params.frame_position_switch==true % Flip position/frame if needed (sometimes .ND2 files organized incorrectly)
            position = frame;
            frame = series;
        else
            position = 1;
        end
        
        % Get image data for channel
        images.(channel_name)(:,:,frame,position) = im_data;        
       
        % Calculate image BG intensity by finding image mode
        im_mode = mode(im_data(:));
        
        % Exclude likely saturated pixels in calculation of image mode
        if im_mode > prctile(im_data(:),95)
            disp(['Warning: Excluding likely saturated pixel values from mode calculation for ' filename ext ' ' channel_name ' frame ' num2str(frame) ' position ' num2str(position)]);
            im_mode = mode(im_data(im_data~=im_mode));
        end
        
        % Set BG intensity from mode intensity
        images.([channel_name '_mode'])(frame,position) = im_mode;
        
        if params.frame_position_switch==true
            metadata_temp = table('Size',[1, 4],'VariableTypes',{'string','int32','int32','double'},'VariableNames',{'sourceFile','Frame','Position','Time'});
            metadata_temp.sourceFile(:,1) = string(filename);
            metadata_temp.Frame(:,1) = frame;
            metadata_temp.Position(:,1) = position;
            metadata_temp.Time(:,1) = time_list(frame);
        end
        
    end
    
    
    if params.frame_position_switch==false
        %  Get metadata for series (not tested for multiple positions)
        metadata_raw = string(im{series,2});
        timestamps = regexp(metadata_raw,'((?<=timestamp #).*?(?=\,))','match');
        time = string(regexp(timestamps,'\=\d*\.\d*','match'));
        time = double(string(regexp(time,'\d*\.\d*','match')));
        time = flip(time)';
        
        metadata_temp = table('Size',[frame, 4],'VariableTypes',{'string','int32','int32','double'},'VariableNames',{'sourceFile','Frame','Position','Time'});
        metadata_temp.sourceFile(:,1) = string(filename);
        metadata_temp.frame(:,1) = (1:frame)';
        metadata_temp.position(:,1) = position;
        metadata_temp.time(:,1) = time;
    end
    
    % Collect metadata
    im_metadata{series,1} = metadata_temp;
end

im_metadata = vertcat(im_metadata{:});
images.metadata = im_metadata;

% Get and save image info
images.iminfo.h = size(images.(channel_list{1}),1);
images.iminfo.w = size(images.(channel_list{1}),2);
images.iminfo.nf = size(images.(channel_list{1}),3);
images.iminfo.np = size(images.(channel_list{1}),4);

% Get and save image info
params.sourceFile = filename;
params.outputFolder = fullfile(folder, 'output');

