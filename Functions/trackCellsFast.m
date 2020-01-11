% function cellDataOut = trackCellsFast(data,trackVar,maxLinkDist,maxGapClose)

% nf = max(data.Frame(:));
% np =  max(data.Position(:));

data = cellFilter;
trackVar = 'Cells';
maxLinkDist = 10;
maxGapClose = 3;

nf = 121;
np = 2;

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
    [tracks, global_idx] = simpletracker(points,'MaxLinkingDistance', maxLinkDist,'MaxGapClosing', maxGapClose);
    
    disp('Formatting data for output')
    %%
    all_points = vertcat(points{:});
    
    
        % Format output data
        for c = 1:numel(global_idx)
            trackData0 = table();
            c_idx = global_idx{c,1};
            
            trackData0.Position(:,1) = p;
            trackData0.cCellX(:,1) = all_points(c_idx,1);
            trackData0.cCellY(:,1) = all_points(c_idx,2);
            trackData0.TrackID(:,1) = c;
            
            trackData{c} = trackData0;
        end
       trackData = vertcat(trackData{:});

end

cellDataOut = innerjoin(data,trackData);



