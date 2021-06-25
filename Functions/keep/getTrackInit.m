function dataOut = getTrackInit(dataIn,VOI)

% Make table with initial frame of each track
x = grpstats(dataIn,{'sourceFile','Position','TrackID'},{'min'},'DataVars',{'Frame'});
x.TrackID_init = x.min_Frame;
x.min_Frame = [];
x.Properties.RowNames={};
x.GroupCount = [];

dataOut = join(dataIn,x);

% Make table with initial value of variable of interest (VOI)
y = dataOut(dataOut.TrackID==dataOut.TrackID & dataOut.Frame==dataOut.TrackID_init,:);
y.([VOI '_init']) = y.(VOI);
idx_field = ismember(fieldnames(y),{'sourceFile','Position','TrackID',[VOI '_init']});
y = y(:,idx_field);

dataOut = join(dataOut,y);
