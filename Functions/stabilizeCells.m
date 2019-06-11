function cellDataStabilize = stabilizeCells(cellData,targets,thresh)
% clearvars -except cellData lifespan cellFinderProperties
% nt = length(unique(cellData.Time));
% targets = [];
% thresh = 2;

if isempty(targets)
    listTrackID = unique(cellData.TrackID);
    nc = length(listTrackID);
else
    listTrackID = targets;
    nc = length(listTrackID);
end


for c = 1:nc
    clearvars cellData0
    TrackID = listTrackID(c);
    cellData0 = cellData(cellData.TrackID==TrackID,:);
    cellData0.diffX = cellData0.cNucX - cellData0.cCellX;
    %     diffX = mean(cellData0.diffX(:));
    diffX = smooth(cellData0.diffX,11);
    sdX = std(cellData0.diffX(:));
    cellData0.diffY = cellData0.cNucY - cellData0.cCellY;
%     diffY = mean(cellData0.diffY(:));
    diffY = smooth(cellData0.diffY,11);
    sdY = std(cellData0.diffY(:));
    err = sqrt(sdY.^2 + sdX.^2);
    hold on; bar(c,err)
    
    if err>thresh
        cellData0.cCellX = cellData0.cNucX - diffX;
        cellData0.cCellY = cellData0.cNucY - diffY;
    end
    
    cellData0.diffX=[];
    cellData0.diffY=[];
    
    % Append data to struct
    if c==1
        cellDataStabilize = cellData0;
    else
        cellDataStabilize = vertcat(cellDataStabilize, cellData0);
    end
end

% cellDataStabilize = removevars(cellDataStabilize,{'diffX', 'diffY'});
% cellDataInterp.Properties.VariableNames{'Time_cellDataInterp0'} = 'Time';
% cellDataInterp = rmmissing(cellDataInterp);

