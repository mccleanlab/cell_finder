function exportCellDisplay(cellData,images,channel1,channel2,params)
tic

plotincolor = 'no';
disp('Exporting movie of tracked cells tracks')

h = size(images.(channel1),1);
w = size(images.(channel1),2);
nf = size(images.(channel1),3);
np = size(images.(channel1),4);

if ~isempty(channel1)
    im1 = images.(channel1);
else
    im1 = zeros(h,w,nf,np);
end

if ~isempty(channel2)
    im2 = images.(channel2);
else
    im2 = zeros(h,w,nf,np);
end

% Delete existing output images
if exist([params.outputFolder params.outputFilenameBase '_cellTracks' '.tif'])~=0
    delete([params.outputFolder params.outputFilenameBase '_cellTracks' '.tif']);
end

for p = 1:np
    if exist([params.outputFolder params.outputFilenameBase '_cellTracks_position_' num2str(p) '.tif'])~=0
        delete([params.outputFolder params.outputFilenameBase '_cellTracks_position_' num2str(p) '.tif']);
    end
end


for p = 1:np
    
    for f = 1:nf
        % Get cell data and image for current frame and position
        cellDataDisplay = cellData(cellData.Frame==f & cellData.Position==p,:);
        im10 = im1(:,:,f,p);
        im20 = im2(:,:,f,p);
        
        % Image contrast adjustment
        im20 = imadjust(im20, stretchlim(im20),[]);
        im10 = imadjust(im10, stretchlim(im10),[]);
                

%             n = 16;
%             sigma = 0.05;
%             filt = fspecial('log',n,sigma);
%             im10 = imfilter(im10,filt,'replicate');
%             im10 = imgaussfilt(im10,2);
%             im10 = imerode(im10,strel('disk',1));
%             im10 = imdilate(im10,strel('disk',1));
            
        % Create images with cell overlays
        fig = figure;
        set(gcf,'visible','off')
        if plotincolor=='no'
            imshow(imadjust(im10),'InitialMagnification',100);
        else
            if isequal(channel1,'DIC') || isequal(channel2,'DIC')
                im20 = cat(3,im20,im20,im20);
                im10 =cat(3,im10,zeros(h,w),zeros(h,w));
                imshowpair(im20,im10,'blend');
            else
                imshowpair(im20,im10,'ColorChannels','red-cyan','Scaling','joint');
                set(gca,'position',[0 0 1 1],'units','normalized')
            end
        end
        
        if ismember('rNuc', cellData.Properties.VariableNames)
            viscircles([cellDataDisplay.cNucX, cellDataDisplay.cNucY], cellDataDisplay.rNuc,'EdgeColor','r','LineWidth',0.25);
        end
        viscircles([cellDataDisplay.cCellX, cellDataDisplay.cCellY], cellDataDisplay.rCell,'EdgeColor','y','LineWidth',0.25);
        
        % Label identified cells
        if params.displayCellNumber==1 && ismember('TrackID', cellDataDisplay.Properties.VariableNames)
            for i = 1:length(cellDataDisplay.TrackID)
%                 txt = text(cellDataDisplay.cCellX(i) + 0, cellDataDisplay.cCellY(i) + 0, sprintf('%d', cellDataDisplay.TrackID(i)));
                txt.HorizontalAlignment='center';
                txt.VerticalAlignment='middle';
                txt.Color = 'y';
            end
        elseif params.displayCellNumber==1 && ~ismember('TrackID', cellDataDisplay.Properties.VariableNames)
            for i = 1:length(cellDataDisplay.ID)
                txt = text(cellDataDisplay.cCellX(i) + 25, cellDataDisplay.cCellY(i) + 8, sprintf('%d', cellDataDisplay.ID(i)));
                txt.HorizontalAlignment='center';
                txt.VerticalAlignment='middle';
                txt.Color = 'y';
            end
        elseif params.displayCellNumber==2 && ismember('Parent', cellDataDisplay.Properties.VariableNames)
            for i = 1:length(cellDataDisplay.Parent)
                if ~isnan(cellDataDisplay.Parent(i))
                    txt = text(cellDataDisplay.cCellX(i) + 0, cellDataDisplay.cCellY(i) + 0, sprintf('%d', [cellDataDisplay.Parent(i)]));
                    txt.HorizontalAlignment='center';
                    txt.VerticalAlignment='middle';
                    txt.Color = 'y';
                elseif isnan(cellDataDisplay.Parent(i))
                    txt = text(cellDataDisplay.cCellX(i) + 0, cellDataDisplay.cCellY(i) + 0, sprintf('%d', cellDataDisplay.TrackID(i)));
                    txt.HorizontalAlignment='center';
                    txt.VerticalAlignment='middle';
                    txt.Color = 'g';
                end
            end
        end
        
        % Export images
        truesize(fig)
        fig = getframe(fig);
        im = fig.cdata;
        if np ==1
            imwrite(im, [params.outputFolder params.outputFilenameBase '_cellTracks' '.tif'],'WriteMode','append');
        elseif nf==1 && np>1
            imwrite(im, [params.outputFolder params.outputFilenameBase '_cellTracks' '.tif'],'WriteMode','append');
        else
            imwrite(im, [params.outputFolder params.outputFilenameBase '_cellTracks_position_' num2str(p) '.tif'],'WriteMode','append');
        end
        close;
        cellDataDisplay =[];
    end
end
toc