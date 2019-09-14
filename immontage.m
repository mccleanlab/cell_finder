%% Select images
clearvars; close all; clc
imagelist = selectImages();
channellist = {'iRFP','mScarlet','mCitrine','DIC'};
channels2montage = {'mCitrine'};
numFrames = [];
numPositions = 3;
position = 3;
imScale = 0.5;
bgsubtract = 1;

%% Labels
genotypelist = {'pMM0697','A|4A|A','NES-|NLS+|DBD+','-LINuS';'pMM0698','A|4A|WT','NES-|NLS+|DBD WT','-LINuS';...
    'pMM0699','A|4WT|A','NES-|NLS WT|DBD+','-LINuS';'pMM0700','A|4WT|WT','NES-|NLS WT|DBD WT','-LINuS';...
    'pMM0701','A|4E|A','NES-|NLS-|DBD+','-LINuS';'pMM0702','A|4E|WT','NES-|NLS-|DBD WT','-LINuS';...
    'pMM0703','WT|4A|A','NES WT|NLS+|DBD+','-LINuS';'pMM0704','WT|4A|WT','NES WT|NLS+|DBD WT','-LINuS';...
    'pMM0705','WT|4WT|A','NES WT|NLS WT|DBD+','-LINuS';'pMM0706','WT|4WT|WT','NES WT|NLS WT|DBD WT','-LINuS';...
    'pMM0707','WT|4E|A','NES WT|NLS-|DBD+','-LINuS';'pMM0708','WT|4E|WT','NES WT|NLS-|DBD WT','-LINuS';...
    'pMM0709','E|4E|E','NES-|NLS-|DBD-','-LINuS';'pMM0710','A|4A|A','NES-|NLS+|DBD+','+LINuS';...
    'pMM0711','A|4A|WT','NES-|NLS+|DBD WT','+LINuS';'pMM0712','A|4WT|A','NES-|NLS WT|DBD+','+LINuS';...
    'pMM0713','A|4WT|WT','NES-|NLS WT|DBD WT','+LINuS';'pMM0714','A|4E|A','NES-|NLS-|DBD+','+LINuS';...
    'pMM0715','A|4E|WT','NES-|NLS-|DBD WT','+LINuS';'pMM0716','WT|4A|A','NES WT|NLS+|DBD+','+LINuS';...
    'pMM0717','WT|4A|WT','NES WT|NLS+|DBD WT','+LINuS';'pMM0718','WT|4WT|A','NES WT|NLS WT|DBD+','+LINuS';...
    'pMM0719','WT|4WT|WT','NES WT|NLS WT|DBD WT','+LINuS';'pMM0720','WT|4E|A','NES WT|NLS-|DBD+','+LINuS';...
    'pMM0721','WT|4E|WT','NES WT|NLS-|DBD WT','+LINuS';'pMM0722','E|4E|E','NES-|NLS-|DBD-','+LINuS';...
    'pMM0008','None','None','-LINuS'};

%% Load images
im = {};
for imidx = 1:numel(imagelist)
    images = [];
    [~, imname,~] = fileparts(imagelist{imidx});
    [images, ~, ~] = loadND(imagelist,imidx,channellist,numFrames,numPositions,[]);
    

    for cidx = 1:numel(channels2montage)
        imChannel =[];
        channel = channels2montage{cidx};
        imChannel = images.(channel)(:,:,:,position);
        
         % BG subtract
        if bgsubtract==1
            imChannel = imChannel - images.([channel '_mode'])(position);
        end
        
        imChannel = imresize(imChannel, imScale);
        cmax = intmax(class(imChannel));
        xy = size(imChannel);
        imChannel = imadjust(imChannel);
        imChannel = padarray(imChannel, [0 1], cmax/6);
        
        % Get label
        plasmid = regexp(imname,'yMM1454_pMM\d*_','match');
        plasmid = regexp(plasmid,'pMM\d*','match');
        gidx = contains(genotypelist(:,1),plasmid{:});
        genotype = genotypelist(gidx,2);
        label = strcat(imname,' (',genotype,')');
        textsize = 12;    
        
        % Add label and append channels (if applicable)
        imChannel = (insertText(imChannel,[0.01*xy(2) 0.9*xy(1)],channel,'FontSize',textsize,'TextColor','white', 'BoxColor','black','BoxOpacity',1));
        if cidx==1
            imChannel = (insertText(imChannel,[0.01*xy(2) 0.01*xy(1)],label,'FontSize',textsize,'TextColor','white', 'BoxColor','black','BoxOpacity',1));
            imChannelOut = rgb2gray(imChannel);
        else
            imChannelOut = [imChannelOut, rgb2gray(imChannel)];
        end
    end
    imChannelOut = padarray(imChannelOut, [3 3], 0.95*cmax);
    im{imidx} = imChannelOut;
end

clearvars -except im imagelist position channels2montage

%%
imOut = im;
% % xy = size(imOut{1});
% % blank = uint16(zeros(xy));
% % for idx = 43:48    
% %     imOut{idx} = blank;
% % end
imOut = reshape(imOut,10,9)';
imOut = cell2mat(imOut);
imOut = uint16(imOut);

imshow(imOut)
imNameOutStart = [imagelist{1}];
[~, imNameOutStart, ~] = fileparts(imNameOutStart);
imNameOutEnd = [imagelist{1}];
[~, imNameOutEnd, ~] = fileparts(imNameOutEnd);
channelNamesOut =  join(channels2montage);
channelNamesOut = strrep(channelNamesOut,' ','_');
imwrite(imOut,[imNameOutStart '-' imNameOutEnd '_' channelNamesOut{:} '_position_' num2str(position) '.tif'])

