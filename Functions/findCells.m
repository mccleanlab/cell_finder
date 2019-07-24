function cellData = findCells(imNuc,imCell,imCellType,params)
% imNuc = images.mCherry;
% imCell = images.GFP;
% imCellType = 'GFP';
% params.nucSensitivity = 0.95;
% params.nucEdgeThresh = 0.25;
% params.cellEdgeThresh = 0.5;
% params.cellSensitivity = 0.85;
% params.nucGamma = 1;


for f = 1:params.nf
    %% Image processing
    
    % Preprocess nuclear images
    if ~isempty(imNuc)
        
        %         imNuc0 = imerode(imNuc0,strel('disk',5));
        imNuc0 = imNuc(:,:,f);
        imNuc0 = imgaussfilt(imNuc0,2);
        imNuc0 = imadjust(imNuc0,stretchlim(imNuc0,[0.9 0.999]),[],params.nucGamma);
        %         nucEdgeThresh = params.nucEdgeThresh.*graythresh(imNuc0);
        nucEdgeThresh = params.nucEdgeThresh*graythresh(imNuc0);
        
    end
    
    % Preprocess cell images
    imCell0 = imCell(:,:,f);
    if isequal(imCellType,'DIC')
        %         polarity = 'dark';
        %         polarity = 'bright';
        %                 imCell0 = imgaussfilt(imCell0,2);
        %         imCell0 = imadjust(imCell0,stretchlim(imCell0),[0 1],params.cellGamma);
        %                 cellEdgeThresh = params.cellEdgeThresh*graythresh(imCell0);
        polarity = 'bright';
        %         n = 10;
        %         filt = fspecial('log',[n n],2);
        %         imCell0 = imfilter(imCell0,filt);
        imCell0 = imadjust(imCell0);
        cellEdgeThresh = params.cellEdgeThresh*graythresh(imCell0);
        
    else
        polarity = 'bright';
        %         smoothFilter = fspecial('gaussian', [3 3], 2);
        %         imCell0 = imfilter(imCell0, smoothFilter);
        %         imCell0 = imgaussfilt(imCell0,2);
        %         imCell0 = imadjust(imCell0);
        imCell0 = imadjust(imCell0,stretchlim(imCell0),[0 0.5],params.cellGamma);
        imCell0 = imgaussfilt(imCell0,3);
        cellEdgeThresh = params.cellEdgeThresh*graythresh(imCell0);
        
    end
    
    clearvars cNuc rNuc cCell rCell numInCell
    
    %% Find ROIs from processed images
    
    % Find potential nuclear ROIs
    if ~isempty(imNuc)
        
        [cNuc, rNuc] = imfindcircles(imNuc0,params.sizeNuc,'ObjectPolarity','bright','Sensitivity',params.nucSensitivity,'Method','TwoStage','EdgeThreshold',nucEdgeThresh);
        
        % If no nuclei found
        if isempty(rNuc)
            disp(['No nuclei found in frame ' num2str(f)])
            rNuc = [nan,nan];
        end
        
        % Remove nuclei that are too close together
        if ~isempty(params.nucOverlapThresh)
            [cNuc, rNuc] = RemoveOverLap(cNuc,rNuc,params.nucOverlapThresh.*params.sizeCell(1),2);
        end
        
        % Force nuclei to size range (counters effects of blur and image processing)
        if ~isempty(params.sizeNucForce)
            rNuc(rNuc<params.sizeNucForce(1)) = params.sizeNucForce(1);
            rNuc(rNuc>params.sizeNucForce(2)) = params.sizeNucForce(2);
        end
    end
    
    % Find cell ROIs from image
    [cCell, rCell] = imfindcircles(imCell0,params.sizeCell,'ObjectPolarity',polarity,'Sensitivity',params.cellSensitivity,'Method','TwoStage','EdgeThreshold',cellEdgeThresh);
    %     [cCell, rCell] = imfindcircles(imCell0,params.sizeCell,'ObjectPolarity',polarity,'Sensitivity',params.cellSensitivity,'Method','TwoStage');
    
    % If no cells found
    if isempty(rCell)
        disp(['No cells found in frame ' num2str(f)])
        rCell = nan;
        cCell = nan;
    end
    
    % Remove overlapping cells
    if ~isempty(params.cellOverlapThresh) && size(cCell,1)>1
        [cCell, rCell] = RemoveOverLap(cCell,rCell,params.cellOverlapThresh*params.sizeCell(2),2);
    end
    
    %     Force cells to size range
    if ~isempty(params.sizeCellForce)
        rCell(rCell<params.sizeCellForce(1)) = params.sizeCellForce(1);
        rCell(rCell>params.sizeCellForce(2)) = params.sizeCellForce(2);
    end
    
    % Scale cells (decrease radius to reduce unintended capture of BG)
    if ~isempty(params.sizeCellScale)
        rCell = params.sizeCellScale*rCell;
    end
    
    %% Initialize variables
    cellData0 = struct();
    
    %% Match nuclei to cells
    if ~isempty(imNuc)
        
        % Parameters for sampling ROIs to find cells containing nuclei
        perimPoints = 12;
        fillPoints = 18;
        L = linspace(0,2*pi,perimPoints);
        phi = 2*pi*rand(1,fillPoints);
        r = 1*sqrt(rand(1,fillPoints));
        
        % Cycle through each nucleus and map to cell
        for i = 1:length(rNuc)
            cellData0(i).Time = f;
            cellData0(i).ID = i;
            
            cellData0(i).cNucX = cNuc(i,1);
            cellData0(i).cNucY = cNuc(i,2);
            cellData0(i).rNuc = rNuc(i);
            
            % Sample points within nucleus
            pNuc = [rNuc(i)*cos(L) + cNuc(i,1); rNuc(i)*sin(L) + cNuc(i,2)]';
            fNuc = [cNuc(i,1) + rNuc(i)*r.*cos(phi); cNuc(i,2) + rNuc(i)*r.*sin(phi)]';
            fNuc = [fNuc; pNuc];
            
            % Sample points on cell perimeter and compare to nuclear points
            for j = 1:length(rCell)
                pCell = [rCell(j)*cos(L)+cCell(j,1); rCell(j)*sin(L)+cCell(j,2)]';
                [inCell,~] = inpolygon(fNuc(:,1),fNuc(:,2),pCell(:,1),pCell(:,2));
                numInCell(j) = sum(inCell);
            end
            
            % Find best match for cell and nucleus pair
            [val, idx] = max(numInCell);
            
            % If nucleus/cell overlap passes threshold, keep cell
            if val > (perimPoints + fillPoints)*params.nucCellOverlapThresh
                cellData0(i).cCellX = cCell(idx,1);
                cellData0(i).cCellY = cCell(idx,2);
                cellData0(i).rCell = rCell(idx);
                % If not, ditch cell
            else
                cellData0(i).cCellX = nan;
                cellData0(i).cCellY = nan;
                cellData0(i).rCell = nan;
            end
        end
        
    elseif isempty(imNuc)
        cellData0.Time = f.*ones(length(rCell),1);
        cellData0.ID = (1:length(rCell))';
        cellData0.cCellX = cCell(:,1);
        cellData0.cCellY = cCell(:,2);
        cellData0.rCell = rCell;
    end
    
    cellData0 = struct2table(cellData0);
    
    % Display identified nuclei (optional)
    if params.displayCells ~= 0
        cellDataDisplay = cellData0;
        if isa(cellDataDisplay,'struct')
            cellDataDisplay = struct2table(cellDataDisplay);
        end
        cellDataDisplay = rmmissing(cellDataDisplay);
        figure;
        if params.displayCells==1 % Show matched nucleus/cell pairs
            imshow(imadjust(imCell(:,:,f),stretchlim(imCell(:,:,f),[0.0001 0.9999])))
            viscircles([cellDataDisplay.cNucX, cellDataDisplay.cNucY] , cellDataDisplay.rNuc,'EdgeColor','r','LineWidth',1);
            viscircles([cellDataDisplay.cCellX, cellDataDisplay.cCellY] , cellDataDisplay.rCell,'EdgeColor','y','LineWidth',1);
            for i = 1:length(cellDataDisplay.ID)
                text(cellDataDisplay.cNucX(i) + 25, cellDataDisplay.cNucY(i) + 8, sprintf('%d', i),'HorizontalAlignment','center','VerticalAlignment','middle','Color','r');
            end
        elseif params.displayCells==2 % Show all originally identified cells/nuclei
            imshow(imadjust(imCell(:,:,f),stretchlim(imCell(:,:,f),[0.0001 0.9999])))
            viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',1);
            viscircles(cCell, rCell,'EdgeColor','y','LineWidth',1);
        elseif params.displayCells==3 % Show originally identified nuclei
            imshow(imNuc0)
            viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',1);
        elseif params.displayCells==4 % Show originally identified cells
            imshow(imadjust(imCell0,stretchlim(imCell0,[0.0001 0.9999])))
            viscircles(cCell, rCell,'EdgeColor','y','LineWidth',1);
        end
        clearvars cellDataDisplay
    end
    
    % Collect data into single variable
    if f==1
        cellData = cellData0;
    else
        cellData = vertcat(cellData, cellData0);
    end
end

%% Format data for output
if isa(cellData,'struct')
    cellData = struct2table(cellData);
end

cellData = rmmissing(cellData); % Remove unmatched cells