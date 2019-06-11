function cellDataMeasure = measureCells(imMeasure,channel,measureLocalization,cellData,params)

disp('Measuring cells:')
nt = length(unique(cellData.Time));

% Cycle through frames
for t = 1:nt
    disp(['     Frame ' num2str(t)])
    
    % Set image to measure and remove zeros introduce by registration
    imMeasure0 = imMeasure(:,:,t);
    imMeasure0 = double(imMeasure0);
    imMeasure0(imMeasure0==0)=nan;
    
    % Initialize variables
    cellDataMeasure0 = [];
    cellDataMeasure0 = cellData(cellData.Time==t,:);
    cellDataMeasure0 = table2struct(cellDataMeasure0);
    
    % Cycle through cells
    for c = 1:size(cellDataMeasure0,1)
        % Clear old variables
        Nuc0=[];
        Cell0=[];
        Cyto0=[];
        
        % Draw masks for paired cell and nucleus
        [mc, mr] = meshgrid(1:params.w, 1:params.h);
        mNuc = (mr - cellDataMeasure0(c).cNucY).^2 + (mc - cellDataMeasure0(c).cNucX).^2 <= cellDataMeasure0(c).rNuc.^2;
        mCell = (mr - cellDataMeasure0(c).cCellY).^2 + (mc - cellDataMeasure0(c).cCellX).^2 <= cellDataMeasure0(c).rCell.^2;
        mCyto = mCell - mNuc;
        
        % Select pixels to measure
        Nuc0=imMeasure0(mNuc~=0);
        Cell0=imMeasure0(mCell~=0);
        Cyto0=imMeasure0(mCyto~=0);
        
        % Measure cell ROIs
        cellDataMeasure0(c).([channel '_Cell_mean']) = nanmean(Cell0);
        cellDataMeasure0(c).([channel '_Cell_median']) = nanmedian(Cell0);
        cellDataMeasure0(c).([channel '_Cell_SD']) = nanstd(Cell0);
        cellDataMeasure0(c).([channel '_Cell_max']) = nanmax(Cell0);
        cellDataMeasure0(c).([channel '_Cell_min']) = nanmin(Cell0);
        cellDataMeasure0(c).([channel '_Cell_upperquartile']) = quantile(Cell0,0.75);
        cellDataMeasure0(c).([channel '_Cell_lowerquartile']) = quantile(Cell0,0.25);
        cellDataMeasure0(c).([channel '_Cell_upperdecile']) = quantile(Cell0,0.9);
        cellDataMeasure0(c).([channel '_Cell_lowerdecile']) = quantile(Cell0,0.1);
        
        % Measure nuclear and cytoplasmic ROIs
        if measureLocalization~=0
            cellDataMeasure0(c).([channel '_Nuclear_mean']) = nanmean(Nuc0);
            cellDataMeasure0(c).([channel '_Nuclear_median']) = nanmedian(Nuc0);
            cellDataMeasure0(c).([channel '_Nuclear_SD']) = nanstd(Nuc0);
            cellDataMeasure0(c).([channel '_Nuclear_max']) = nanmax(Nuc0);
            cellDataMeasure0(c).([channel '_Nuclear_min']) = nanmin(Nuc0);
            cellDataMeasure0(c).([channel '_Nuclear_upperquartile']) = quantile(Nuc0,0.75);
            cellDataMeasure0(c).([channel '_Nuclear_lowerquartile']) = quantile(Nuc0,0.25);
            cellDataMeasure0(c).([channel '_Nuclear_upperdecile']) = quantile(Nuc0,0.9);
            cellDataMeasure0(c).([channel '_Nuclear_lowerdecile']) = quantile(Nuc0,0.1);
            
            cellDataMeasure0(c).([channel '_Cytoplasmic_mean']) = nanmean(Cyto0);
            cellDataMeasure0(c).([channel '_Cytoplasmic_median']) = nanmedian(Cyto0);
            cellDataMeasure0(c).([channel '_Cytoplasmic_SD']) = nanstd(Cyto0);
            cellDataMeasure0(c).([channel '_Cytoplasmic_max']) = nanmax(Cyto0);
            cellDataMeasure0(c).([channel '_Cytoplasmic_min']) = nanmin(Cyto0);
            cellDataMeasure0(c).([channel '_Cytoplasmic_upperquartile']) = quantile(Cyto0,0.75);
            cellDataMeasure0(c).([channel '_Cytoplasmic_lowerquartile']) = quantile(Cyto0,0.25);
            cellDataMeasure0(c).([channel '_Cytoplasmic_upperdecile']) = quantile(Cyto0,0.9);
            cellDataMeasure0(c).([channel '_Cytoplasmic_lowerdecile']) = quantile(Cyto0,0.1);
            
            % Calculate localization metrics
            cellDataMeasure0(c).([channel '_NucCytRatio']) = nanmean(Nuc0)./nanmean(Cyto0);
            cellDataMeasure0(c).([channel '_LocScore']) = (nanmean(Nuc0) - nanmean(Cyto0))./nanmean(Cyto0);
            Localization0 = reshape(Nuc0,[1,numel(Nuc0)]);
            Localization0 = sort(Localization0);
            max15px = Localization0(end-14:end);
            cellDataMeasure0(c).([channel '_max15px']) = nanmean(max15px);
            Localization0 = Localization0(floor(0.95*numel(Localization0)):end);
            cellDataMeasure0(c).([channel '_Localization']) = nanmean(Localization0) - nanmedian(Cyto0);
        end
    end
    
    % Collect data into single struct
    if t==1
        cellDataMeasure = cellDataMeasure0;
    else
        cellDataMeasure = vertcat(cellDataMeasure, cellDataMeasure0);
    end
end
cellDataMeasure = struct2table(cellDataMeasure);