function [cellDataTrackOut, tracksFinal] = utrack(cellData,trackVar,params)


trackVar = 'Cells';
tracksFinal = [];
cellDataTrack = [];
nf = max(cellData.Frame(:));
np = max(cellData.Position(:));

%% Format data for input to utrack
for p =1:np
    data =[];
    data = cellData(cellData.Position==p,:);
    
    
    for f = 1:nf
        if strcmp(trackVar,'Nuclei')
            x = data.cNucX(data.Frame==f);
            y = data.cNucY(data.Frame==f);
        elseif strcmp(trackVar,'Cells')
            x = data.cCellX(data.Frame==f);
            y = data.cCellY(data.Frame==f);
        end
        dx = 0;
        dx = repmat(dx,[numel(x),1]);
        dy = dx;
        amp = 1;
        
        points(f).xCoord = [x, dx];
        points(f).yCoord = [y, dy];
        points(f).amp = [data.rCell(data.Frame==f), zeros(numel(x),1)];
        %     points(t).amp = [repmat(amp,[numel(x),1]), zeros(numel(x),1)];
    end
    
    movieInfo = points';
    
    %% utrack params
    
    gapCloseParam.timeWindow = 10; % maximum allowed time gap (in frames) between a track segment end and a track segment start that allows linking them.
    gapCloseParam.timeWindow = params.trackGap;
    gapCloseParam.mergeSplit = 1; % 1 if merging and splitting are to be considered, 2 if only merging is to be considered, 3 if only splitting is to be considered, 0 if no merging or splitting are to be considered.
    gapCloseParam.minTrackLen = 2; % minimum length of track segments from linking to be used in gap closing.
    
    %optional input:
    gapCloseParam.diagnostics = 0; % 1 to plot a histogram of gap lengths in the end; 0 or empty otherwise.
    
    %% cost matrix for frame-to-frame linking
    
    %function name
    costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';
    
    parameters.linearMotion = 0; %use linear motion Kalman filter.
    parameters.minSearchRadius = 3; %minimum allowed search radius. The search radius is calculated on the spot in the code given a feature's motion parameters. If it happens to be smaller than this minimum, it will be increased to the minimum.
    parameters.maxSearchRadius = 50; %maximum allowed search radius. Again, if a feature's calculated search radius is larger than this maximum, it will be reduced to this maximum.
    parameters.maxSearchRadius = params.trackMaxDist;
    parameters.brownStdMult = 3; %multiplication factor to calculate search radius from standard deviation.
    
    parameters.useLocalDensity = 1; %1 if you want to expand the search radius of isolated features in the linking (initial tracking) step.
    parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before the current one where you want to look to see a feature's nearest neighbor in order to decide how isolated it is (in the initial linking step).
    
    parameters.kalmanInitParam = []; %Kalman filter initialization parameters.
    % parameters.kalmanInitParam.searchRadiusFirstIteration = 10; %Kalman filter initialization parameters.
    
    %optional input
    parameters.diagnostics = []; %if you want to plot the histogram of linking distances up to certain frames, indicate their numbers; 0 or empty otherwise. Does not work for the first or last frame of a movie.
    
    costMatrices(1).parameters = parameters;
    clear parameters
    
    %% cost matrix for gap closing
    
    %function name
    costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';
    
    %needed all the time
    parameters.linearMotion = 0; %use linear motion Kalman filter.
    
    parameters.minSearchRadius = 3; %minimum allowed search radius.
    parameters.maxSearchRadius = 50; %maximum allowed search radius.
    parameters.maxSearchRadius = params.trackMaxDist;
    parameters.brownStdMult = 3*ones(gapCloseParam.timeWindow,1); %multiplication factor to calculate Brownian search radius from standard deviation.
    
    parameters.brownScaling = [0.25 0.01]; %power for scaling the Brownian search radius with time, before and after timeReachConfB (next parameter).
    % parameters.timeReachConfB = 3; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
    parameters.timeReachConfB = gapCloseParam.timeWindow; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
    parameters.ampRatioLimit = [0 0.75]; %for merging and splitting. Minimum and maximum ratios between the intensity of a feature after merging/before splitting and the sum of the intensities of the 2 features that merge/split.
    parameters.ampRatioLimit = [];
    
    parameters.lenForClassify = 5; %minimum track segment length to classify it as linear or random.
    parameters.useLocalDensity = 1; %1 if you want to expand the search radius of isolated features in the gap closing and merging/splitting step.
    parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before/after the current one where you want to look for a track's nearest neighbor at its end/start (in the gap closing step).
    parameters.linStdMult = 3*ones(gapCloseParam.timeWindow,1); %multiplication factor to calculate linear search radius from standard deviation.
    parameters.linScaling = [1 0.01]; %power for scaling the linear search radius with time (similar to brownScaling).
    % parameters.timeReachConfL = 4; %similar to timeReachConfB, but for the linear part of the motion.
    parameters.timeReachConfL = gapCloseParam.timeWindow; %similar to timeReachConfB, but for the linear part of the motion.
    parameters.maxAngleVV = 30; %maximum angle between the directions of motion of two tracks that allows linking them (and thus closing a gap). Think of it as the equivalent of a searchRadius but for angles.
    
    %optional; if not input, 1 will be used (i.e. no penalty)
    parameters.gapPenalty = 1.5; %penalty for increasing temporary disappearance time (disappearing for n frames gets a penalty of gapPenalty^(n-1)).
    
    %optional; to calculate MS search radius
    %if not input, MS search radius will be the same as gap closing search radius
    parameters.resLimit = []; %resolution limit, which is generally equal to 3 * point spread function sigma.
    parameters.resLimit = 50;
    
    
    %NEW PARAMETER
    parameters.gapExcludeMS = 1; %flag to allow gaps to exclude merges and splits
    
    %NEW PARAMETER
    parameters.strategyBD = -1; %strategy to calculate birth and death cost
    parameters.strategyBD = 99.99; %strategy to calculate birth and death cost
    
    costMatrices(2).parameters = parameters;
    clear parameters
    
    %% Kalman filter function names
    
    kalmanFunctions.reserveMem  = 'kalmanResMemLM';
    kalmanFunctions.initialize  = 'kalmanInitLinearMotion';
    kalmanFunctions.calcGain    = 'kalmanGainLinearMotion';
    kalmanFunctions.timeReverse = 'kalmanReverseLinearMotion';
    
    %% Additional input
    saveResults = 0; %saveResults
    verbose = 1; %verbose state
    probDim = 2;%problem dimension
    
    %% Tracking function call
    [tracksFinal,~,~] = trackCloseGapsKalmanSparse(movieInfo,costMatrices,gapCloseParam,kalmanFunctions,probDim,saveResults,verbose);
    % [trackedFeatureInfo, ~, ~, ~] = convStruct2MatIgnoreMS(tracksFinal);
    
    %% Format data for ouput
    
    TrackID = 1;
    cellDataTrack = [];
    
    for p = 1:np
        data =[];
        data = cellData(cellData.Position==p,:);
        for i = 1:size(tracksFinal,1)
            cellDataTrack0 = [];
            tracksFinal0 = tracksFinal(i);
            nTracks = size(tracksFinal0.tracksFeatIndxCG,1);
            
            for locidx = 1:nTracks
                cellDataTrack00 = [];
                idxlist = tracksFinal0.tracksFeatIndxCG(locidx,:);
                tList = find(idxlist~=0);
                idxlist(idxlist==0)=[];
                
                for j = 1:length(idxlist)
                    cellDataTrack000 = [];
                    f = tList(j);
                    idx = idxlist(j);
                    cellDataTrack000 = data(data.Frame==f & data.ID==idx,:);
                    if j==1
                        cellDataTrack00 = cellDataTrack000;
                    else
                        cellDataTrack00 = [cellDataTrack00; cellDataTrack000];
                    end
                end
                
                cellDataTrack00.locidx = repmat(locidx,size(cellDataTrack00,1),1);
                cellDataTrack00.TrackID = repmat(TrackID,size(cellDataTrack00,1),1);
                TrackID = TrackID + 1;
                
                if locidx==1
                    cellDataTrack0 = cellDataTrack00;
                else
                    cellDataTrack0 = [cellDataTrack0; cellDataTrack00];
                end
            end
            
%             cellDataTrack0.Parent = nan(size(cellDataTrack0,1),1);
%             
%             for locidx = 1:nTracks
%                 events = tracksFinal0.seqOfEvents;
%                 [idx, ~] = find(events(:,2)==1 & events(:,3)==locidx);
%                 parent1 = [];
%                 parent = [];
%                 parent = tracksFinal0.seqOfEvents(idx,4)
%                 
%                 if ~isempty(parent) && ~isnan(parent(1))
%                     parent = cellDataTrack0.TrackID(cellDataTrack0.locidx==parent);
%                     parent = parent(1);
%                     cellDataTrack00 = cellDataTrack0(cellDataTrack0.locidx==locidx,:);
%                     cellDataTrack0.Parent(cellDataTrack0.locidx==locidx) = repmat(parent,size(cellDataTrack00,1),1);
%                 end
%                 
%             end
            
            if i==1
                cellDataTrack = cellDataTrack0;
            else
                cellDataTrack = [cellDataTrack; cellDataTrack0];
            end
            
        end
        if p==1
            cellDataTrackOut = cellDataTrack;
        else
            cellDataTrackOut = [cellDataTrackPos; cellDataTrack];
        end
    end
    %     cellDataTrackOut = [];
end

    
