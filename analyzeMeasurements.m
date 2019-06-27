clearvars
close all
%% Load files and append to table
data = [];
[files, folder] =  uigetfile('.xls','MultiSelect','on');
if ischar(files)==1
    files = {files};
end

for i = 1:length(files)
    file = files{i};
    data0 = readtable([folder file]);
    data = [data; data0];
end

%% Edit table 
data.Sample = string(extractBetween(data.SourceFile,'SplitImages\','.tif'));
% data.Sample = regexprep(data.Sample,'WELL\w\d*_yMM1454_','','ignorecase');
% data.Sample = regexprep(data.Sample,'_mCh','','ignorecase');
% data.Time = data.Time.*2 - 2;

% idx = [];
% idx = strfind(data.Sample,'pMM0615');
% idx = find(~cellfun(@isempty,idx));
%
% data.Zdk2 = repmat('pMM0007',height(data),1);
% data.Zdk2(idx,:) = repmat('pMM0615',length(idx),1);
% data.Zdk2 = string(data.Zdk2);

%% Set variable of interest (VOI)
VOI = 'mCh_Localization';

%% Plot mean and CI
measurements = grpstats(data,{'Time','Sample'},{'mean','meanci'},'DataVars',VOI);

samplelist = (unique(measurements.Sample,'stable'));
cmap = colormap(parula(numel(samplelist)));

for i = 1:numel(samplelist)
    hold on
    s = string(samplelist{i});
    x = measurements(measurements.Sample==s,:);
    hCI = fill([x.Time',fliplr(x.Time')],[x.(['meanci_' VOI])(:,1)',fliplr(x.(['meanci_' VOI])(:,2)')],cmap(i,:));
    set(hCI,'facealpha',0.25,'EdgeColor','none','HandleVisibility','off');
    plot(x.Time,x.(['mean_' VOI]),'-','LineWidth',2,'Color',cmap(i,:))
end

legend(samplelist,'Location','northwest','Interpreter','none');
legend('boxoff');
f = gca;
f.XLabel.String = 'Time (min)'; set(f.YLabel, 'Interpreter', 'none');
f.YLabel.String = [VOI newline '(mean ± CI)']; set(f.YLabel, 'Interpreter', 'none');

%% Boxplot
figure;
boxplot(data.(VOI),{data.Time});
% ylim([1 1.4])

%% Plot single cell traces
figure;
cellList = unique(data.TrackID,'stable');

for c = 1:numel(cellList)
    hold on
    cidx = cellList(c);
    t = data.Time(data.TrackID==cidx);
    y = data.(VOI)(data.TrackID==cidx);
    plot(t,y)
end

%% Calculate fold change (FC)

for c = 1:numel(cellList)
    cidx = cellList(c);    
    init = data.(VOI)(data.Time==1 & data.TrackID==cidx);
    if ~isempty(find(data.Time(data.TrackID==cidx)==1,1))
%         ~isempty(find(data.Time(data.TrackID==cidx)==1))
        
        data.([VOI '_FC'])(data.TrackID==cidx)= data.(VOI)(data.TrackID==cidx)./init;
    else
        data.([VOI '_FC'])(data.TrackID==cidx)= data.(VOI)(data.TrackID==cidx).*nan;
    end
end

%% Plot fold change
for c = 1:numel(cellList)
    hold on
    cidx = cellList(c);
    t = data.Time(data.TrackID==cidx);
    y = data.([VOI '_FC'])(data.TrackID==cidx);
    plot(t,y)
end

boxplot(data.([VOI '_FC']),{data.Time})

%% Photobleach correction (PBC)
figure; hold on
VOI = 'mCh_Cell_median';

% Plot initial data
y = varfun(@nanmedian, data,'InputVariables',VOI,'GroupingVariables','Time');
t = y{:,1};
y = y{:,3};
plot(t,y,'b')

% Plot data used for fit
y = varfun(@nanmedian, data(data.Time<=10 | data.Time>=54 & data.Time<=60 | data.Time>=87 & data.Time<=93,:),'InputVariables',VOI,'GroupingVariables','Time');
t = y{:,1};
y = y{:,3};
plot(t,y,'bo')

% Fit to calculate PBC parameters
options = fitoptions('exp2');
options.Lower = [-Inf -Inf -Inf 0];
options.Upper = [Inf Inf Inf 0];
f = fit(t,y,'exp2',options);
PBC = @(x,t) (x - f.c)./exp(f.b.*t);
plot(f)

% Apply PBC
data_PBC = data;
for c=8:17
    data_PBC{:,c} = PBC(data_PBC{:,c},data_PBC.Time);
end

y = varfun(@nanmedian, data_PBC,'InputVariables',VOI,'GroupingVariables','Time');
t = y{:,1};
y = y{:,3} + f.c;
plot(t,y,'c')


