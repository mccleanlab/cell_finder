function imOut = simpleBGsubtract(images,channel)


h = size(images.(channel),1);
w = size(images.(channel),2);
nf = size(images.(channel),3);
np = size(images.(channel),4);

imOut = zeros(h,w,nf,np);
imOut = uint16(imOut);

for p = 1:np    
    for f = 1:nf
        im0 = images.(channel)(:,:,f,p);
        bg0 = images.([channel '_mode'])(f,p);        
        imOut(:,:,f,p) = im0 - bg0;
    end
end
