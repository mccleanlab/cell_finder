function dataOut = smoothTracks(dataIn,vars2filter,filterSize)
% dataIn = cell_tracks_interp;
% vars2filter = {'cCellX' 'cCellY' 'rCell'};
% smoothFiterSize = {5,5,5};
% VOI = 'rCell';

track_list = unique(dataIn.TrackID,'stable');
frame_list = unique(dataIn.Frame,'stable');
position_list = unique(dataIn.Position,'stable');
dataOut = {};

for i = 1:numel(vars2filter)
    VOI = vars2filter{i};
    fsize = filterSize{i};
    parfor c = 1:numel(track_list)
        track = track_list(c);
        data0 = dataIn(dataIn.TrackID==track,:);
        data0.(VOI) = smooth(data0.(VOI),fsize)
        dataOut{c} = data0;
    end
end

dataOut = vertcat(dataOut{:});
toc