function cell_measurements = measureCells(images,channel_list,cell_ROIs,params)

[h, w, number_frames, number_positions] = size(images.(channel_list{1}));
theta = 0:0.1:2*pi;

idx = 1;
cell_measurements = cell(number_positions*number_frames,1);

%Cycle through positions
for p = 1:number_positions
    
    % Cycle through frames
    for f = 1:number_frames
        
        try
            disp(['Measuring cells: frame ' num2str(f) ' position ' num2str(p)])
            
            % Create table for cells at current frame and position
            cell_meausurements_temp = cell_ROIs(cell_ROIs.Frame==f & cell_ROIs.Position==p,:);
            number_cells_temp = size(cell_meausurements_temp,1);
            
            % If no nuclear ROIs, get pixel indices for each cell
            if ~contains('rNuc', cell_ROIs.Properties.VariableNames)
                xCell = (cell_meausurements_temp.rCell * cos(theta) + cell_meausurements_temp.cCellX)';
                yCell = (cell_meausurements_temp.rCell * sin(theta) + cell_meausurements_temp.cCellY)';
                
                % Convert coordinates of cell borders to mask and get pixel indices                
                parfor c = 1:number_cells_temp
                    mask_cell = poly2mask(xCell(:,c),yCell(:,c),h,w);
                    idx_cell{:,c} = find(mask_cell);
                end
              
            % If nuclear ROIs, get pixel indices for each cell, nucleus, and cytosol
            elseif contains('rNuc', cell_ROIs.Properties.VariableNames)
                xCell = (cell_meausurements_temp.rCell * cos(theta) + cell_meausurements_temp.cCellX)';
                yCell = (cell_meausurements_temp.rCell * sin(theta) + cell_meausurements_temp.cCellY)';
                xNuc = (cell_meausurements_temp.rNuc * cos(theta) + cell_meausurements_temp.cNucX)';
                yNuc = (cell_meausurements_temp.rNuc * sin(theta) + cell_meausurements_temp.cNucY)';
                xNucDilate = ((cell_meausurements_temp.rNuc + params.nucDilate) * cos(theta) + cell_meausurements_temp.cNucX)';
                yNucDilate = ((cell_meausurements_temp.rNuc + params.nucDilate) * sin(theta) + cell_meausurements_temp.cNucY)';
                
                % Convert coordinates of cell,nucleus, and cytosol borders to masks and get pixel indices                
                parfor c = 1:number_cells_temp
                    mask_cell = poly2mask(xCell(:,c),yCell(:,c),h,w);
                    mask_nuc = poly2mask(xNuc(:,c),yNuc(:,c),h,w);
                    mask_nuc_dilate = poly2mask(xNucDilate(:,c),yNucDilate(:,c),h,w);
                    mask_cyto = mask_cell - mask_nuc_dilate;
                    
                    idx_cell{:,c} = find(mask_cell);
                    idx_nuc{:,c} = find(mask_nuc);
                    idx_cyto{:,c} = find(mask_cyto);
                end
            end
            
            % Create mask from indices of all cells (to identify background)
            mask_to_measure = zeros(h,w,'logical');
            for c = 1:number_cells_temp
                mask_to_measure(idx_cell{:,c})=1;
            end
            
            % Cycle through channels and measure intensity per cell
            for i = 1:numel(channel_list)
                
                % Set image to measure and replace zeros with nan
                channel = channel_list{i};
                im_to_measure = images.(channel)(:,:,f,p);
                im_to_measure = double(im_to_measure);
                im_to_measure(im_to_measure==0)=nan;
                
                % Calculate background intensity (mode outside of cells)
                BG = mode(im_to_measure(~mask_to_measure),'all');
                
                % If no nuclear ROIs, measure cells only
                if ~contains('rNuc', cell_ROIs.Properties.VariableNames)
                    
                    % Make array of cell measurements for channel
                    cell_measurements_channel = cell(1,number_cells_temp);
                    parfor c = 1:number_cells_temp
                        current_cell_measurements = double(im_to_measure(idx_cell{c}));
                        current_cell_measurements = sort(current_cell_measurements(~isnan(current_cell_measurements)),'descend');
                        cell_measurements_channel{:,c} = current_cell_measurements;
                    end
                    
                    % Convert  array of cell measurements to double
                    cell_number_pixels_max = max(cell2mat(cellfun(@length,cell_measurements_channel,'uni',false)));
                    cell_measurements_channel_double = nan(cell_number_pixels_max,number_cells_temp);
                    
                    for c = 1:number_cells_temp
                        cell_measurements_channel_double(1:length(cell_measurements_channel{c}),c) = cell_measurements_channel{c};
                    end
                    
                % If nuclear ROIs, measure cells, nuclei, and cytosol
                elseif contains('rNuc', cell_ROIs.Properties.VariableNames)
                    
                    % Make array of cell measurements for channel
                    cell_measurements_channel = cell(1,number_cells_temp);
                    nuc_measurements_channel = cell(1,number_cells_temp);
                    cyto_measurements_channel= cell(1,number_cells_temp);
                    
                    parfor c = 1:number_cells_temp
                        current_cell_measurements = double(im_to_measure(idx_cell{c}));
                        current_cell_measurements = sort(current_cell_measurements(~isnan(current_cell_measurements)),'descend');
                        current_nuc_measurements = double(im_to_measure(idx_nuc{c}));
                        current_nuc_measurements = sort(current_nuc_measurements(~isnan(current_nuc_measurements)),'descend');
                        current_cyto_measurements = double(im_to_measure(idx_cyto{c}));
                        current_cyto_measurements = sort(current_cyto_measurements(~isnan(current_cyto_measurements)),'descend');
                        
                        cell_measurements_channel{:,c} = current_cell_measurements;
                        nuc_measurements_channel{:,c} = current_nuc_measurements;
                        cyto_measurements_channel{:,c} = current_cyto_measurements;
                    end
                    
                    % Convert  array of cell measurements to double
                    cell_number_pixels_max = max(cell2mat( cellfun(@length,cell_measurements_channel,'uni',false)));
                    cell_measurements_channel_double = nan(cell_number_pixels_max,number_cells_temp);
                    nuc_number_pixels_max = max(cell2mat( cellfun(@length,nuc_measurements_channel,'uni',false)));
                    nuc_measurements_channel_double = nan(nuc_number_pixels_max,number_cells_temp);
                    cyto_number_pixels_max = max(cell2mat( cellfun(@length,cyto_measurements_channel,'uni',false)));
                    cyto_measurements_channel_double = nan(cyto_number_pixels_max,number_cells_temp);
                    
                    for c = 1:number_cells_temp
                        cell_measurements_channel_double(1:length(cell_measurements_channel{c}),c) = cell_measurements_channel{c};
                        nuc_measurements_channel_double(1:length(nuc_measurements_channel{c}),c) = nuc_measurements_channel{c};
                        cyto_measurements_channel_double(1:length(cyto_measurements_channel{c}),c) = cyto_measurements_channel{c};
                    end
                end
                
                % Fill empty arrays with nan to avoid errors when measuring
                if isempty(cell_measurements_channel_double)
                    cell_measurements_channel_double = nan(15,size(cell_measurements_channel_double,2));
                end
                
                if exist('nuc_measurements_channel_double','var') && isempty(nuc_measurements_channel_double)
                    nuc_measurements_channel_double = nan(15,size(nuc_measurements_channel_double,2));
                end
                
                if exist('cyto_measurements_channel_double','var') && isempty(cyto_measurements_channel_double)
                    cyto_measurements_channel_double = nan(15,size(cyto_measurements_channel_double,2));
                end
                
                % Measure cells
                cell_meausurements_temp.([channel '_mode'])(:,1) = double(images.([channel '_mode'])(f,p));
                cell_meausurements_temp.([channel '_BG'])(:,1) = BG;
                cell_meausurements_temp.([channel '_cell_mean'])(:,1) = nanmean(cell_measurements_channel_double);
                cell_meausurements_temp.([channel '_cell_median'])(:,1) = nanmedian(cell_measurements_channel_double);
                cell_meausurements_temp.([channel '_cell_mode'])(:,1) = mode(cell_measurements_channel_double);
                cell_meausurements_temp.([channel '_cell_SD'])(:,1) = nanstd(cell_measurements_channel_double);
                cell_meausurements_temp.([channel '_cell_max'])(:,1) = nanmax(cell_measurements_channel_double);
                cell_meausurements_temp.([channel '_cell_min'])(:,1) = nanmin(cell_measurements_channel_double);
                cell_meausurements_temp.([channel '_cell_sum'])(:,1) = nansum(cell_measurements_channel_double);
                cell_meausurements_temp.([channel '_cell_upperquartile'])(:,1) = quantile(cell_measurements_channel_double,0.75);
                cell_meausurements_temp.([channel '_cell_lowerquartile'])(:,1) = quantile(cell_measurements_channel_double,0.25);
                cell_meausurements_temp.([channel '_cell_95prctile'])(:,1) = quantile(cell_measurements_channel_double,0.95);
                cell_meausurements_temp.([channel '_cell_5prctile'])(:,1) = quantile(cell_measurements_channel_double,0.05);
                
                cell_meausurements_temp.([channel '_cell_max15px'])(:,1) = nanmean(cell_measurements_channel_double(1:14,:));
                cell_meausurements_temp.([channel '_cell_dimpx'])(:,1) = nanmean(cell_measurements_channel_double(14:end,:));
                
                % Measure subcellular compartments if nuclear marker present
                if contains('rNuc', cell_ROIs.Properties.VariableNames)
                    cell_meausurements_temp.([channel '_nuclear_mean'])(:,1) = nanmean(nuc_measurements_channel_double);
                    cell_meausurements_temp.([channel '_nuclear_median'])(:,1) = nanmedian(nuc_measurements_channel_double);
                    cell_meausurements_temp.([channel '_nuclear_mode'])(:,1) = mode(nuc_measurements_channel_double);
                    cell_meausurements_temp.([channel '_nuclear_SD'])(:,1) = nanstd(nuc_measurements_channel_double);
                    cell_meausurements_temp.([channel '_nuclear_max'])(:,1) = nanmax(nuc_measurements_channel_double);
                    cell_meausurements_temp.([channel '_nuclear_min'])(:,1) = nanmin(nuc_measurements_channel_double);
                    cell_meausurements_temp.([channel '_nuclear_sum'])(:,1) = nansum(nuc_measurements_channel_double);
                    cell_meausurements_temp.([channel '_nuclear_upperquartile'])(:,1) = quantile(nuc_measurements_channel_double,0.75);
                    cell_meausurements_temp.([channel '_nuclear_lowerquartile'])(:,1) = quantile(nuc_measurements_channel_double,0.25);
                    cell_meausurements_temp.([channel '_nuclear_95prctile'])(:,1) = quantile(nuc_measurements_channel_double,0.95);
                    cell_meausurements_temp.([channel '_nuclear_5prctile'])(:,1) = quantile(nuc_measurements_channel_double,0.05);
                    
                    cell_meausurements_temp.([channel '_cyto_mean'])(:,1) = nanmean(cyto_measurements_channel_double);
                    cell_meausurements_temp.([channel '_cyto_median'])(:,1) = nanmedian(cyto_measurements_channel_double);
                    cell_meausurements_temp.([channel '_cyto_SD'])(:,1) = nanstd(cyto_measurements_channel_double);
                    cell_meausurements_temp.([channel '_cyto_max'])(:,1) = nanmax(cyto_measurements_channel_double);
                    cell_meausurements_temp.([channel '_cyto_min'])(:,1) = nanmin(cyto_measurements_channel_double);
                    cell_meausurements_temp.([channel '_cyto_sum'])(:,1) = nansum(cyto_measurements_channel_double);
                    cell_meausurements_temp.([channel '_cyto_upperquartile'])(:,1) = quantile(cyto_measurements_channel_double,0.75);
                    cell_meausurements_temp.([channel '_cyto_lowerquartile'])(:,1) = quantile(cyto_measurements_channel_double,0.25);
                    cell_meausurements_temp.([channel '_cyto_95prctile'])(:,1) = quantile(cyto_measurements_channel_double,0.95);
                    cell_meausurements_temp.([channel '_cyto_5prctile'])(:,1) = quantile(cyto_measurements_channel_double,0.05);
                end
            end
            cell_measurements{idx} = cell_meausurements_temp;
            idx = idx + 1;
            
        catch
            disp(['No cells in frame ' num2str(f) ' position ' num2str(p)])
        end
    end
end

cell_measurements = vertcat(cell_measurements{:});

