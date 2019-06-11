function cellDataOut = interpolateTracks(cellData,params,removeOverlap)
% clearvars -except cellData lifespan cellFinderProperties
lifespan = params.lifespan;
nt = length(unique(cellData.Time));
listTrackID = unique(cellData.TrackID);
nc = length(listTrackID);


for c = 1:nc
    clearvars cellDataInterp0
    TrackID = listTrackID(c);
    cellData0 = cellData(cellData.TrackID==TrackID,:);
    cellDataInterp0.Time = (1:nt)';
    cellDataInterp0 = struct2table(cellDataInterp0);
    cellDataInterp0 = outerjoin(cellDataInterp0,cellData0);
    cellDataInterp0 = fillmissing(cellDataInterp0,'linear','EndValues','none');
    cellDataInterp0.Lifetime = repmat(sum(~isnan(cellDataInterp0.TrackID)),height(cellDataInterp0),1);
    
    % Remove tracks with lifespan less than threshold
    if nt>=lifespan && sum(~isnan(cellDataInterp0.Time_cellData0))<lifespan
        cellDataInterp0 = [];
    end
    
    % Append data to struct
    if c==1
        cellDataInterp = cellDataInterp0;
    else
        cellDataInterp = vertcat(cellDataInterp, cellDataInterp0);
    end
end

cellDataInterp = removevars(cellDataInterp,{'Time_cellData0'});
cellDataInterp.Properties.VariableNames{'Time_cellDataInterp0'} = 'Time';
cellDataInterp = rmmissing(cellDataInterp);

if removeOverlap==1
    % Remove overlaping cells created by interpolation
    for t = 1:nt
        clearvars cellDataOut0 cellDataOut00
        cellDataOut0 = cellDataInterp(cellDataInterp.Time==t,:);
        % Remove overlapping cell with shortest lifespan
        if ~isempty(params.cellOverlapThresh)
            [cCell, ~] = removeOverLapByLifespan([cellDataOut0.cCellX, cellDataOut0.cCellY],cellDataOut0.rCell,cellDataOut0.Lifetime,params.cellOverlapThresh*params.sizeCell(2));
        end
        cellDataOut00.cCellX = cCell(:,1);
        cellDataOut00.cCellY = cCell(:,2);
        cellDataOut00 = struct2table(cellDataOut00);
        cellDataOut0 = innerjoin(cellDataOut0, cellDataOut00);
        if t==1
            cellDataOut = cellDataOut0;
        else
            cellDataOut = vertcat(cellDataOut, cellDataOut0);
        end
    end
else
    cellDataOut = cellDataInterp;
end

