function cellDataTrackOut = trackCells(data, trackVar,maxLinkDist,maxGapClose)

nf = max(data.Frame(:));
np =  max(data.Position(:));
for p = 1:np
    cellData = data(data.Position==p,:);
    
    % Format data for simpletracker
    for f = 1:nf
        cellData0 = cellData(cellData.Frame==f,:);
        if strcmp(trackVar,'Nuclei')
            points(f) = {[cellData0.cNucX, cellData0.cNucY]};
        elseif strcmp(trackVar,'Cells')
            points(f) = {[cellData0.cCellX cellData0.cCellY]};
        end
    end
    
    if size(points,1)<size(points,2)
        points = points';
    end
    
    % Track data with simpletracker
    [tracks] = simpletracker(points,'MaxLinkingDistance', maxLinkDist,'MaxGapClosing', maxGapClose);
    
    % Format output data
    nTracks = numel(tracks);
    
    for c = 1:nTracks
        clearvars cellDataTrack0 cellDataTrack00
        for f= 1:nf
            cellDataTrack00.Frame = f;
            cellDataTrack00.TrackID = c;
            if strcmp(trackVar,'Nuclei')
                if ~isnan(tracks{c,1}(f))
                    cellDataTrack00.cNucX =  points{f,1}(tracks{c,1}(f),1);
                    cellDataTrack00.cNucY =  points{f,1}(tracks{c,1}(f),2);
                else
                    cellDataTrack00.cNucX =  nan;
                    cellDataTrack00.cNucY =  nan;
                end
            elseif strcmp(trackVar,'Cells')
                if ~isnan(tracks{c,1}(f))
                    cellDataTrack00.cCellX =  points{f,1}(tracks{c,1}(f),1);
                    cellDataTrack00.cCellY =  points{f,1}(tracks{c,1}(f),2);
                else
                    cellDataTrack00.cCellX =  nan;
                    cellDataTrack00.cCellY =  nan;
                end
            end
            if f==1
                cellDataTrack0 = cellDataTrack00;
            else
                cellDataTrack0 = [cellDataTrack0, cellDataTrack00];
            end
        end
        
        if c==1
            cellDataTrack = cellDataTrack0;
        else
            cellDataTrack = [cellDataTrack, cellDataTrack0];
        end
    end
    
    if p==1
        cellDataTrackOut = cellDataTrack;
    else
        cellDataTrackOut = [cellDataTrackOut, cellDataTrack];
    end
end

cellDataTrackOut = struct2table(cellDataTrackOut);
cellDataTrackOut = innerjoin(cellData,cellDataTrackOut);
cellDataTrackOut = removevars(cellDataTrackOut,{'ID'});

