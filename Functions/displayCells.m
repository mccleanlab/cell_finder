function [] = displayCells(cellData,imNuc,imCell,params)

% Delete existing output images
if exist([params.outputFolder params.prefix '.tif'])~=0 && params.writeImages==1
    delete([params.outputFolder params.prefix '.tif']);
end

for f = 1:params.nf
    % Get cell location data at current frame
    cellDataDisplay = cellData(ismember(cellData.Time,f),:);
    
    if isempty(imNuc)
        imNuc0 = zeros(params.h,params.w);
        imCell0 = imCell(:,:,f);
    elseif isempty(imCell)
        imNuc0 = imNuc(:,:,f);
        imCell0 = zeros(params.h,params.w);
    else
        imNuc0 = imNuc(:,:,f);
        imCell0 = imCell(:,:,f);
    end
    
    % Image contrast adjustment
    imCell0 = imadjust(imCell0, stretchlim(imCell0,[0.1 0.99]));
    imNuc0 = imadjust(imNuc0, stretchlim(imNuc0,[0.1 0.99]));
    
    % Create images with cell overlays
    f = figure;
    set(gcf,'visible','off')
    imshowpair(imCell0,imNuc0,'ColorChannels','red-cyan','Scaling','joint');
    set(gca,'position',[0 0 1 1],'units','normalized')
    if ismember('rNuc', cellData.Properties.VariableNames)
        viscircles([cellDataDisplay.cNucX, cellDataDisplay.cNucY], cellDataDisplay.rNuc,'EdgeColor','r','LineWidth',0.25);
    end
    
    viscircles([cellDataDisplay.cCellX, cellDataDisplay.cCellY], cellDataDisplay.rCell,'EdgeColor','y','LineWidth',0.25);
    
    % Label identified cells
    if ismember('TrackID', cellDataDisplay.Properties.VariableNames)
        for i = 1:length(cellDataDisplay.TrackID)
            text(cellDataDisplay.cCellX(i) + 25, cellDataDisplay.cCellY(i) + 8, sprintf('%d', cellDataDisplay.TrackID(i)),'HorizontalAlignment','center','VerticalAlignment','middle','Color','y');
        end
    else
        for i = 1:length(cellDataDisplay.ID)
            text(cellDataDisplay.cCellX(i) + 25, cellDataDisplay.cCellY(i) + 8, sprintf('%d', cellDataDisplay.ID(i)),'HorizontalAlignment','center','VerticalAlignment','middle','Color','y');
        end
    end
    
    % Export images
    if params.writeImages==1
        F = getframe(f);
        im = F.cdata;
        imwrite(im, [params.outputFolder params.prefix '.tif'],'WriteMode','append');
    end
    close;
    cellDataDisplay =[];
end
