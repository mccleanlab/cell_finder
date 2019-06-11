function [imOut,xformOut] = registerImagesFast(im,xformIn)
% Registers each image to prevous frame using dftregistration
% mathworks.com/matlabcentral/fileexchange/18401-efficient-subpixel-image-registration-by-cross-correlation

% Parameters
usfac = 100;
nf = size(im,3);


% Register images
if isempty(xformIn)
    % Calculate transformation matrix and register images
    for f = 1:nf
        if f==1
            targetFrame=1;
            imReg = im(:,:,targetFrame);
            xformOut(f).affineParams = [0 0 0 0];
        else
            targetFrame=f-1;
            [xform, ~] = dftregistration(fft2(im2double(im(:,:,targetFrame))),fft2(im2double(im(:,:,f))),usfac);
            xformOut(f).affineParams = xformOut(f-1).affineParams + xform;
            imReg = imtranslate(im(:,:,f),[xformOut(f).affineParams(4), xformOut(f).affineParams(3)],'FillValues',mode(im(:,:,f),'all'));
        end
        imOut(:,:,f) = imReg;
    end
else
    % Apply precalculated transformation matrix to register images
    for f = 1:nf
        if f==1
            targetFrame=1;
            imReg = im(:,:,targetFrame);
        else
            targetFrame=f-1;
            xform = xformIn(f).affineParams;
            imReg = imtranslate(im(:,:,f),[xform(4), xform(3)],'FillValues',mode(im(:,:,f),'all'));
        end
        imOut(:,:,f) = imReg;
        xformOut(f).affineParams = [];
    end
end
