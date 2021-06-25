function dataOut = subtractBGtable(data,BG,groupingVars,channels2BGsubtract)

deleteidx = contains(data.Properties.VariableNames,'SD') | contains(data.Properties.VariableNames,'mode');
data(:,deleteidx) = [];

for g = 1:numel(groupingVars)
    groupvar = groupingVars{g};
    groupvals = string(unique(data.(groupvar),'stable'));
    for v = 1:numel(groupvals)
        val = groupvals{v};
        for i = 1:numel(channels2BGsubtract)
            rowidx = string(data.(groupvar))==string(val);
            channel = channels2BGsubtract{i};
            columnidx = contains(data.Properties.VariableNames,channel) & ~contains(data.Properties.VariableNames,'mode');            
            data{:,columnidx} = data{:,columnidx} - BG;            
        end
    end
end
dataOut = data;
