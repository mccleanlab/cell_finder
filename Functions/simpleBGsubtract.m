function imOut = simpleBGsubtract(im,bg)

nf = size(im,3);

for f = 1:nf
    im0 = im(:,:,f);
    bg0 = bg(f);
    imOut(:,:,f) = im0 - bg0;
end
