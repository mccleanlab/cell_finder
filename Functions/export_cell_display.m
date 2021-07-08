function export_cell_display(images,channel,cell_measurements,params,preprocess_im)

disp('Exporting movie of tracked cells tracks')

% Get images for specified channel and number of frames/positions
im = images.(channel);
[~, ~, number_frames, number_positions] = size(im);

% Create output folder
if ~exist(params.outputFolder)
    mkdir(params.outputFolder)
end

% Delete existing output images if needed
if number_frames==1
    file_name_out = fullfile(params.outputFolder,strcat(params.sourceFile,'_cell_tracks','.tif'));
    if  exist(file_name_out,'file')
        delete(file_name_out);
    end
else
    for p = 1:number_positions
        file_name_out = fullfile(params.outputFolder, strcat(params.sourceFile, '_cell_tracks_p',num2str(p),'.tif'));
        if  exist(file_name_out,'file')
            delete(file_name_out);
        end
    end
end

for p = 1:number_positions
    
    for f = 1:number_frames
        
        % Get current image
        im_temp = im(:,:,f,p);
        
        % Preprocess image
        if ~isempty(preprocess_im)
            [im_temp, ~] = preprocess_im(im_temp,params);
        else
            im_temp(im_temp==0) = mode(im_temp(im_temp~=0),'all');
            im_temp = imadjust(im_temp);
        end
        
        fig = figure();
        set(gcf,'visible','off')
        imshow(im_temp,[],'Border','tight','InitialMagnification',75)
        
        % Overlay cell features/IDs (if applicable)
        if ~isempty(cell_measurements)
            % Get cell data and image for current frame and position
            data_temp = cell_measurements(cell_measurements.frame==f & cell_measurements.position==p,:);
            
            % Draw cells
            viscircles([data_temp.cCellX, data_temp.cCellY], data_temp.rCell,'EdgeColor','y','LineWidth',0.25);
            
            % Draw nuclei
            if ismember('rNuc', cell_measurements.Properties.VariableNames)
                viscircles([data_temp.cNucX, data_temp.cNucY], data_temp.rNuc,'EdgeColor','r','LineWidth',0.25);
            end
            
            % Draw track IDs if neeeded
            if params.displayTrackID==1 && ismember('track_ID', data_temp.Properties.VariableNames)
                for c = 1:length(data_temp.track_ID)
                    txt = text(data_temp.cCellX(c) + 0, data_temp.cCellY(c) + 0, sprintf('%d', data_temp.track_ID(c)));
                    txt.HorizontalAlignment='center';
                    txt.VerticalAlignment='middle';
                    txt.Color = 'y';
                end
            end
        end
         
        % Export images
        truesize(fig)
        fig = getframe(fig);
        imdata = fig.cdata;
        
        if number_frames==1
            imwrite(imdata, [params.outputFolder '\' params.sourceFile '_cell_tracks' '.tif'],'WriteMode','append');
        else
            imwrite(imdata, [params.outputFolder '\' params.sourceFile '_cell_tracks_p' num2str(p) '.tif'],'WriteMode','append');
        end
        
        close;
        
    end
end
