function dataOut = trackCellsFast(dataIn,trackVar,maxLinkDist,maxGapClose)

% dataIn = cellFilter;
% trackVar = 'Cells';
% maxLinkDist = 10;
% maxGapClose = 3;

nf = max(dataIn.Frame(:));
np =  max(dataIn.Position(:));

idx = 1;
trackData = {};

for p = 1:np
    data = dataIn(dataIn.Position==p,:);
    
    disp(['Position = ' num2str(p)]);
    disp('Formatting data for simpletracker');
    
    % Format data for simpletracker
    for f = 1:nf
        data0 = data(data.Frame==f,:);
        
        id_list(f) = {data0.ID};
        
        if strcmp(trackVar,'Nuclei')
            points(f) = {[data0.cNucX, data0.cNucY]};
        elseif strcmp(trackVar,'Cells')
            points(f) = {[data0.cCellX data0.cCellY]};
        end
    end
    
    if size(points,1)<size(points,2)
        points = points';
    end
    
    disp('Running simpletracker');
    
    % Track data with simpletracker
    [tracks, global_idx] = simpletracker(points,'MaxLinkingDistance', maxLinkDist,'MaxGapClosing', maxGapClose);
    
    % Format output data
    disp('Formatting data for output')
    
    all_points = vertcat(points{:});
    all_ids = vertcat(id_list{:});
    
    
    for c = 1:numel(global_idx)
        trackData0 = table();
        c_idx = global_idx{c,1};
        
        trackData0.ID(:,1) = all_ids(c_idx);
        trackData0.Position(:,1) = p;
        trackData0.TrackID(:,1) = idx;
        
        trackData{idx} = trackData0;
        idx = idx + 1;
    end
end

trackData = vertcat(trackData{:});
dataOut = innerjoin(dataIn,trackData);
dataOut =  calcLifespan(dataOut);
dataOut = sortrows(dataOut,{'TrackID','Frame'},{'Ascend','Ascend'});
