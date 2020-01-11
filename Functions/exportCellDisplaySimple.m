function exportCellDisplaySimple(images,channel,dataIn,params,preprocess_im)
tic
disp('Exporting movie of tracked cells tracks')

im = images.(channel);
[h, w, nf, np] = size(im);

% Create output folder
if ~exist([pwd '\output'])
    mkdir([pwd '\output'])
end

% Delete existing output images
if exist([pwd '\output\' params.outputFilenameBase '_cellTracks' '.tif'])~=0
    delete([pwd '\output\' params.outputFilenameBase '_cellTracks' '.tif']);
end

for p = 1:np
    if exist([pwd '\output\' params.outputFilenameBase '_cellTracks_p' num2str(p) '.tif'])~=0
        delete([pwd '\output\' params.outputFilenameBase '_cellTracks_p' num2str(p) '.tif']);
    end
end


for p = 1:np
    
    for f = 1:nf
        
        % Get current image
        im0 = im(:,:,f,p);
        
        % Preprocess image
        if ~isempty(preprocess_im)
            [im0, ~] = preprocess_im(im0,params);
        else
            im0 = imadjust(im0);
        end
        
        fig = figure('Position',[100, 100, w, h]);
        set(gcf,'visible','off')
        imshow(im0,[])
        
        % Overlay cell features/IDs (if applicable)
        if ~isempty(dataIn)
            % Get cell data and image for current frame and position
            data0 = dataIn(dataIn.Frame==f & dataIn.Position==p,:);
            
            % Draw cells
            viscircles([data0.cCellX, data0.cCellY], data0.rCell,'EdgeColor','y','LineWidth',0.25);
            
            % Draw nuclei
            if ismember('rNuc', dataIn.Properties.VariableNames)
                viscircles([data0.cNucX, data0.cNucY], data0.rNuc,'EdgeColor','r','LineWidth',0.25);
            end
            
            % Draw track IDs
            if params.displayCellNumber==1 && ismember('TrackID', data0.Properties.VariableNames)
                for c = 1:length(data0.TrackID)
                    txt = text(data0.cCellX(c) + 0, data0.cCellY(c) + 0, sprintf('%d', data0.TrackID(c)));
                    txt.HorizontalAlignment='center';
                    txt.VerticalAlignment='middle';
                    txt.Color = 'y';
                end
            end
        end
        
        data0 =[];
        
        % Export images
        truesize(fig)
        fig = getframe(fig);
        imdata = fig.cdata;
        imwrite(imdata, [pwd '\output\' params.outputFilenameBase '_cellTracks_p' num2str(p) '.tif'],'WriteMode','append');
        close;
        
    end
end
toc