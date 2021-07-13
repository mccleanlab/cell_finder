function dataOut = countCells(dataIn)

% Number of cells per position per frame
filelist = unique(dataIn.sourceFile);

for file_idx = 1:numel(filelist)
    file = string(filelist{file_idx});
    % Count cells for frame/position
    for p = 1:max(dataIn.Position)
        for f = 1:max(dataIn.Frame)
            nCells_position = size(dataIn(dataIn.Frame==f & dataIn.Position==p & dataIn.sourceFile==file,1),1);
            
            % If no cells in frame/position, add row to table with # cells = 0
            if nCells_position==0
                newrow = dataIn(1,:);
                idx_keep =  contains(dataIn.Properties.VariableNames,'sourceFile');
                newrow{1,~idx_keep} = nan;
                newrow.Frame=f;
                newrow.Position=p;
                newrow.nCells_position = 0;
                dataIn = [dataIn; newrow];
                dataIn = sortrows(dataIn,{'Frame','Position'});
            end
            
            % Otherwise just append the cell count to table
            dataIn.nCells_position(dataIn.Frame==f & dataIn.Position==p & dataIn.sourceFile==file) = nCells_position;
            
            % Number of cells per frame
            nCells = size(dataIn(dataIn.Frame==f & dataIn.sourceFile==file,1),1);
            dataIn.nCells(dataIn.Frame==f & dataIn.sourceFile==file) = nCells;
        end
    end
end

dataIn.fractionCells_position(:,1) = nan;
for p = 1:max(dataIn.Position)
    nCells_position_max = max(dataIn.nCells_position(dataIn.Position==p & dataIn.sourceFile==file));
    dataIn.fractionCells_position(dataIn.Position==p & dataIn.sourceFile==file) = dataIn.nCells_position(dataIn.Position==p & dataIn.sourceFile==file)/nCells_position_max;
end

dataIn.fractionCells = dataIn.nCells/max(dataIn.nCells);
dataOut = dataIn;