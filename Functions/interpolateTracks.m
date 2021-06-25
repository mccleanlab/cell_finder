function dataOut = interpolateTracks(dataIn,params,removeOverlap,maxGap)

% dataIn = cell_tracks;
% maxGap = 2;
dataIn = sortrows(dataIn,{'TrackID','Frame'},{'Ascend','Ascend'});

dataOut = {};
track_list = unique(dataIn.TrackID,'stable');
frame_list = unique(dataIn.Frame,'stable');
position_list = unique(dataIn.Position,'stable');


parfor c = 1:numel(track_list)
    % Load track data (no rows for frames where track does not exist)
    track = track_list(c);
    data0 = dataIn(dataIn.TrackID==track,:);
    position = unique(data0.Position);
    
    % Create new expanded table with rows for all frames
    data_interp = table();
    data_interp.Frame(:,1) = frame_list;
    data_interp.Position(:,1) = position;
    data_interp.TrackID(:,1) = track;    
    
    data_interp.cCellX(:,1) = nan(numel(frame_list),1);
    data_interp.cCellY(:,1) = nan(numel(frame_list),1);
    data_interp.rCell = nan(numel(frame_list),1);
    data_interp.mCell = nan(numel(frame_list),1);

    data_interp.cCellX(data0.Frame) = data0.cCellX;
    data_interp.cCellY(data0.Frame) = data0.cCellY;
    data_interp.rCell(data0.Frame) = data0.rCell;
    data_interp.mCell(data0.Frame) = data0.mCell;
    
    if contains('rNuc',dataIn.Properties.VariableNames)
        data_interp.cNucX(:,1) = nan(numel(frame_list),1);
        data_interp.cNucY(:,1) = nan(numel(frame_list),1);
        data_interp.rNuc = nan(numel(frame_list),1);
        data_interp.mNuc = nan(numel(frame_list),1);
        
        data_interp.cNucX(data0.Frame) = data0.cNucX;
        data_interp.cNucY(data0.Frame) = data0.cNucY;
        data_interp.rNuc(data0.Frame) = data0.rNuc;
        data_interp.mNuc(data0.Frame) = data0.mNuc;
    end
    
    % Calculate track gap lengths
    CC = bwconncomp(isnan(data_interp.rCell));
    n = cellfun('prodofsize',CC.PixelIdxList);
    b = zeros(size(data_interp.rCell));
    for ii = 1:CC.NumObjects
        b(CC.PixelIdxList{ii}) = n(ii);
    end
    data_interp.Gap = b;
    
    
    data_interp(data_interp.Gap>maxGap,:) = []; % Delete rows for gaps > maxGap
    data_interp = fillmissing(data_interp,'linear','EndValues','none'); % Interpolate tracks
    dataOut{c} = data_interp; % Collect track into big table
    
end

dataOut = vertcat(dataOut{:});
dataOut = rmmissing(dataOut);
dataOut =  calcLifespan(dataOut); % Calculate lifespan of interpolated track
dataOut.ID(:,1) = randperm(size(dataOut,1)); % Generate new unique IDs

%% Remove overlaping cells created by interpolation

idx = 1;
idx_delete = [];
ID_delete = {};

if removeOverlap==true
    for p = 1:numel(position_list)
        
        for f = 1:numel(frame_list)
            
            data_rmoverlap0 = dataOut(dataOut.Frame==f & dataOut.Position==p,:);
            
            % Remove overlapping cell with shortest lifespan
            [centersNew, ~, ~] = RemoveOverLapPlus([data_rmoverlap0.cCellX, data_rmoverlap0.cCellY],data_rmoverlap0.rCell,0.5*params.sizeCell(2),4,data_rmoverlap0.Lifespan);
            
            idx_delete = ~ismember(data_rmoverlap0.cCellX,centersNew(:,1)) & ~ismember(data_rmoverlap0.cCellY,centersNew(:,2));
            ID_delete{idx,1} = data_rmoverlap0.ID(idx_delete);
            idx = idx + 1;
        end
        
    end
end

ID_delete = vertcat(ID_delete{:});
idx_ID = ismember(dataOut.ID,ID_delete);

dataOut(idx_ID,:) = [];
