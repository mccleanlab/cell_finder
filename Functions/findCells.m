function cellDataOut = findCells(images,channelNuc,channelCell,params,preprocess_imNuc,preprocess_imCell)


% clearvars -except params images channel
% channelNuc = 'mCherry';
% channelCell = 'GFP';

tic

if ~isempty(channelNuc)
    imNuc = images.(channelNuc);
    disp('Finding paired cell/nucleus ROIs')
    %     params.nuc_mode = mode(imNuc,'all');
    params.nuc_mode = mode(images.([channelNuc '_mode']),'all');
    params.nuc_stretchlim = stretchlim(imNuc(:) - params.nuc_mode);
    [h, w, nf, np] = size(imNuc);
else
    imNuc = [];
    disp('Finding cell ROIs only')
end

if ~isempty(channelCell)
    imCell = images.(channelCell);
    [h, w, nf, np] = size(imCell);
else
    imCell = [];
    %     disp('Must input cell image');
end

idxData = 1;
cellDataOut = cell(np*nf,1);

%Cycle through stage positions
for p = 1:np
    
    % Cycle through frames
    for f = 1:nf
        cellData0 = table();
        display_ROI = true;
        disp(['     Frame ' num2str(f) ' position ' num2str(p)])
        
        % Preprocess nuclear images
        if ~isempty(imNuc)
            imNuc0 = imNuc(:,:,f,p);
            imNuc0(imNuc0==0)=mode(imNuc0(imNuc0~=0),'all');
            [imNuc0, params] = preprocess_imNuc(imNuc0,params);
            %             nucEdgeThresh = params.nucEdgeThresh*graythresh(imNuc0);
            nucEdgeThresh = params.nucEdgeThresh;
        end
        
        % Preprocess cell images
        if ~isempty(imCell)
            imCell0 = imCell(:,:,f,p);
            imCell0(imCell0==0)=mode(imCell0(imCell0~=0),'all');
            params.p_current = p;
            [imCell0, params] = preprocess_imCell(imCell0,params);
            %                         cellEdgeThresh = params.cellEdgeThresh*graythresh(imCell0);
            cellEdgeThresh = params.cellEdgeThresh;
        end
        
        clearvars cNuc rNuc cCell rCell numInCell
        
        % Find potential nuclear ROIs
        if ~isempty(imNuc)
            
            [cNuc, rNuc, mNuc] = imfindcircles(imNuc0,params.sizeNuc,'ObjectPolarity',params.nucPolarity,'Sensitivity',params.nucSensitivity,'Method','PhaseCode','EdgeThreshold',nucEdgeThresh);
            
            % If no nuclei found
            %             if isempty(rNuc)
            %                 disp(['No nuclei found in frame ' num2str(f) ' position ' num2str(p)])
            % %                 rNuc = nan;
            % %                 cNuc = nan;
            % %                 mNuc = nan;
            %             end
            
            % Remove nuclei that are too close together
            if ~isempty(params.nucOverlapThresh) && size(cNuc,1)>1
                [cNuc, rNuc, mNuc] = RemoveOverLapPlus(cNuc,rNuc,params.nucOverlapThresh.*params.sizeCell(1),4,mNuc);
            end
            
            % Force nuclei to size range (counters dilation due to image preprocessing)
            if ~isempty(params.sizeNucForce) && size(cNuc,1)>1
                rNuc(rNuc<params.sizeNucForce(1)) = params.sizeNucForce(1);
                rNuc(rNuc>params.sizeNucForce(2)) = params.sizeNucForce(2);
            end
        end
        
        if ~isempty(imCell)
            % Find cell ROIs from image
            [cCell, rCell, mCell] = imfindcircles(imCell0,params.sizeCell,'ObjectPolarity',params.cellPolarity,'Sensitivity',params.cellSensitivity,'Method','TwoStage','EdgeThreshold',cellEdgeThresh);
        else
            cCell = cNuc;
            rCell = rNuc*params.nucToCellScale;
            mCell = mNuc;
        end
        
        % If cells found, process
        if ~isempty(rCell)
            
            % Remove overlapping cells
            if ~isempty(params.cellOverlapThresh) && size(cCell,1)>1
                [cCell, rCell, mCell] = RemoveOverLapPlus(cCell,rCell,params.cellOverlapThresh*params.sizeCell(2),4,mCell);
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
            
            % If no nuclear image, just find cells
            if isempty(imNuc)
                nCell = numel(rCell);
                cellData0.Frame(1:nCell,1) = f;
                cellData0.Position(1:nCell,1) = p;
                cellData0.ID(1:nCell,1) = randi(1E9);
                cellData0.cCellX(1:nCell,1) = cCell(:,1);
                cellData0.cCellY(1:nCell,1) = cCell(:,2);
                cellData0.rCell(1:nCell,1) = rCell(:);
                cellData0.mCell(1:nCell,1) = mCell(:);
                
            elseif isempty(imCell) && ~isempty(rNuc)
                nCell = numel(rCell);
                cellData0.Frame(1:nCell,1) = f;
                cellData0.Position(1:nCell,1) = p;
                cellData0.cCellX(1:nCell,1) = cCell(:,1);
                cellData0.cCellY(1:nCell,1) = cCell(:,2);
                cellData0.rCell(1:nCell,1) = rCell;
                cellData0.mCell(1:nCell,1) = mCell;
                
                cellData0.cNucX(1:nCell,1) = cCell(:,1);
                cellData0.cNucY(1:nCell,1) = cCell(:,2);
                cellData0.rNuc(1:nCell,1) = rCell/params.nucToCellScale;
                cellData0.mNuc(1:nCell,1) = mCell;
                cellData0.mNuc(1:nCell,1) = mCell;
                
                % If nuclear and cell images provided and nuclei found, pair up cells/nuclei
            elseif ~isempty(imNuc) && ~isempty(imCell) && ~isempty(rNuc)
                xy = [cCell; cNuc];
                rads = [rCell; rNuc];
                
                rad2 = rads(:) + rads(:)';
                dxy = sqrt((xy(:,1) - xy(:,1)').^2 + (xy(:,2) - xy(:,2)').^2 );
                idx0 = dxy <= params.nucCellOverlapThresh*rad2;
                idx0(1:size(xy,1)+1:end) = false;
                intersecting_circles = find(any(idx0,2));
                
                nCell = length(rCell);
                idxtrim = idx0(1:nCell,(nCell+1):end);
                maxCol = max(sum(idxtrim,2));
                mNuc2D = repmat(mNuc,[nCell,maxCol]);
                idxN0 = zeros(nCell,maxCol);
                
                for c = 1:nCell
                    [~, idx] = find(idxtrim(c,:));
                    idxN0(c,1:numel(idx)) = idx;
                end
                
                mNucCell = zeros(nCell,maxCol);
                mNucCell(idxN0>0)= mNuc2D(idxN0>0);
                [~, idxmMax] = max(mNucCell,[],2);
                
                idxC = 1:nCell;
                idxN = zeros(nCell,1);
                
                for c =1:nCell
                    idxN(c) = idxN0(c,idxmMax(c));
                end
                
                idxC(idxN==0)=[];
                idxN(idxN==0)=[];
                nCell = numel(idxN);
                
                cellData0.Frame(1:nCell,1) = f;
                cellData0.Position(1:nCell,1) = p;
                %             cellData0.ID(1:nCell,1) = randi([0 1E9],nCell,1);
                cellData0.cCellX(1:nCell,1) = cCell(idxC,1);
                cellData0.cCellY(1:nCell,1) = cCell(idxC,2);
                cellData0.rCell(1:nCell,1) = rCell(idxC);
                cellData0.mCell(1:nCell,1) = mCell(idxC);
                
                cellData0.cNucX(1:nCell,1) = cNuc(idxN,1);
                cellData0.cNucY(1:nCell,1) = cNuc(idxN,2);
                cellData0.rNuc(1:nCell,1) = rNuc(idxN);
                cellData0.mNuc(1:nCell,1) = mNuc(idxN);
                cellData0.mNuc(1:nCell,1) = mNuc(idxN);
                
                % If nuclear image provided but no nuclei found, set to nan
            elseif ~isempty(imNuc) && isempty(rNuc)
                disp(['No nuclei found in frame ' num2str(f) ' position ' num2str(p)])
                rNuc = nan;
                cNuc = nan;
                mNuc = nan;
                display_ROI = false;
            end
            
            % Display identified nuclei (optional)
            if params.displayCells ~= 0
                cellDataDisplay = cellData0;
                if isa(cellDataDisplay,'struct')
                    cellDataDisplay = struct2table(cellDataDisplay);
                end
                cellDataDisplay = rmmissing(cellDataDisplay);
                figure;
                if params.displayCells==1 && display_ROI==true % Show matched nucleus/cell pairs
                    %                     imshow(imCell0,[])
                    imshow(imadjust(imNuc0),[])
                    
                    %                     imshow(imadjust(imCell(:,:,f,p)),[])
                    viscircles([cellDataDisplay.cNucX, cellDataDisplay.cNucY] , cellDataDisplay.rNuc,'EdgeColor','r','LineWidth',0.1);
                    viscircles([cellDataDisplay.cCellX, cellDataDisplay.cCellY] , cellDataDisplay.rCell,'EdgeColor','y','LineWidth',0.1);
                    %                 for i = 1:length(cellDataDisplay.ID)
                    %                     text(cellDataDisplay.cNucX(i) + 25, cellDataDisplay.cNucY(i) + 8, sprintf('%d', i),'HorizontalAlignment','center','VerticalAlignment','middle','Color','r');
                    %                 end
                elseif params.displayCells==2 % Show all potential cells/nuclei
                    %                                         imCell0 = imCell(:,:,f,p);
                    %                     imCell0 = imadjust(imCell0,stretchlim(imCell0),[],params.cellGamma);
                    %                     imshow(imCell0,[])
                    imshow(imadjust(imNuc0),[])
                    viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',0.1);
                    viscircles(cCell, rCell,'EdgeColor','y','LineWidth',0.1);
                elseif params.displayCells==3 % Show potential nuclei
                    %                     imshow(imadjust(imNuc0),[])
                    imshow(imadjust(imNuc(:,:,f,p)),[])
                    viscircles(cNuc, rNuc,'EdgeColor','r','LineWidth',0.1);
                elseif params.displayCells==4 % Show potential cells
                    imshow(imCell0,[])
                    %                     imshow(imadjust(imCell(:,:,f,p)),[])
                    viscircles(cCell, rCell,'EdgeColor','y','LineWidth',0.1);
                elseif params.displayCells==5 % Show filtered cells
                    imshow(imCell0,[])
                    viscircles([cellDataDisplay.cCellX, cellDataDisplay.cCellY] , cellDataDisplay.rCell,'EdgeColor','y','LineWidth',0.1);
                end
            end
            
        else
            disp(['No cells found in frame ' num2str(f) ' position ' num2str(p)])
            rCell = nan;
            cCell = nan;
            mCell = nan;
        end
        
        cellDataOut{idxData} = cellData0;
        idxData = idxData + 1;
    end
    
end
cellDataOut = vertcat(cellDataOut{:});
cellDataOut.ID(:,1) = randperm(size(cellDataOut,1));
toc
