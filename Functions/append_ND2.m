function [images, params] = append_ND2(imagelist,channels,number_positions,params)

%%
% imagelist = selectImages();
% channels = {'DIC','mCherry','GFP'};
channels_get_mode =  strcat(channels,'_mode');

for idx = 1:numel(imagelist)
    [im_temp(idx), params] = load_ND2(imagelist,idx,channels,number_positions,params);       
end

%%
im_data = cellfun(@(f) {cat(3,im_temp.(f))},channels);
im_data = cell2struct(im_data,channels,2);

im_mode = cellfun(@(f) {cat(1,im_temp.(f))},channels_get_mode);
im_mode = cell2struct(im_mode,channels_get_mode,2);

info = cellfun(@(f) {cat(1,im_temp.(f))},{'iminfo'});
info = struct2table(info{:,:});
iminfo.h = info.h(1);
iminfo.w = info.w(1);
iminfo.nf = sum(info.nf);
iminfo.np = info.np(1);

%%
field_names = [fieldnames(im_data); fieldnames(im_mode);];
images = cell2struct([struct2cell(im_data); struct2cell(im_mode)], field_names, 1);
images.iminfo = iminfo;