function dataOut = labelCells(dataIn,label_max)
% Labels cells by track ID with random integer between 1 and label_max

labels = table();
labels.TrackID = unique(dataIn.TrackID);
labels.Label  = randi(label_max,[numel(unique(dataIn.TrackID)), 1]);

dataOut = join(dataIn,labels);