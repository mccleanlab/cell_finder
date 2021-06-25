% function [dataOut, imOut] = measureConfluency(images,channel)
channel = 'GFP';
[h, w, nf, np] = size(images.(channel)(:,:,:,:));
total_px = h*w;
imOut = zeros(h,w,nf,np,'logical');

idx = 1;
dataOut = struct();

for p=1%:np
%     BG = mode(images.GFP(:,:,:,p),'all');
    BG = mode(images.GFP(:,:,:,p),[1,2]);
    BG = prctile(BG,5);
    
    im0 = images.GFP(:,:,1,p);
    im = im0 - BG;
    
    im = imopen(im,strel('disk',10));
    threshold = graythresh(im);
    
    for f=45%:nf
        im0 = images.GFP(:,:,f,p);
        im = im0 - BG;
            im = imflatfield(im,100);
            im = imbilatfilt(im);

        imshow(im,[]); pause
%         im = imopen(im,strel('disk',10));
        
%         im = imbinarize(im,'adaptive','Sensitivity',0.8);
                imshow(im,[])

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

