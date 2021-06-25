function  imagelist = selectImages()
imagelist = {};
[file, folder] = uigetfile('*.nd2;*.tif;*.tiff','MultiSelect','on');

if ischar(file)==1
    file = {file};
else
    file = file';
end

for f = 1:numel(file)
    imagelist{f} = [folder file{f}];
end

imagelist = imagelist';


