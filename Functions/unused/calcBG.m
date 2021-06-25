function [valBG, maskBG] = calcBG(imCell,imMeasure,tBG,params)
% Calculates background subtraction value
t = tBG;
imCell0 = imCell(:,:,t);
imCell0(imCell0==0)=median(imCell0(:));
imCell0 = imadjust(imCell0,stretchlim(imCell0,[0 1]));

imMeasure0 = imMeasure(:,:,t);

mask = ones(params.h,params.w);

clearvars cNuc rNuc cCell rCell numInCell

% Find just cell ROIs from cell image (very permissive)
[cCell, rCell] = imfindcircles(imCell0,params.sizeCell,'ObjectPolarity','dark','Sensitivity',0.95);

% Draw BG mask
for c = 1:length(rCell)
    [mc, mr] = meshgrid(1:params.w, 1:params.h);
    mCell = (mr - cCell(c,2)).^2 + (mc - cCell(c,1)).^2 <= 1.5.*rCell(c).^2;
    mask(mCell~=0) = 0;
end

% Calculate BG value from masked image
valBG = mode(imMeasure0(imMeasure0~=0));
maskBG = [];

