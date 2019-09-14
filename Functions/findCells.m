function cellDataOut = findCells(images,channelNuc,channelCell,params)
tic

if ~isempty(channelNuc)
    imNuc = images.(channelNuc);
    disp('Finding paired cell/nucleus ROIs')
else
    imNuc = [];
    disp('Finding cell ROIs only')
end

if ~isempty(channelCell)
    imCell = images.(channelCell);
end

nf = images.nf;
np = images.np;
cellData = [];

%Cycle through stage positions
for p = 1:np
    
    cellData0 = [];
    
    % Cycle through frames
    for f = 1:nf
        
        cellData00 = [];
        
        % Preprocess nuclear images
        if ~isempty(imNuc)
            imNuc0 = imNuc(:,:,f,p);
            
            n = 12;
            sigma = 0.05;
            filt = fspecial('log',n,sigma);
            imNuc0 = imfilter(imNuc0,filt,'replicate');
            imNuc0 = imopen(imNuc0,strel('disk',3));
            imNuc0 = imgaussfilt(imNuc0,1);
            imNuc0 = imdilate(imNuc0,strel('disk',1));
            nucEdgeThresh = params.nucEdgeThresh*graythresh(imNuc0);
            
%                                                 imNuc0 = imadjust(imNuc0,stretchlim(imNuc0,[0.8 0.9999]),[],params.nucGamma);
%                                                 imNuc0 = imopen(imNuc0,strel('disk',1));
%                                                 imNuc0 = imdilate(imNuc0,strel('disk',2));
%                                                 imNuc0 = imgaussfilt(uint16(imNuc0),2);
%                                                 nucEdgeThresh = params.nucEdgeThresh*graythresh(imNuc0);
            
            %             imNuc0 = imadjust(imNuc0,stretchlim(imNuc0,[0.9 0.9999]),[],params.nucGamma);
            %             imNuc0 = imgaussfilt(imNuc0,3);
            %             nucEdgeThresh = params.nucEdgeThresh*graythresh(imNuc0);
        end
        
        % Preprocess cell images
        imCell0 = imCell(:,:,f,p);
        if isequal(channelCell,'DIC')
            polarity = 'dark';
            %             polarity = 'bright';
            %             imCell0 = imgaussfilt(imCell0,2);
            imCell0 = imadjust(imCell0,stretchlim(imCell0),[],params.cellGamma);
            %             n = 10;
            %             filt = fspecial('log',[n n],2);
            %             imCell0 = imfilter(imCell0,filt);
            imCell0 = imgaussfilt(imCell0,2);
            imCell0 = imadjust(imCell0);
            cellEdgeThresh = params.cellEdgeThresh*graythresh(imCell0);
            
        else
            %         smoothFilter = fspecial('gaussian', [3 3], 2);
            %         imCell0 = imfilter(imCell0, smoothFilter);
            %         imCell0 = imgaussfilt(imCell0,2);
            %         imCell0 = imadjust(imCell0);
            polarity = 'bright';
            imCell0 = imadjust(imCell0,stretchlim(imCell0,[0.05 0.995]),[],1);
            imCell0 = medfilt2(imCell0);
            imCell0 = imgaussfilt(imCell0,2);
            cellEdgeThresh = params.cellEdgeThresh*graythresh(imCell0);
        end
        
        clearvars cNuc rNuc cCell rCell numInCell
        
        % Find potential nuclear ROIs
        if ~isempty(imNuc)
            
            [cNuc, rNuc, mNuc] = imfindcircles(imNuc0,params.sizeNuc,'ObjectPolarity','bright','Sensitivity',params.nucSensitivity,'Method','TwoStage','EdgeThreshold',nucEdgeThresh);
            
            % If no nuclei found
            if isempty(rNuc)
                disp(['No nuclei found in frame ' num2str(f) ' position ' num2str(p)])
                rNuc = [nan,nan];
            end
            
            % Remove nuclei that are too close together
            if ~isempty(params.nucOverlapThresh)
                [cNuc, rNuc] = RemoveOverLapPlus(cNuc,rNuc,params.nucOverlapThresh.*params.sizeCell(1),5,mNuc);
            end
            
            % Force nuclei to size range (counters enlargement due to image preprocessing)
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
            disp(['No cells found in frame ' num2str(f) ' position ' num2str(p)])
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
        
        % Initialize variables
        cellData00 = struct();
        
        % Match nuclei to cells
        if ~isempty(imNuc)
            
            % Parameters for sampling ROIs to find cells containing nuclei
            perimPoints = 12;
            fillPoints = 18;
            L = linspace(0,2*pi,perimPoints);
            phi = 2*pi*rand(1,fillPoints);
            r = 1*sqrt(rand(1,fillPoints));
            
            % Cycle through each nucleus and map to cell
            for i = 1:length(rNuc)
                cellData00(i).Frame = f;
                cellData00(i).Position = p;
                cellData00(i).ID = i;
                
                cellData00(i).cNucX = cNuc(i,1);
                cellData00(i).cNucY = cNuc(i,2);
                cellData00(i).rNuc = rNuc(i);
                
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
                    cellData00(i).cCellX = cCell(idx,1);
                    cellData00(i).cCellY = cCell(idx,2);
                    cellData00(i).rCell = rCell(idx);
                    % If not, ditch cell
                else
                    cellData00(i).cCellX = nan;
                    cellData00(i).cCellY = nan;
                    cellData00(i).rCell = nan;
                end
            end
            
        elseif isempty(imNuc)
            cellData00.Frame = repmat(f,numel(rCell),1);
            cellData00.Position = repmat(p,numel(rCell),1);
            cellData00.ID = (1:length(rCell))';
            cellData00.cCellX = cCell(:,1);
            cellData00.cCellY = cCell(:,2);
            cellData00.rCell = rCell;
        end
        
        cellData00 = struct2table(cellData00);
        
        % Collect data into table
        if f==1
            cellData0 = cellData00;
        else
            cellData0 = vertcat(cellData0, cellData00);
        end
        
        % Display identified nuclei (optional)
        if params.displayCells ~= 0
            cellDataDisplay = cellData00;
            if isa(cellDataDisplay,'struct')
                cellDataDisplay = struct2table(cellDataDisplay);
            end
            cellDataDisplay = rmmissing(cellDataDisplay);
            figure;
            if params.displayCells==1 % Show matched nucleus/cell pairs
                imCell0 = imCell(:,:,f,p);
                imCell0 = imadjust(imCell0,stretchlim(imCell0),[],params.cellGamma);
                imshow(imCell0)
                viscircles([cellDataDisplay.cNucX, cellDataDisplay.cNucY] , cellDataDisplay.rNuc,'EdgeColor','r','LineWidth',1);
                viscircles([cellDataDisplay.cCellX, cellDataDisplay.cCellY] , cellDataDisplay.rCell,'EdgeColor','y','LineWidth',1);
                for i = 1:length(cellDataDisplay.ID)
                    text(cellDataDisplay.cNucX(i) + 25, cellDataDisplay.cNucY(i) + 8, sprintf('%d', i),'HorizontalAlignment','center','VerticalAlignment','middle','Color','r');
                end
            elseif params.displayCells==2 % Show all potential cells/nuclei
                imCell0 = imCell(:,:,f,p);
                imCell0 = imadjust(imCell0,stretchlim(imCell0),[],params.cellGamma);
                imshow(imCell0)
                viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',1);
                viscircles(cCell, rCell,'EdgeColor','y','LineWidth',1);
            elseif params.displayCells==3 % Show potential nuclei
                imshow(imNuc0)
                viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',1);
            elseif params.displayCells==4 % Show potential cells
                imshow(imCell0)
                viscircles(cCell, rCell,'EdgeColor','y','LineWidth',1);
            end
        end
        
    end
    
    if p==1
        cellData = cellData0;
    else
        cellData = vertcat(cellData, cellData0);
    end
    
end

%% Format data for output
if isa(cellData,'struct')
    cellData = struct2table(cellData);
end
cellDataOut = rmmissing(cellData); % Remove unmatched cells
toc
