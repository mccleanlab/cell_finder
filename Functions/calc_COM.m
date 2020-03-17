function dataOut = calc_COM(dataIn,channel)

% dataIn = data2plot; channel = 'GFP_Cell_mean';

func = @(x,c) sum(x.*c)./sum(c);
x = rowfun(func,dataIn,'GroupingVariables',{'Frame','Position'},'InputVariables',{'cCellX',channel});
y = rowfun(func,dataIn,'GroupingVariables',{'Frame','Position'},'InputVariables',{'cCellY',channel});
x.GroupCount = [];
y.GroupCount = [];
x.Properties.VariableNames = {'Frame', 'Position', [channel '_xCOM']};
y.Properties.VariableNames = {'Frame', 'Position', [channel '_yCOM']};

dataOut = join(dataIn,x);
dataOut = join(dataOut,y);
% COM = join(x,y);
% dataOut = join(dataIn,COM);
end