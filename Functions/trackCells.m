function tracksOut = trackCells(cellData, trackVar,maxLinkDist,maxGapClose)

nt = length(unique(cellData.Time));
%% Format data for simpletracker
for t = 1:nt
    cellData0 = cellData(cellData.Time==t,:);
    if strcmp(trackVar,'Nuclei')
        points(t) = {[cellData0.cNucX, cellData0.cNucY]};
    elseif strcmp(trackVar,'Cells')
        points(t) = {[cellData0.cCellX cellData0.cCellY]};
    end
end

if size(points,1)<size(points,2)
    points = points';
end

%% Track data with simpletracker
[tracks] = simpletracker(points,'MaxLinkingDistance', maxLinkDist,'MaxGapClosing', maxGapClose);

%% Format output data
nTracks = numel(tracks);

for c = 1:nTracks
    clearvars cellDataTrack0 cellDataTrack00
    for t= 1:nt
        cellDataTrack00.Time = t;
        cellDataTrack00.TrackID = c;
        if strcmp(trackVar,'Nuclei')
            if ~isnan(tracks{c,1}(t))
                cellDataTrack00.cNucX =  points{t,1}(tracks{c,1}(t),1);
                cellDataTrack00.cNucY =  points{t,1}(tracks{c,1}(t),2);
            else
                cellDataTrack00.cNucX =  nan;
                cellDataTrack00.cNucY =  nan;
            end
        elseif strcmp(trackVar,'Cells')
            if ~isnan(tracks{c,1}(t))
                cellDataTrack00.cCellX =  points{t,1}(tracks{c,1}(t),1);
                cellDataTrack00.cCellY =  points{t,1}(tracks{c,1}(t),2);
            else
                cellDataTrack00.cCellX =  nan;
                cellDataTrack00.cCellY =  nan;
            end
        end
        if t==1
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
cellDataTrack = struct2table(cellDataTrack);
cellDataTrack = innerjoin(cellData,cellDataTrack);
tracksOut = removevars(cellDataTrack,{'ID'});

