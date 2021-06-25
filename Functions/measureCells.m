function cellDataMeasure = measureCells(images,channellist,cellData,params)

% clearvars -except params images channel cellData
% imMeasure = images.mCherry;
% channellist = {'mCherry','DIC'};

disp('Measuring cells:')
[h, w, nf, np] = size(images.(channellist{1}));
% nf = images.iminfo.nf;
% np = images.iminfo.np;
% w = images.iminfo.w;
% h = images.iminfo.h;
theta = 0:0.1:2*pi;

idx = 1;
cellDataMeasure = cell(np*nf,1);

t_measure = tic;

%Cycle through positions
for p = 1:np
    % Cycle through frames
    for f = 1:nf
%         try
            disp(['     Frame ' num2str(f) ' position ' num2str(p)])
            
            cellDataMeasure00 = cellData(cellData.Frame==f & cellData.Position==p,:);
            nc = size(cellDataMeasure00,1);
            
            if ~contains('rNuc', cellData.Properties.VariableNames)
                xCell = (cellDataMeasure00.rCell * cos(theta) + cellDataMeasure00.cCellX)';
                yCell = (cellDataMeasure00.rCell * sin(theta) + cellDataMeasure00.cCellY)';
                
                % Make array of cell indices
                parfor c = 1:nc
                    mCell = poly2mask(xCell(:,c),yCell(:,c),h,w);
                    idxCell{:,c} = find(mCell);
                end
                
            elseif contains('rNuc', cellData.Properties.VariableNames)
                xCell = (cellDataMeasure00.rCell * cos(theta) + cellDataMeasure00.cCellX)';
                yCell = (cellDataMeasure00.rCell * sin(theta) + cellDataMeasure00.cCellY)';
                xNuc = (cellDataMeasure00.rNuc * cos(theta) + cellDataMeasure00.cNucX)';
                yNuc = (cellDataMeasure00.rNuc * sin(theta) + cellDataMeasure00.cNucY)';
                xNucDilate = ((cellDataMeasure00.rNuc + params.nucDilate) * cos(theta) + cellDataMeasure00.cNucX)';
                yNucDilate = ((cellDataMeasure00.rNuc + params.nucDilate) * sin(theta) + cellDataMeasure00.cNucY)';
                
                parfor c = 1:nc
                    mCell = poly2mask(xCell(:,c),yCell(:,c),h,w);
                    mNuc = poly2mask(xNuc(:,c),yNuc(:,c),h,w);
                    mNucDilate = poly2mask(xNucDilate(:,c),yNucDilate(:,c),h,w);
                    mCyto = mCell - mNucDilate;
                    
                    idxCell{:,c} = find(mCell);
                    idxNuc{:,c} = find(mNuc);
                    idxCyto{:,c} = find(mCyto);
                end
            end
            
            % Create mask to measure BG
            mask = zeros(h,w,'logical');
            for c = 1:nc
                mask(idxCell{:,c})=1;
            end
            
            assignin('base','mask',mask);
            
            % Calculate confluency based on cell ROIs
            confluency = mask;
            confluency = imdilate(confluency,strel('disk',3));
            confluency = bwmorph(confluency,'bridge');
            confluency = imfill(confluency,8,'holes');
            confluency = sum(confluency,'all')/(h*w);
            
            for i = 1:numel(channellist)
                
                % Set image to measure and replace zeros with nan
                channel = channellist{i};
                imMeasure0 = images.(channel)(:,:,f,p);
                imMeasure0 = double(imMeasure0);
                imMeasure0(imMeasure0==0)=nan;
                
                BG = mode(imMeasure0(~mask),'all');
                
                if ~contains('rNuc', cellData.Properties.VariableNames)
                    % Make array of cell measurements for channel
                    Cell0 = cell(1,nc);
                    parfor c = 1:nc
                        cellMeasurements = double(imMeasure0(idxCell{c}));
                        cellMeasurements = sort(cellMeasurements(~isnan(cellMeasurements)),'descend');
                        Cell0{:,c} = cellMeasurements;
                    end
                    
                    % Convert  array of cell measurements to double
                    Cell0_npxmax = max(cell2mat( cellfun(@length,Cell0,'uni',false)));
                    Cell0_mat = nan(Cell0_npxmax,nc);
                    
                    for c = 1:nc
                        Cell0_mat(1:length(Cell0{c}),c) = Cell0{c};
                    end
                    
                elseif contains('rNuc', cellData.Properties.VariableNames)
                    % Make array of cell measurements for channel
                    Cell0 = cell(1,nc);
                    Nuc0 = cell(1,nc);
                    Cyto0= cell(1,nc);
                    parfor c = 1:nc
                        cellMeasurements = double(imMeasure0(idxCell{c}));
                        cellMeasurements = sort(cellMeasurements(~isnan(cellMeasurements)),'descend');
                        nucMeasurements = double(imMeasure0(idxNuc{c}));
                        nucMeasurements = sort(nucMeasurements(~isnan(nucMeasurements)),'descend');
                        cytoMeasurements = double(imMeasure0(idxCyto{c}));
                        cytoMeasurements = sort(cytoMeasurements(~isnan(cytoMeasurements)),'descend');
                        
                        Cell0{:,c} = cellMeasurements;
                        Nuc0{:,c} = nucMeasurements;
                        Cyto0{:,c} = cytoMeasurements;
                    end
                    
                    % Convert  array of cell measurements to double
                    Cell0_npxmax = max(cell2mat( cellfun(@length,Cell0,'uni',false)));
                    Cell0_mat = nan(Cell0_npxmax,nc);
                    Nuc0_npxmax = max(cell2mat( cellfun(@length,Nuc0,'uni',false)));
                    Nuc0_mat = nan(Nuc0_npxmax,nc);
                    Cyto0_npxmax = max(cell2mat( cellfun(@length,Cyto0,'uni',false)));
                    Cyto0_mat = nan(Cyto0_npxmax,nc);
                    for c = 1:nc
                        Cell0_mat(1:length(Cell0{c}),c) = Cell0{c};
                        Nuc0_mat(1:length(Nuc0{c}),c) = Nuc0{c};
                        Cyto0_mat(1:length(Cyto0{c}),c) = Cyto0{c};
                    end
                end
                
                % Fill empty arrays with nan to avoid errors when measuring
                if isempty(Cell0_mat)
                    Cell0_mat = nan(15,size(Cell0_mat,2));
                end
                
                if exist('Nuc0_mat','var') && isempty(Nuc0_mat)
                    Nuc0_mat = nan(15,size(Nuc0_mat,2));
                end
                
                if exist('Cyto0_mat','var') && isempty(Cyto0_mat)
                    Cyto0_mat = nan(15,size(Cyto0_mat,2));
                end
                
                % Measure cells
                cellDataMeasure00.([channel '_mode'])(:,1) = double(images.([channel '_mode'])(f,p));
                cellDataMeasure00.([channel '_BG'])(:,1) = BG;
                cellDataMeasure00.([channel '_confluency'])(:,1) = confluency;
                cellDataMeasure00.([channel '_cell_mean'])(:,1) = nanmean(Cell0_mat);
                cellDataMeasure00.([channel '_cell_median'])(:,1) = nanmedian(Cell0_mat);
                cellDataMeasure00.([channel '_cell_mode'])(:,1) = mode(Cell0_mat);
                cellDataMeasure00.([channel '_cell_SD'])(:,1) = nanstd(Cell0_mat);
                cellDataMeasure00.([channel '_cell_max'])(:,1) = nanmax(Cell0_mat);
                cellDataMeasure00.([channel '_cell_min'])(:,1) = nanmin(Cell0_mat);
                cellDataMeasure00.([channel '_cell_sum'])(:,1) = nansum(Cell0_mat);
                cellDataMeasure00.([channel '_cell_upperquartile'])(:,1) = quantile(Cell0_mat,0.75);
                cellDataMeasure00.([channel '_cell_lowerquartile'])(:,1) = quantile(Cell0_mat,0.25);
                cellDataMeasure00.([channel '_cell_95prctile'])(:,1) = quantile(Cell0_mat,0.95);
                cellDataMeasure00.([channel '_cell_5prctile'])(:,1) = quantile(Cell0_mat,0.05);
                
                cellDataMeasure00.([channel '_cell_max15px'])(:,1) = nanmean(Cell0_mat(1:14,:));
                cellDataMeasure00.([channel '_cell_dimpx'])(:,1) = nanmean(Cell0_mat(14:end,:));
                
                % Measure cellular compartments if nuclear marker present
                if contains('rNuc', cellData.Properties.VariableNames)
                    cellDataMeasure00.([channel '_nuclear_mean'])(:,1) = nanmean(Nuc0_mat);
                    cellDataMeasure00.([channel '_nuclear_median'])(:,1) = nanmedian(Nuc0_mat);
                    cellDataMeasure00.([channel '_nuclear_mode'])(:,1) = mode(Nuc0_mat);
                    cellDataMeasure00.([channel '_nuclear_SD'])(:,1) = nanstd(Nuc0_mat);
                    cellDataMeasure00.([channel '_nuclear_max'])(:,1) = nanmax(Nuc0_mat);
                    cellDataMeasure00.([channel '_nuclear_min'])(:,1) = nanmin(Nuc0_mat);
                    cellDataMeasure00.([channel '_nuclear_sum'])(:,1) = nansum(Nuc0_mat);
                    cellDataMeasure00.([channel '_nuclear_upperquartile'])(:,1) = quantile(Nuc0_mat,0.75);
                    cellDataMeasure00.([channel '_nuclear_lowerquartile'])(:,1) = quantile(Nuc0_mat,0.25);
                    cellDataMeasure00.([channel '_nuclear_95prctile'])(:,1) = quantile(Nuc0_mat,0.95);
                    cellDataMeasure00.([channel '_nuclear_5prctile'])(:,1) = quantile(Nuc0_mat,0.05);
                    
                    cellDataMeasure00.([channel '_cyto_mean'])(:,1) = nanmean(Cyto0_mat);
                    cellDataMeasure00.([channel '_cyto_median'])(:,1) = nanmedian(Cyto0_mat);
                    cellDataMeasure00.([channel '_cyto_SD'])(:,1) = nanstd(Cyto0_mat);
                    cellDataMeasure00.([channel '_cyto_max'])(:,1) = nanmax(Cyto0_mat);
                    cellDataMeasure00.([channel '_cyto_min'])(:,1) = nanmin(Cyto0_mat);
                    cellDataMeasure00.([channel '_cyto_sum'])(:,1) = nansum(Cyto0_mat);
                    cellDataMeasure00.([channel '_cyto_upperquartile'])(:,1) = quantile(Cyto0_mat,0.75);
                    cellDataMeasure00.([channel '_cyto_lowerquartile'])(:,1) = quantile(Cyto0_mat,0.25);
                    cellDataMeasure00.([channel '_cyto_95prctile'])(:,1) = quantile(Cyto0_mat,0.95);
                    cellDataMeasure00.([channel '_cyto_5prctile'])(:,1) = quantile(Cyto0_mat,0.05);
                end
            end
            cellDataMeasure{idx} = cellDataMeasure00;
            idx = idx + 1;
            
%         catch
%             disp(['No cells in frame ' num2str(f) ' position ' num2str(p)])
%         end
    end
end
cellDataMeasure = vertcat(cellDataMeasure{:});

t_measure = toc;
disp(['time to measure = ' num2str(t_measure)])
