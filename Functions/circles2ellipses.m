function cellDataOut = circles2ellipses(cellDataIn,images,channelCell,BG,displayEllipses,preprocess_imEllipse)

% cellDataIn = cellData;
% channelCell = 'GFP';
% BG = mode(images.GFP,'all');

nf = images.iminfo.nf;
np = images.iminfo.np;
cellDataOut = cell(np*nf,1);
idxData = 1;
disp('Converting circles to ellipses:')

for p = 1:np
    for f = 1:nf
        disp(['     Frame ' num2str(f)]);
        
        cellData0 = cellDataIn(cellDataIn.Frame==f & cellDataIn.Position==p,:);
        nCell = size(cellData0,1);
        
        x0 = nan(nCell,1);
        y0 = nan(nCell,1);
        a = nan(nCell,1);
        b = nan(nCell,1);
        alpha = nan(nCell,1);
        
        im0 = images.(channelCell)(:,:,f,p);
        if ~isempty(preprocess_imEllipse)
            im = preprocess_imEllipse(im0,BG);
        else
            im = im0;
        end
        padsize = [100 100];
        im = padarray(im,padsize,'replicate');
        
        for c = 1:nCell
            
            cX = cellData0.cCellX(c);
            cY = cellData0.cCellY(c);
            cR = cellData0.rCell(c);
            
            cS = 2;
            
            imC = imcrop(im, [cX + padsize(1) - cS*cR, cY + padsize(2) - cS*cR, cS*2*cR, cS*2*cR]);
            
            [imX, imY] = size(imC);
            xc = imX/2;
            yc = imY/2;
            [xx,yy] = meshgrid(1:imX,1:imY);
            mask = false(imX,imY);
            mask = mask | hypot(xx - xc, yy - yc) >= 0.75*cR & hypot(xx - xc, yy - yc) <= cS*cR;
            
            
            %             imC = edge(imC,'canny',0.75);
            imC(~mask)=0;
            %             imC = bwareaopen(imC, 30);
            imshow(imC);
            
            ellipseParams = [];
            ellipseParams.cR = cR;
            ellipseParams.minMajorAxis = round(0.6*2*cR);
            ellipseParams.maxMajorAxis = round(1.4*2*cR);
            ellipseParams.minAspectRatio = 0.7;
            ellipseParams.numBest = 1;
            ellipseParams.cR = cR;
            ellipseParams.randomize = 2;
            bestFits = ellipseDetectionKS(imC,ellipseParams);
            
            x0(c) = cX - cS*cR + bestFits(1);
            y0(c) = cY - cS*cR + bestFits(2);
            a(c) = bestFits(3);
            b(c) = bestFits(4);
            alpha(c) = bestFits(5);
            
            if displayEllipses==1
                clf
                
                imshow(imC,[],'InitialMagnification',400); hold on
                ellipse(a(c),b(c),alpha(c),bestFits(1),bestFits(2),'y')
                pause(1)
            end
        end
        
        cellData0.Frame(1:nCell,1) = f;
        cellData0.Position(1:nCell,1) = p;
        cellData0.ID(1:nCell,1) = randi([0 1E9],nCell,1);
        cellData0.cCellX(1:nCell,1) = x0;
        cellData0.cCellY(1:nCell,1) = y0;
        cellData0.rCellA(1:nCell,1) = a;
        cellData0.rCellB(1:nCell,1) = b;
        cellData0.rCellAlpha(1:nCell,1) = alpha';
        
        cellDataOut{idxData} = cellData0;
        idxData = idxData + 1;
    end
end

cellDataOut = vertcat(cellDataOut{:});
