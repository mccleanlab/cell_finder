function cellDataOut = flagDeadCells(cellData,cellDataDead,params)

cellDataOut = cellData;

for f = 1:max(cellData.Frame)
cellData0 = cellData(cellData.Frame==f,:);
cellDataDead0 = cellDataDead(cellDataDead.Frame==f,:);

c0 = [cellData0.cCellX, cellData0.cCellY];
r0 = cellData0.rCell;
cDead = [cellDataDead0.cCellX, cellDataDead0.cCellY];
rDead = cellDataDead0.rCell;

cCompare = [c0; cDead];
rCompare = [r0; rDead];
mCompare = [zeros(size(c0,1),1); ones(size(cDead,1),1)];

[cOverlap,~] = RemoveOverLapPlus(cCompare,rCompare,params.deadOverlap*params.sizeCell(2),4,mCompare);
cDelete = setdiff(c0,cOverlap,'rows');
idx = ismember(c0, cDelete, 'rows');
sum(idx)

cellData0.Status(:,1) = "Live";
cellData0.Status(idx) = "Dead";

Status{f} = cellData0.Status;
end

Status = vertcat(Status{:});
cellDataOut.Status = Status;
