function exportCellEllipseDisplay(cellData,images,channel,params)

nf = size(images.(channel),3);
np = size(images.(channel),4);

if exist([params.outputFolder params.outputFilenameBase '_cellTracksEllipse' '.tif'])~=0
    delete([params.outputFolder params.outputFilenameBase '_cellTracksEllipse' '.tif']);
end

im = images.(channel);

for p = 1:np
    for f = 1:nf
        
        cellData0= cellData(cellData.Frame==f & cellData.Position==p,:);
        im0 = im(:,:,f,p);
        assignin('base','test',im0);
                
        h = figure;
        set(gcf,'visible','off');
        imshow(im0,[],'InitialMagnification',100);
        ellipse(cellData0.rCellA,cellData0.rCellB,cellData0.rCellAlpha,cellData0.cCellX,cellData0.cCellY,'y');
        
        truesize(h)
        h = getframe(h);
        imOut = h.cdata;                
        imwrite(imOut, [params.outputFolder params.outputFilenameBase '_cellTracksEllipse' '.tif'],'WriteMode','append');
        
    end
end

