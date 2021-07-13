function [im_registered_out,xforms_out] = register_images(images,channel,xforms_in)

% Registers each image to prevous frame using dftregistration
% mathworks.com/matlabcentral/fileexchange/18401-efficient-subpixel-image-registration-by-cross-correlation

% Get images to register and their dimensions
im = images.(channel);
[h, w, number_frames,number_positions]  = size(im);

% disp(['Registering ' channel ' images'])

% Set parameters
upsampling_factor = 1;
fill_value = 0;

% Initialize variables
xforms_out = cell(number_frames,number_positions);
im_registered_out = zeros(h,w,number_frames,number_positions,'uint16');

% If no transformation matrix provided, calculate one
if ~exist('xforms_in','var') || isempty(xforms_in)
    
    % Calculate transformation matrix
    for p = 1:number_positions
        
        for f = 1:number_frames
            
            disp(strcat("Calculating registration matrix: ",channel," frame ",num2str(f)," position ",num2str(p)))
            
            if f==1
                %                 target_frame=1;
%                 im_registered_temp = im(:,:,1,p);
                xforms_out{f,p} = [0 0 0 0];
            else
                
                [xforms_temp, ~] = dftregistration(fft2(im2double(im(:,:,f-1,p))),fft2(im2double(im(:,:,f,p))),upsampling_factor);
                xforms_out{f,p} = xforms_out{f-1,p} + xforms_temp;
%                 im_registered_temp = imtranslate(im(:,:,f,p),[xforms_out{f,p}(4), xforms_out{f,p}(3)],'FillValues',fill_value);
                
            end
            
            %             im_registered_out(:,:,f,p) = im_registered_temp;
            
        end
    end
    
    
else % If transformation matrix provided, use to register images
    for p = 1:number_positions
        for f = 1:number_frames
            
            disp(strcat("Applying registration matrix: ",channel," frame ",num2str(f)," position ",num2str(p)))
            
            % Apply registration matrix
            if f==1
                im_registered_temp = im(:,:,1,p);
            else
                xforms_temp = xforms_in{f,p};
                im_registered_temp = imtranslate(im(:,:,f,p),[xforms_temp(4), xforms_temp(3)],'FillValues',fill_value);
            end
            
            im_registered_out(:,:,f,p) = im_registered_temp;
            
            %             xforms_out{f,p} = [];
            
        end
    end
end
