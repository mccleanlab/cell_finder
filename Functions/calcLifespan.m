function dataOut = calcLifespan(dataIn)
% Calculates lifespan of cells by track ID and appends to table

tracks = table();
tracks.TrackID = unique(dataIn.TrackID);
tracks.Lifespan  = histc(dataIn.TrackID,tracks.TrackID);

dataOut = join(dataIn,tracks);

