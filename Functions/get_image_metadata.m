function im_metadata = get_image_metadata(imagelist)
% imagelist = selectImages();
im_metadata = cell(numel(imagelist),1);

for imidx = 1:numel(imagelist)
    imfile = imagelist{imidx};
    [~, filename, ext] = fileparts(imfile);
    disp(['Loading ' filename]);
    im = bfopen(imfile);
    
    metadata= string(im{1,2});
    timestamps = regexp(metadata,'((?<=timestamp #).*?(?=\,))','match');
    
    frame = string(regexp(timestamps,'\d*\=','match'));
    frame = double(string(regexp(frame,'\d*','match')))';
    
    time = string(regexp(timestamps,'\=\d*\.\d*','match'));
    time = double(string(regexp(time,'\d*\.\d*','match')))';
    
    metadata_temp = table();
    metadata_temp.sourceFile(1:length(frame),1) = string(filename);
    metadata_temp.Frame = frame;
    metadata_temp.Time = time;
    
    im_metadata{imidx,1} = metadata_temp;
end
%%
im_metadata = vertcat(im_metadata{:});