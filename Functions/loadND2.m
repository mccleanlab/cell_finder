function [images, params, im] = loadND2(imagelist,imidx,channellist,numFrames,numPositions,params)
% numFrames = [];
% numPositions = 5;
% imidx = 1;

imfile = imagelist{imidx};
[~, filename, ext] = fileparts(imfile);
disp(['Loading ' filename]);
im = bfopen(imfile);
nseries = size(im,1);

if isempty(numPositions)
    numPositions =1;
end

%%


for series = 1:nseries
    nplane = size(im{series,1},1);
    for plane = 1:nplane
        imdata = [];
        planelabel = [];
        imdata = im{series,1}{plane,1};
        planelabel = im{series,1}{plane,2};
        
        channel = regexp(planelabel,'C\?=\d*/\d*|C=\d*/\d*','match');
        channel = regexprep(channel,'\C=|\C\?=','');
        channel = regexprep(channel,'\/\d*','');
        channel = str2double(channel);
        channelname = channellist(channel);
        channelname = channelname{:};
        
        frame = regexp(planelabel,'T\?=\d*/\d*|T=\d*/\d*','match');
        frame = regexprep(frame,'\T=|\T\?=','');
        frame = regexprep(frame,'\/\d*','');
        frame = str2double(frame);
        
        if isempty(frame)
            frame = 1;
        end
        
        if numPositions~=1
            position = series;
        else
            position = 1;
        end
        
        if isempty(numFrames)
            images.(channelname)(:,:,frame,position) = imdata;
            immode = mode(imdata(:));
            im95pct = prctile(imdata(:),95);
            if immode > im95pct
%                 disp(['Warning: ' channelname ' frame ' num2str(frame) ' position ' num2str(position) ' mode intensity greater than 95th percentile intensity'])
                disp(['Warning: Excluding likely saturated pixel values from mode calculation for ' filename ext ' ' channelname ' frame ' num2str(frame) ' position ' num2str(position)]);
                immode = mode(imdata(imdata~=immode));
            end
            images.([channelname '_mode'])(frame,position) = immode;
            
        elseif frame<=numFrames
            images.(channelname)(:,:,frame,position) = imdata;
            images.([channelname '_mode'])(frame,position) = mode(imdata(:));
        end
    end    
end

images.iminfo.h = size(images.(channellist{1}),1);
images.iminfo.w = size(images.(channellist{1}),2);
images.iminfo.nf = size(images.(channellist{1}),3);
images.iminfo.np = size(images.(channellist{1}),4);

[folder, filename, ext] = fileparts(imfile);
match = [ext, channellist];
params.sourceFile = filename;
params.outputFilenameBase = erase(filename, match);
params.outputFolder = [folder '\output\'];

