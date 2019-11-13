function dataOut = countCells(dataIn)

for f = 1:max(dataIn.Frame)
    
    % Number of cells per position per frame
    for p = 1:max(dataIn.Position)
        % Count cells for frame/position
        nCells_Position = size(dataIn(dataIn.Frame==f & dataIn.Position==p,1),1);
        
        % If no cells in frame/position, add row to table with # cells = 0
        if nCells_Position==0
            newrow = dataIn(1,:);
            idx_keep =  contains(dataIn.Properties.VariableNames,'sourceFile');
            newrow{1,~idx_keep} = nan;
            newrow.Frame=f;
            newrow.Position=p;
            newrow.nCells_Position = 0;
            dataIn = [dataIn; newrow];
            dataIn = sortrows(dataIn,{'Frame','Position'});
        end
        
        % Otherwise just append the cell count to table
        dataIn.nCells_Position(dataIn.Frame==f & dataIn.Position==p) = nCells_Position;
        
    end
    
    % Number of cells per frame
    nCells = size(dataIn(dataIn.Frame==f,1),1);
    dataIn.nCells(dataIn.Frame==f) = nCells; 
    
    dataOut = dataIn;

end