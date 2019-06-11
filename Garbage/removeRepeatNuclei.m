function cellDataOut = removeRepeatNuclei(cellData)
% cellData = cellData;
cellData.UniqueID = (1:height(cellData))';
listTrackID = unique(cellData.TrackID);
nc = length(listTrackID);

for c = 1:nc
    TrackID = listTrackID(c);
    cellData0 = cellData(cellData.TrackID==TrackID,:);
    if length(unique(cellData0.Time))~=length(cellData0.TrackID)
        dist = sqrt((cellData0.cCellX - cellData0.cNucX).^2 + (cellData0.cCellY - cellData0.cNucY).^2);
        cellDataArray = table2array(cellData0(:,{'cNucX','cNucY','cCellX','cCellY'}));
        idx = kmeans(cellDataArray,2);
        if mean(dist(idx==1)) > mean(dist(idx==2))
            deleteList = cellData0.UniqueID(idx==1);
        else
            deleteList = cellData0.UniqueID(idx==2);
        end
    else
        deleteList = [];
    end
    for i = 1:length(deleteList)
        cellData(cellData.UniqueID==deleteList(i),:)=[];
    end
end

cellDataOut = cellData;