function dataOut = calcLifespan(dataIn)
% Calculates lifespan of cells by track ID and appends to table

tracks = table();
tracks.track_ID = unique(dataIn.track_ID);
tracks.lifespan  = histc(dataIn.track_ID,tracks.track_ID);

dataOut = join(dataIn,tracks);

