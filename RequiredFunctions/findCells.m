function cellData = findCells(imNuc,imCell,imCellType,params)

for t = 1:params.nt
    
    % Set black pixels due to image registration to median pixel value
    imNuc0 = imNuc(:,:,t);
    imNuc0(imNuc0==0) = mode(imNuc0(imNuc0~=0));    
    imCell0 = imCell(:,:,t);
    imCell0(imCell0==0) = mode(imCell0(imCell0~=0));
    
    % Preprocess images
    imNuc0 = imadjust(imNuc0,stretchlim(imNuc0,[0 1]));
    smoothFilter = fspecial('gaussian', [9 9], 2);
    imNuc0 = imfilter(imNuc0, smoothFilter);
    imNuc0 = imerode(imNuc0,strel('disk',7));
    
    if imCellType=='DIC'
        polarity = 'dark';
        imCell0 = histeq(imCell0);
        smoothFilter = fspecial('gaussian', [9 9], 2);
        imCell0 = imfilter(imCell0, smoothFilter);
    else
        polarity = 'bright';
        smoothFilter = fspecial('gaussian', [3 3], 2);
        imCell0 = imfilter(imCell0, smoothFilter);
        imCell0 = imadjust(imCell0);
    end
    
    % Initialize variables
    mapNuc = zeros(params.h, params.w, 'uint8');
    mapCell = zeros(params.h, params.w, 'uint8');
    mapCyto = zeros(params.h, params.w, 'uint8');
    cellData0 = struct();
    
    clearvars cNuc rNuc cCell rCell numInCell
    
    % Find potential nuclear ROIs
    [cNuc, rNuc] = imfindcircles(imNuc0,params.sizeNuc,'ObjectPolarity','bright','Sensitivity',params.nucSensitivity,'Method','TwoStage');
    
    % Remove nuclei that are too close together
    if ~isempty(params.nucOverlapThresh)
        [cNuc, rNuc] = RemoveOverLap(cNuc,rNuc,params.nucOverlapThresh.*params.sizeCell(1),2);
    end
    
    % Force nuclei to size range (counters effects of blur and image processing)
    if ~isempty(params.sizeNucForce)
        rNuc(rNuc<params.sizeNucForce(1)) = params.sizeNucForce(1);
        rNuc(rNuc>params.sizeNucForce(2)) = params.sizeNucForce(2);
    end
    
    %% Find cell ROIs from image
    [cCell, rCell] = imfindcircles(imCell0,params.sizeCell,'ObjectPolarity',polarity,'Sensitivity',params.cellSensitivity,'Method','TwoStage');
    
    % Force cells to size range
    if ~isempty(params.sizeCellForce)
        rCell(rCell<params.sizeCellForce(1)) = params.sizeCellForce(1);
        rCell(rCell>params.sizeCellForce(2)) = params.sizeCellForce(2);
    end
    
    % Scale cells (decrease radius to reduce unintended capture of BG)
    if ~isempty(params.sizeCellScale)
        rCell = params.sizeCellScale*rCell;
    end
    
    % Remove overlapping cells
    if ~isempty(params.cellOverlapThresh)
        [cCell, rCell] = RemoveOverLap(cCell,rCell,params.cellOverlapThresh*params.sizeCell(2),2);
    end
    
    %% Match nuclei to cells
    % Parameters for sampling ROIs to find cells containing nuclei
    perimPoints = 12;
    fillPoints = 18;
    L = linspace(0,2*pi,perimPoints);
    phi = 2*pi*rand(1,fillPoints);
    r = 1*sqrt(rand(1,fillPoints));
    
    % Cycle through each nucleus and map to cell
    for i = 1:length(rNuc)
        
        %         cellData0(i).SourceFile = cellFinderProperties.paths{1};
        %         cellData0(i).Plasmid = cellFinderProperties.plasmid;
        cellData0(i).Time = t;
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
        
        if val > (perimPoints + fillPoints)*params.nucCellOverlapThresh
            cellData0(i).cCellX = cCell(idx,1);
            cellData0(i).cCellY = cCell(idx,2);
            cellData0(i).rCell = rCell(idx);
            
        else
            cellData0(i).cCellX = nan;
            cellData0(i).cCellY = nan;
            cellData0(i).rCell = nan;
        end
        
    end
    
    % Display identified nuclei (optional)
    if params.displayCells ~= 0
        cellDataDisplay = struct2table(cellData0);
        cellDataDisplay = rmmissing(cellDataDisplay);
        figure;
        imshow(imadjust(imCell0,stretchlim(imCell0,[0.0001 0.9999])))
        if params.displayCells==1
            imshow(imadjust(imCell0,stretchlim(imCell0,[0.0001 0.9999])))
            viscircles([cellDataDisplay.cNucX, cellDataDisplay.cNucY] , cellDataDisplay.rNuc,'EdgeColor','r','LineWidth',1);
            viscircles([cellDataDisplay.cCellX, cellDataDisplay.cCellY] , cellDataDisplay.rCell,'EdgeColor','y','LineWidth',1);
            for i = 1:length(cellDataDisplay.ID)
                text(cellDataDisplay.cNucX(i) + 25, cellDataDisplay.cNucY(i) + 8, sprintf('%d', i),'HorizontalAlignment','center','VerticalAlignment','middle','Color','r');
            end
        elseif params.displayCells==2
            imshow(imadjust(imCell0,stretchlim(imCell0,[0.0001 0.9999])))
            viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',1);
            viscircles(cCell, rCell,'EdgeColor','y','LineWidth',1);
        elseif params.displayCells==3
            imshow(imadjust(imNuc0,stretchlim(imNuc0,[0.0001 0.9999])))
            viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',1);
        elseif params.displayCells==4
            imshow(imadjust(imCell0,stretchlim(imCell0,[0.0001 0.9999])))
            viscircles(cCell, rCell,'EdgeColor','y','LineWidth',1);
        end
        
        clearvars cellDataDisplay
    end
    
    % Collect data into single struct
    if t==1
        cellData = cellData0;
    else
        cellData = [cellData, cellData0];
    end
    
end
cellData = struct2table(cellData);
cellData = rmmissing(cellData); % Remove unmatched cell