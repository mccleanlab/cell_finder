function [dataOut, imOut] = measureFOV(images,dataIn)

[h, w, nf, np] = size(images.GFP(:,:,:,:));
total_px = h*w;

imOut = zeros(h,w,nf,np,'uint16');
idx = 1;
fractionFOV_out = nan(nf,np);

for p=1:np
    BG = mode(images.GFP(:,:,:,p),'all');
    
    im0 = images.GFP(:,:,1,p);
    im = im0 - BG;
    im = imopen(im,strel('disk',10));
    threshold = graythresh(im);
    
    for f=1:nf
        im0 = images.GFP(:,:,f,p);
        im = im0 - BG;
        im = imopen(im,strel('disk',10));
        im = imbinarize(im,threshold);
        
        imOut(:,:,f,p) = im;
        
        nCell_px = numel(im(im==1));
        fractionFOV = nCell_px/total_px;
        fractionFOV_out(f,p) = fractionFOV;
        
        % Append measurement to table
        data0 = dataIn(dataIn.Position==p & dataIn.Frame==f,:);
        data0.fractionFOV_position(:,1) = fractionFOV;
        dataOut{idx} = data0;
        idx = idx + 1;
    end
end

dataOut = vertcat(dataOut{:});

