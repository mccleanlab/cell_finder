function [imOut,xformOut] = registerImagesFast(images,channel,xformIn)

% Registers each image to prevous frame using dftregistration
% mathworks.com/matlabcentral/fileexchange/18401-efficient-subpixel-image-registration-by-cross-correlation

% channel = 'iRFP';
im = images.(channel);
% xformIn=[];

% if isempty(fill)
%     fill = images.([channel '_mode']);
% end

disp(['Registering ' channel ' images'])

% Parameters
usfac = 1;
nf = size(im,3);
np = size(im,4);
fill = 0;

xformOut = {};

% Register images
% if exist('xformIn','var')==0
if exist('xformIn','var')==0 || isempty(xformIn)
    % Calculate transformation matrix and register images
    for p = 1:np
        for f = 1:nf
            if f==1
                targetFrame=1;
                imReg = im(:,:,targetFrame,p);
                xformOut{f,p} = [0 0 0 0];
            else
                targetFrame=f-1;
                [xform, ~] = dftregistration(fft2(im2double(im(:,:,targetFrame,p))),fft2(im2double(im(:,:,f,p))),usfac);
                xformOut{f,p} = xformOut{f-1,p} + xform;
                imReg = imtranslate(im(:,:,f,p),[xformOut{f,p}(4), xformOut{f,p}(3)],'FillValues',fill);
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
                xform = xformIn{f,p};
                imReg = imtranslate(im(:,:,f,p),[xform(4), xform(3)],'FillValues',fill);
            end
            imOut(:,:,f,p) = imReg;
            xformOut{f,p} = [];
        end
    end
end
