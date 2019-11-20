function [dataOut, imOut] = measureConfluency(images)

[h, w, nf, np] = size(images.GFP(:,:,:,:));
total_px = h*w;
imOut = zeros(h,w,nf,np,'uint16');

idx = 1;

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
        confluency = nCell_px/total_px;
        
        % Append measurement to table
        dataOut(idx).Frame = f;
        dataOut(idx).Position = p;
        dataOut(idx).Confluency = confluency;
        idx = idx + 1;
    end
end

dataOut = struct2table(dataOut);

