function cellDataRemoveOverlap = interpolateTracks(data,params,removeOverlap)
% clearvars -except cellData lifespan cellFinderProperties
lifespan = params.lifespan;
nf = length(unique(data.Frame));
listTrackID = unique(data.TrackID,'stable');
nc = length(listTrackID);
np = max(data.Position(:));

for p = 1:np
    cellData = data(data.Position==p,:);
    for c = 1:nc
        clearvars cellDataInterp0
        TrackID = listTrackID(c);
        cellData0 = cellData(cellData.TrackID==TrackID,:);
        cellDataInterp0.Frame = (1:nf)';
        cellDataInterp0 = struct2table(cellDataInterp0);
        cellDataInterp0 = outerjoin(cellDataInterp0,cellData0);
        cellDataInterp0 = fillmissing(cellDataInterp0,'linear','EndValues','none');
        cellDataInterp0.Lifetime = repmat(sum(~isnan(cellDataInterp0.TrackID)),height(cellDataInterp0),1);
        
        % Remove tracks with lifespan less than threshold
        if nf>=lifespan && sum(~isnan(cellDataInterp0.Frame_cellData0))<lifespan
            cellDataInterp0 = [];
        end
        
        % Append data to struct
        if c==1
            cellDataInterp = cellDataInterp0;
        else
            cellDataInterp = vertcat(cellDataInterp, cellDataInterp0);
        end
    end
    
    cellDataInterp(isnan(cellDataInterp.TrackID),:)=[];
    cellDataInterp = removevars(cellDataInterp,{'Frame_cellData0'});
    cellDataInterp.Properties.VariableNames{'Frame_cellDataInterp0'} = 'Frame';
    % cellDataInterp = rmmissing(cellDataInterp);
    
    if removeOverlap==1
        % Remove overlaping cells created by interpolation
        for f = 1:nf
            clearvars cellDataRemoveOverlap0 cellDataRemoveOverlap00
            cellDataRemoveOverlap0 = cellDataInterp(cellDataInterp.Frame==f,:);
            % Remove overlapping cell with shortest lifespan
            if ~isempty(params.cellOverlapThresh)
                [cCell, ~] = removeOverLapByLifespan([cellDataRemoveOverlap0.cCellX, cellDataRemoveOverlap0.cCellY],cellDataRemoveOverlap0.rCell,cellDataRemoveOverlap0.Lifetime,params.cellOverlapThresh*params.sizeCell(2));
            end
            cellDataRemoveOverlap00.cCellX = cCell(:,1);
            cellDataRemoveOverlap00.cCellY = cCell(:,2);
            cellDataRemoveOverlap00 = struct2table(cellDataRemoveOverlap00);
            cellDataRemoveOverlap0 = innerjoin(cellDataRemoveOverlap0, cellDataRemoveOverlap00);
            if f==1
                cellDataRemoveOverlap = cellDataRemoveOverlap0;
            else
                cellDataRemoveOverlap = vertcat(cellDataRemoveOverlap, cellDataRemoveOverlap0);
            end
        end
    else
        cellDataRemoveOverlap = cellDataInterp;
    end
    
    if p==1
        cellDataOut = cellDataRemoveOverlap;
    else
        cellDataOut = vertcat(cellDataOut, cellDataRemoveOverlap);
    end
end

