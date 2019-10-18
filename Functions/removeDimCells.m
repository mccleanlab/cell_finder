function [cellDataOut] = removeDimCells(cellDataIn,targetChannel,threshold,option)

cellDataOut = cellDataIn;
if option == 0
    cellDataOut((cellDataOut.(targetChannel))<threshold,:) = [];
elseif option == 1
    cellDataOut.FalsePositiveFlag(:,1) = 0;
    cellDataOut.FalsePositiveFlag(cellDataOut.(targetChannel)<threshold) = 1;
end


