function cellDataSmooth = smoothTracks(cellData)
listTrackID = unique(cellData.TrackID);
nc = length(listTrackID);

% Set track variables for filtering and filter size
smoothVar = {'cNucX' 'cNucY' 'rNuc' 'cCellX' 'cCellY' 'rCell'};
filterSize = [5, 5, 5, 5, 5, 3];

% Filter track timetraces
for c = 1:nc
    clearvars cellDataSmooth0
    TrackID = listTrackID(c);
    cellDataSmooth0 = cellData(cellData.TrackID==TrackID,:);
    for i = 1: length(smoothVar)
        if i == 6
            % Apply median filter to cell radii
            cellDataSmooth0.(smoothVar{i}) = medfilt1(cellDataSmooth0.(smoothVar{i}),7);
        else
            % Smooth cell tracks
            cellDataSmooth0.(smoothVar{i}) = smooth(cellDataSmooth0.(smoothVar{i}),filterSize(i));
        end
    end
    
    % Collect data into single struct
    if c==1
        cellDataSmooth = cellDataSmooth0;
    else
        cellDataSmooth = vertcat(cellDataSmooth, cellDataSmooth0);
    end
end
% Remove rows with missing data
cellDataSmooth= rmmissing(cellDataSmooth);

