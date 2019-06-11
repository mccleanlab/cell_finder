function [imOut,xformOut] = registerImagesFast(im,xformIn)
% Registers each image to prevous frame using dftregistration
% mathworks.com/matlabcentral/fileexchange/18401-efficient-subpixel-image-registration-by-cross-correlation

% Parameters
usfac = 100;
nt = size(im,3);

% Register images
if isempty(xformIn)
    % Calculate transformation matrix and register images
    for t = 1:nt
        if t==1
            targetFrame=1;
            imReg = im(:,:,targetFrame);
            xformOut(t).affineParams = [0 0 0 0];
        else
            targetFrame=t-1;
            [xform, ~] = dftregistration(fft2(im2double(im(:,:,targetFrame))),fft2(im2double(im(:,:,t))),usfac);
            xformOut(t).affineParams = xformOut(t-1).affineParams + xform;
            imReg = imtranslate(im(:,:,t),[xformOut(t).affineParams(4), xformOut(t).affineParams(3)]);
        end
        imOut(:,:,t) = imReg;
    end    
else
   % Apply precalculated transformation matrix to register images 
    for t = 1:nt
        if t==1
            targetFrame=1;
            imReg = im(:,:,targetFrame);
        else
            targetFrame=t-1;
            xform = xformIn(t).affineParams;
            imReg = imtranslate(im(:,:,t),[xform(4), xform(3)]);
        end
        imOut(:,:,t) = imReg;
        xformOut(t).affineParams = [];
    end
end
