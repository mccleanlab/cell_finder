function [images, params, im] = load_ND2(image_list,image_idx,channel_list,number_positions,params)
% numFrames = [];
% numPositions = 8;
% imidx = 1;
% imagelist = selectImages();

% Get file to load
im_file = image_list{image_idx};
[folder, filename, ext] = fileparts(im_file);
disp(['Loading ' filename]);

% Use Bio-Formats to open .ND2 file
im = bfopen(im_file);

% Get number of positions/series
number_series = size(im,1);
if isempty(number_positions)
    number_positions =1;
end

%%

for series = 1:number_series
    
    number_planes = size(im{series,1},1);
    
    for plane = 1:number_planes
%         imdata = [];
%         planelabel = [];
        % Get image data and plane label
        im_data = im{series,1}{plane,1};
        plane_label = im{series,1}{plane,2};
        
        % Get channel from plane label
        channel = regexp(plane_label,'C\?=\d*/\d*|C=\d*/\d*','match');
        channel = regexprep(channel,'\C=|\C\?=','');
        channel = regexprep(channel,'\/\d*','');
        channel = str2double(channel);
        channel_name = channel_list(channel);
        channel_name = channel_name{:};
        
        % Get frame name from plane label
        frame = regexp(plane_label,'T\?=\d*/\d*|T=\d*/\d*','match');
        frame = regexprep(frame,'\T=|\T\?=','');
        frame = regexprep(frame,'\/\d*','');
        frame = str2double(frame);
        
        % If no frame value, set as 1
        if isempty(frame)
            frame = 1;
        end        
        
        % If multiple positions, set position as series, else set as 1
        if number_positions~=1
            position = series;  
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
    end    
end

% Save image dimensions
images.iminfo.h = size(images.(channel_list{1}),1);
images.iminfo.w = size(images.(channel_list{1}),2);
images.iminfo.nf = size(images.(channel_list{1}),3);
images.iminfo.np = size(images.(channel_list{1}),4);

% Get and save image info
params.sourceFile = filename;
params.outputFolder = fullfile(folder, 'output');

