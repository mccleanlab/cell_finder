function cellDataOut = trackCellsFast(data,trackVar,maxLinkDist,maxGapClose)

nf = max(data.Frame(:));
np =  max(data.Position(:));

for p = 1:np
    cellData = data(data.Position==p,:);
    
    disp(['Position = ' num2str(p)]);
    disp('Formatting data for simpletracker');
    
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
    
    disp('Running simpletracker');
    
    % Track data with simpletracker
    [tracks] = simpletracker(points,'MaxLinkingDistance', maxLinkDist,'MaxGapClosing', maxGapClose);
    
    disp('Formatting data for output')
    
    % Format output data
    for c = 1:numel(tracks)
        c_idx = tracks{c,1};
        c_idx(isnan(c_idx))=[];
        cellData.TrackID(c_idx) = c;
    end
    
    cellDataOut{p} = cellData;    
end

cellDataOut = vertcat(cellDataOut{:});

% cellDataTrackOut = struct2table(cellDataTrackOut);
% cellDataTrackOut = innerjoin(cellData,cellDataTrackOut);
% cellDataTrackOut = removevars(cellDataTrackOut,{'ID'});

