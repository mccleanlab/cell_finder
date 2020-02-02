function [imOut,xformOut] = registerImagesFast(images,channel,xformIn,fill)
% Registers each image to prevous frame using dftregistration
% mathworks.com/matlabcentral/fileexchange/18401-efficient-subpixel-image-registration-by-cross-correlation

im = images.(channel);

if isempty(fill)
    fill = images.([channel '_mode']);
end

disp(['Registering ' channel ' images'])

% Parameters
usfac = 100;
nf = size(im,3);
np = size(im,4);


% Register images
if isempty(xformIn)
    % Calculate transformation matrix and register images
    for p = 1:np
        for f = 1:nf
            if f==1
                targetFrame=1;
                imReg = im(:,:,targetFrame,p);
                xformOut(f,p).affineParams = [0 0 0 0];
            else
                targetFrame=f-1;
                [xform, ~] = dftregistration(fft2(im2double(im(:,:,targetFrame,p))),fft2(im2double(im(:,:,f,p))),usfac);
                xformOut(f,p).affineParams = xformOut(f-1,p).affineParams + xform;
                imReg = imtranslate(im(:,:,f,p),[xformOut(f,p).affineParams(4), xformOut(f,p).affineParams(3)],'FillValues',fill(f,p));
            end
            imOut(:,:,f,p) = imReg;
        end
    end
else
    % Apply precalculated transformation matrix to register images
    for p = 1:np
        for f = 1:nf
            if f==1
                targetFrame=1;
                imReg = im(:,:,targetFrame,p);
            else
                targetFrame=f-1;
                xform = xformIn(f,p).affineParams;
                imReg = imtranslate(im(:,:,f,p),[xform(4), xform(3)],'FillValues',fill(f,p));
            end
            imOut(:,:,f,p) = imReg;
            xformOut(f,p).affineParams = [];
        end
    end
end
