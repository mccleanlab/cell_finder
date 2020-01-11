function dataOut = removeDimCells(dataIn,channels2threshold,threshold,option,frame2cluster)
dataOut = dataIn;

for p = 1:max(dataIn.Position)
    
    data0 = dataIn(dataIn.Frame==frame2cluster & dataIn.Position==p,:);
    
    data2cluster = [];
    % Cluster potential cells by channel2cluster
    for i = 1:numel(channels2threshold)
        channel = channels2threshold{i};
        data2cluster(:,i) = data0.(channel);
    end
    
    qidx = kmeans(zscore(data2cluster),2);
    data2cluster(:,i+1) = qidx;
    
    % Find cells as cluster with highest mean value in channel2cluster
    qidx_mean = [1, mean(data2cluster(data2cluster(:,i+1)==1,:)); 2, mean(data2cluster(data2cluster(:,i+1)==2,:))];
    qidx_mean = sortrows(qidx_mean,2,'descend');
    idx_cells = qidx_mean(1,1);
    idx_noncells = qidx_mean(2,1);
    
    % Calculate threshold as minimum value of channel2cluster in cell cluster
    min_cells = min(data2cluster(data2cluster(:,i+1)==idx_cells,:));
    max_noncells = max(data2cluster(data2cluster(:,i+1)==idx_noncells,:));
    
    % Find channel with greatest separation between clusters and set
    d = min_cells(:,1:end-1) - max_noncells(:,1:end-1);
    [~, idx_d] = max(d);
    channel2threshold = channels2threshold{idx_d};
    
    if isempty(threshold)
        threshold = max_noncells(idx_d);
    end
        
    if option == 0 % Delete cells below threshold
        dataOut(dataOut.Position==p & (dataOut.(channel2threshold))<threshold,:) = [];
    elseif option == 1 % Flag cells below treshold
        dataOut.FalsePositive(dataOut.Position==p) = 0;
        dataOut.FalsePositive((dataOut.Position==p) & dataOut.(channel2threshold)<threshold) = 1;
    end
    
end
