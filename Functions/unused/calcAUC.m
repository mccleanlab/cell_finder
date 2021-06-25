function dataOut = calcAUC(dataIn,VOI)

x = table();
x.TrackID = unique(dataIn.TrackID,'stable');
x_sum = grpstats(dataIn,'TrackID','sum','DataVars',VOI);
x.([VOI '_AUC']) = x_sum{:,3};

dataOut = join(dataIn,x);