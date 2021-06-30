function [images, params] = appendND2(imagelist,channels,numFrames,numPositions,params)

%%
% imagelist = selectImages();
% channels = {'DIC','mCherry','GFP'};
channels2mode =  strcat(channels,'_mode');

for idx = 1:numel(imagelist)
    [im0(idx), params] = loadND2(imagelist,idx,channels,numFrames,numPositions,params);       
end

%%

imdata = cellfun(@(f) {cat(3,im0.(f))},channels);
imdata = cell2struct(imdata,channels,2);

immode = cellfun(@(f) {cat(1,im0.(f))},channels2mode);
immode = cell2struct(immode,channels2mode,2);

info = cellfun(@(f) {cat(1,im0.(f))},{'iminfo'});
info = struct2table(info{:,:});
iminfo.h = info.h(1);
iminfo.w = info.w(1);
iminfo.nf = sum(info.nf);
iminfo.np = info.np(1);

%%
fnames = [fieldnames(imdata); fieldnames(immode);];
images = cell2struct([struct2cell(imdata); struct2cell(immode)], fnames, 1);
images.iminfo = iminfo;