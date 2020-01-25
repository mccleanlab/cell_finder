function dataOut = getTrackInit(dataIn,VOI)
% clc
% VOI = 'mCitrine_Cell_mean'
% dataIn = data2plot;

TrackID_list = unique(dataIn.TrackID,'stable');

x = table();
x.TrackID = unique(dataIn.TrackID,'stable');
x.idx_init(:,1) = cell2mat(arrayfun(@(x) find(dataIn.TrackID==x,1),TrackID_list,'un',0));
x.([VOI '_init']) = dataIn.(VOI)(x.idx_init);


dataOut = join(dataIn,x);