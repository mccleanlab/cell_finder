function cell_ROIs = find_cells(images,channel_nuc,channel_cell,params,preprocess_imNuc,preprocess_imCell)

% If nuclear image, get image parameters (mode, # frames, # positions)
if ~isempty(channel_nuc)
    im_nuc = images.(channel_nuc);
    disp('Finding paired cell/nucleus ROIs')
    params.nuc_mode = mode(images.([channel_nuc '_mode']),'all');
    params.nuc_stretchlim = stretchlim(im_nuc(:) - params.nuc_mode);
    [~, ~, number_frames, number_positions] = size(im_nuc);
else
    im_nuc = [];
    disp('Finding cell ROIs only')
end

% If nuclear image, get image parameters (# frames, # positions)
if ~isempty(channel_cell)
    im_cell = images.(channel_cell);
    [~, ~, number_frames, number_positions] = size(im_cell);
else
    im_cell = [];
end

idx = 1;
cell_ROIs = cell(number_positions*number_frames,1);

%Cycle through stage positions
for p = 1:number_positions
    
    % Cycle through frames
    for f = 1:number_frames
        cell_ROIs_temp = table();
        display_ROI = true;
        
        disp(['     frame ' num2str(f) ' position ' num2str(p)])
        
        % Preprocess nuclear images
        if ~isempty(im_nuc)
            im_nuc_current = im_nuc(:,:,f,p);
            im_nuc_current(im_nuc_current==0)=mode(im_nuc_current(im_nuc_current~=0),'all');
            [im_nuc_current, params] = preprocess_imNuc(im_nuc_current,params);
            nuc_edgethresh = params.nucEdgeThresh;
        end
        
        % Preprocess cell images
        if ~isempty(im_cell)
            im_cell_current = im_cell(:,:,f,p);
            im_cell_current(im_cell_current==0)=mode(im_cell_current(im_cell_current~=0),'all');
            [im_cell_current, params] = preprocess_imCell(im_cell_current,params);
            %                         cellEdgeThresh = params.cellEdgeThresh*graythresh(imCell0);
            cell_edgethresh = params.cellEdgeThresh;
        end
        
        clearvars cNuc rNuc cCell rCell
        
        % If nuclear image, use to find potential nuclear ROIs
        if ~isempty(im_nuc)
            
            % Find center, radius, and metric of nuclear ROIs
            [cNuc, rNuc, mNuc] = imfindcircles(im_nuc_current,params.sizeNuc,'ObjectPolarity',params.nucPolarity,'Sensitivity',params.nucSensitivity,'Method','PhaseCode','EdgeThreshold',nuc_edgethresh);
            
            % Remove nuclei that are too close together
            if ~isempty(params.nucOverlapThresh) && size(cNuc,1)>1
                [cNuc, rNuc, mNuc] = remove_overlap_by_metric(cNuc,rNuc,params.nucOverlapThresh.*params.sizeCell(1),4,mNuc);
            end
            
            % Force nuclei to size range (counters dilation due to image preprocessing)
            if ~isempty(params.sizeNucForce) && size(cNuc,1)>1
                rNuc(rNuc<params.sizeNucForce(1)) = params.sizeNucForce(1);
                rNuc(rNuc>params.sizeNucForce(2)) = params.sizeNucForce(2);
            end
        end
        
        % If cell image, use to find potential cell ROIs
        if ~isempty(im_cell)
            assignin('base','im_cell_current',im_cell_current)
            % Find cell ROIs from image
            [cCell, rCell, mCell] = imfindcircles(im_cell_current,params.sizeCell,'ObjectPolarity',params.cellPolarity,'Sensitivity',params.cellSensitivity,'Method','TwoStage','EdgeThreshold',cell_edgethresh);
%             length(rCell)
            [cCell, rCell, mCell] = imfindcircles(im_cell_current,params.sizeCell,'ObjectPolarity',params.cellPolarity,'Sensitivity',params.cellSensitivity,'Method','TwoStage','EdgeThreshold',params.cellEdgeThresh);

            % If no cell image, dilate nuclear ROIs to approximate cell location
        else
            cCell = cNuc;
            rCell = rNuc*params.nucToCellScale;
            mCell = mNuc;
        end
        
        % If cells found, process
        if ~isempty(rCell)
            
            % Remove overlapping cells
            if ~isempty(params.cellOverlapThresh) && size(cCell,1)>1
                [cCell, rCell, mCell] = remove_overlap_by_metric(cCell,rCell,params.cellOverlapThresh*params.sizeCell(2),4,mCell);
            end
            
            % Force cells to size range
            if ~isempty(params.sizeCellForce)
                rCell(rCell<params.sizeCellForce(1)) = params.sizeCellForce(1);
                rCell(rCell>params.sizeCellForce(2)) = params.sizeCellForce(2);
            end
            
            % Scale cells (decrease radius to reduce unintended capture of BG)
            if ~isempty(params.sizeCellScale)
                rCell = params.sizeCellScale*rCell;
            end
            
            % If no nuclear image, save only cell ROIs
            if isempty(im_nuc)

                % Save cell ROIs
                number_cells = numel(rCell);
                cell_ROIs_temp.frame(1:number_cells,1) = f;
                cell_ROIs_temp.position(1:number_cells,1) = p;
                cell_ROIs_temp.ID(1:number_cells,1) = randi(1E9);
                cell_ROIs_temp.cCellX(1:number_cells,1) = cCell(:,1);
                cell_ROIs_temp.cCellY(1:number_cells,1) = cCell(:,2);
                cell_ROIs_temp.rCell(1:number_cells,1) = rCell(:);
                cell_ROIs_temp.mCell(1:number_cells,1) = mCell(:);
                
                % If no cell image and nuclei found
            elseif isempty(im_cell) && ~isempty(rNuc)
                
                % Save cell ROIs
                number_cells = numel(rCell);
                cell_ROIs_temp.frame(1:number_cells,1) = f;
                cell_ROIs_temp.position(1:number_cells,1) = p;
                cell_ROIs_temp.cCellX(1:number_cells,1) = cCell(:,1);
                cell_ROIs_temp.cCellY(1:number_cells,1) = cCell(:,2);
                cell_ROIs_temp.rCell(1:number_cells,1) = rCell;
                cell_ROIs_temp.mCell(1:number_cells,1) = mCell;
                
                % Recalculate rNuc from rCell because, in this case, we
                % generated cell ROIs by scaling up nuclei then removed
                % overlapping cells without removing the corresponding
                % nuclei. To compensate we just rescale to cells to get
                % back our nuclei
                rNuc = rCell/params.nucToCellScale;
                
                % Save nuclei ROIs
                cell_ROIs_temp.cNucX(1:number_cells,1) = cCell(:,1);
                cell_ROIs_temp.cNucY(1:number_cells,1) = cCell(:,2);
                cell_ROIs_temp.rNuc(1:number_cells,1) = rNuc;
                cell_ROIs_temp.mNuc(1:number_cells,1) = mCell;
                cell_ROIs_temp.mNuc(1:number_cells,1) = mCell;
                
                % If nuclear and cell images and nuclei found, pair up cells/nuclei
            elseif ~isempty(im_nuc) && ~isempty(im_cell) && ~isempty(rNuc)
                
                % Combine coordinates of cells and nuclei
                cell_nuc_positions = [cCell; cNuc];
                cell_nuc_radii = [rCell; rNuc];
                
                % Find potential pairs of cells
                radii_sum = cell_nuc_radii(:) + cell_nuc_radii(:)';
                cell_nuc_distance = sqrt((cell_nuc_positions(:,1) - cell_nuc_positions(:,1)').^2 + (cell_nuc_positions(:,2) - cell_nuc_positions(:,2)').^2 );
                %                 idx_potential_pairs = cell_nuc_distance <= params.nucCellOverlapThresh*radii_sum;
                %                 idx_potential_pairs(1:size(cell_nuc_positions,1)+1:end) = false;
                potential_pairs = cell_nuc_distance <= params.nucCellOverlapThresh*radii_sum;
                potential_pairs(1:size(cell_nuc_positions,1)+1:end) = false;
                
                % Simplify and reorder indices of potential pairs
                number_cells = length(rCell);
                potential_pairs = potential_pairs(1:number_cells,(number_cells+1):end);
                max_number_columns = max(sum(potential_pairs,2));
                mNuc_2D = repmat(mNuc,[number_cells,max_number_columns]);
                
                % Get indices of potential pairs of cells
                idx_potential_pairs = zeros(number_cells,max_number_columns);
                for c = 1:number_cells
                    [~, idx_potential_pairs_temp] = find(potential_pairs(c,:));
                    idx_potential_pairs(c,1:numel(idx_potential_pairs_temp)) = idx_potential_pairs_temp;
                end
                
                % Find nucleus with best mNuc
                mNuc_per_cell = zeros(number_cells,max_number_columns);
                mNuc_per_cell(idx_potential_pairs>0)= mNuc_2D(idx_potential_pairs>0);
                [~, idx_mNuc_max] = max(mNuc_per_cell,[],2);
                
                % Create new cell and nuclei indices
                idx_cell = 1:number_cells;
                idx_nuc = zeros(number_cells,1);
                
                for c =1:number_cells
                    idx_nuc(c) = idx_potential_pairs(c,idx_mNuc_max(c));
                end
                
                % Remove unpaired cells/nuclei
                idx_cell(idx_nuc==0)=[];
                idx_nuc(idx_nuc==0)=[];
                
                % Recalculate number cells
                number_cells = numel(idx_nuc);
                
                % Save cell ROIs
                cell_ROIs_temp.frame(1:number_cells,1) = f;
                cell_ROIs_temp.position(1:number_cells,1) = p;
                %             cellData0.ID(1:nCell,1) = randi([0 1E9],nCell,1);
                cell_ROIs_temp.cCellX(1:number_cells,1) = cCell(idx_cell,1);
                cell_ROIs_temp.cCellY(1:number_cells,1) = cCell(idx_cell,2);
                cell_ROIs_temp.rCell(1:number_cells,1) = rCell(idx_cell);
                cell_ROIs_temp.mCell(1:number_cells,1) = mCell(idx_cell);
                
                % Save nuclei ROIs
                cell_ROIs_temp.cNucX(1:number_cells,1) = cNuc(idx_nuc,1);
                cell_ROIs_temp.cNucY(1:number_cells,1) = cNuc(idx_nuc,2);
                cell_ROIs_temp.rNuc(1:number_cells,1) = rNuc(idx_nuc);
                cell_ROIs_temp.mNuc(1:number_cells,1) = mNuc(idx_nuc);
                cell_ROIs_temp.mNuc(1:number_cells,1) = mNuc(idx_nuc);
                
                % If nuclear image provided but no nuclei found, set to nan
            elseif ~isempty(im_nuc) && isempty(rNuc)
                disp(['No nuclei found in frame ' num2str(f) ' position ' num2str(p)])
                rNuc = nan;
                cNuc = nan;
                mNuc = nan;
                display_ROI = false;
            end
            
            % Display identified nuclei (optional)
            if params.displayCells ~= 0
                cell_ROIs_display = cell_ROIs_temp;
                
                % If needed, convert ROIs to table
                if isa(cell_ROIs_display,'struct')
                    cell_ROIs_display = struct2table(cell_ROIs_display);
                end
                
                % Remove missing rows from ROI table
                cell_ROIs_display = rmmissing(cell_ROIs_display);
                
                figure;
                
                if params.displayCells==1 && display_ROI==true % Show matched nucleus/cell pairs
                    %                     imshow(im_cell_current,[])
                    imshow(im_nuc_current,[])
                    viscircles([cell_ROIs_display.cNucX, cell_ROIs_display.cNucY] , cell_ROIs_display.rNuc,'EdgeColor','r','LineWidth',0.1);
                    viscircles([cell_ROIs_display.cCellX, cell_ROIs_display.cCellY] , cell_ROIs_display.rCell,'EdgeColor','y','LineWidth',0.1);
                elseif params.displayCells==2 % Show all potential cells/nuclei
                    %                     imshow(imadjust(im_cell_current),[])
                    imshow(imadjust(im_nuc_current),[])
                    viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',0.1);
                    viscircles(cCell, rCell,'EdgeColor','y','LineWidth',0.1);
                elseif params.displayCells==3 % Show potential nuclei
                    imshow(imadjust(im_nuc(:,:,f,p)),[])
                    viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',0.1);
                elseif params.displayCells==4 % Show potential cells
                    imshow(im_cell_current,[])
                    viscircles(cCell, rCell,'EdgeColor','y','LineWidth',0.1);
                elseif params.displayCells==5 % Show filtered cells
                    imshow(im_cell_current,[])
                    viscircles([cell_ROIs_display.cCellX, cell_ROIs_display.cCellY] , cell_ROIs_display.rCell,'EdgeColor','y','LineWidth',0.1);
                end
            end
            
        else
            disp(['No cells found in frame ' num2str(f) ' position ' num2str(p)])
            rCell = nan;
            cCell = nan;
            mCell = nan;
        end
        
        cell_ROIs{idx} = cell_ROIs_temp;
        idx = idx + 1;
    end
    
end
cell_ROIs = vertcat(cell_ROIs{:});
cell_ROIs.ID(:,1) = randperm(size(cell_ROIs,1));
