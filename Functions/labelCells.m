function dataOut = labelCells(dataIn,label_max)

cell_list = table();
cell_list.TrackID = unique(dataIn.TrackID);
cell_list.Label  = randi(label_max,[numel(unique(dataIn.TrackID)), 1]);

dataOut = join(dataIn,cell_list);