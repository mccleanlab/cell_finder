function dataOut = calcLifespan(dataIn)

track_list = table();
track_list.TrackID = unique(dataIn.TrackID);
track_list.Lifespan  = histc(dataIn.TrackID,track_list.TrackID);

dataOut = join(dataIn,track_list);

