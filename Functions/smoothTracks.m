function cellDataSmoothOut = smoothTracks(cellData,smoothFilterSize,medFilterSize)
listTrackID = unique(cellData.TrackID,'stable');

np = length(unique(cellData.Position));
nc = length(listTrackID);
nf = length(unique(cellData.Frame));


% Set track variables for filtering and filter size
if ismember('rNuc', cellData.Properties.VariableNames)
    smoothVar = {'cNucX' 'cNucY' 'rNuc' 'cCellX' 'cCellY' 'rCell'};
else
    smoothVar = {'cCellX' 'cCellY' 'rCell'};
end

if medFilterSize > nf
    disp('medFilterSize exceeds number of frames')
end

if numel(smoothFilterSize) ~= numel(smoothVar)
    disp('WARNING:Incorrect smoothFilterSize.')
end

% Filter track timetraces
for p = 1:np
    for c = 1:nc
        clearvars cellDataSmooth0
        TrackID = listTrackID(c);
        cellDataSmooth0 = cellData(cellData.TrackID==TrackID,:);
        for i = 1: length(smoothVar)
            if strcmp(smoothVar{i},'rCell')==1 && medFilterSize>0
                % Apply median filter to cell radii
                cellDataSmooth0.(smoothVar{i}) = medfilt1(cellDataSmooth0.(smoothVar{i}),medFilterSize);
            else
                % Smooth cell tracks
                cellDataSmooth0.(smoothVar{i}) = smooth(cellDataSmooth0.(smoothVar{i}),smoothFilterSize(i));
            end
        end
        
        % Collect data into single struct
        if c==1
            cellDataSmooth = cellDataSmooth0;
        else
            cellDataSmooth = vertcat(cellDataSmooth, cellDataSmooth0);
        end
    end
    if p==1
        cellDataSmoothOut = cellDataSmooth;
    else
        cellDataSmoothOut = vertcat(cellDataSmoothOut, cellDataSmooth);
    end
end
% Remove rows with missing data
cellDataSmoothOut= rmmissing(cellDataSmoothOut);

