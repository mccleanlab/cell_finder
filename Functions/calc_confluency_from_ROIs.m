function [cell_measurements_confluency, mask_out] = calc_confluency_from_ROIs(cell_measurements,images)

% Get iminfo
number_frames = images.iminfo.nf;
number_positions = images.iminfo.np;
im_width = images.iminfo.w;
im_height = images.iminfo.h;

theta = 0:0.1:2*pi;

idx = 1;
cell_measurements_confluency = cell(number_positions*number_frames,1);
mask_out = zeros(im_height,im_width,number_frames,number_positions,'uint8');

%Cycle through positions
for p = 1:number_positions
    
    % Cycle through frames
    for f = 1:number_frames
        
        disp(['Calculating confluency: frame ' num2str(f) ' position ' num2str(p)])
        
        % Get measurements for current frame
        cell_measurements_temp = cell_measurements(cell_measurements.frame==f & cell_measurements.position==p,:);
        number_cells = size(cell_measurements_temp,1);
        
        % Get coordinates of cell borders
        xCell = (cell_measurements_temp.rCell * cos(theta) + cell_measurements_temp.cCellX)';
        yCell = (cell_measurements_temp.rCell * sin(theta) + cell_measurements_temp.cCellY)';
        
        % Convert coordinates of cell borders to mask and get pixel indices
        parfor c = 1:number_cells
            mask_cell = poly2mask(xCell(:,c),yCell(:,c),im_height,im_width);
            idx_cell{:,c} = find(mask_cell);
        end
        
        % Create mask of all cells from ROIs
        mask_temp = zeros(im_height,im_width,'logical');
        for c = 1:number_cells
            mask_temp(idx_cell{:,c})=1;
        end       
        
        % Dilate and fill in holes in mask
        mask_temp = imdilate(mask_temp,strel('disk',3));
        mask_temp = bwmorph(mask_temp,'bridge');
        mask_temp = imfill(mask_temp,8,'holes');
        
        % Calculate confluency based on mask        
        confluency = sum(mask_temp,'all')/(im_height*im_width);%         
        cell_measurements_temp.confluency(:,1) = confluency;
        
        mask_out(:,:,f,p) = mask_temp;
        cell_measurements_confluency{idx} = cell_measurements_temp;
        idx = idx + 1;
    end
end

cell_measurements_confluency = vertcat(cell_measurements_confluency{:});