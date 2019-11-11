function dataOut = removeDimCells(dataIn,channel2threshold,threshold,option,frame2cluster)

if isempty(threshold)
    % Cluster potential cells by channel2cluster
    qidx = kmeans(dataIn.(channel2threshold)(dataIn.Frame==frame2cluster),2);    
    
    % Find cells as cluster with highest mean value in channel2cluster
    qidx_mean = [1, mean(dataIn.(channel2threshold)(qidx==1)); 2, mean(dataIn.(channel2threshold)(qidx==2))];
    qidx_mean = sortrows(qidx_mean,2,'descend');
    idx_cells = qidx_mean(1,1);
    
    % Calculate threshold as minimum value of channel2cluster in cell cluster
    threshold = min(dataIn.(channel2threshold)(qidx==idx_cells));
    threshold
end

dataOut = dataIn;

if option == 0 % Delete cells below threshold
    dataOut((dataOut.(channel2threshold))<threshold,:) = [];
elseif option == 1 % Flag cells below treshold
    dataOut.FalsePositiveFlag(:,1) = 0;
    dataOut.FalsePositiveFlag(dataOut.(channel2threshold)<threshold) = 1;
end


