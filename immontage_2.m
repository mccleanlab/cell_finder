%% Select images
clearvars; close all; clc
imagelist = selectImages();
channellist = {'iRFP','mScarlet','mCitrine','DIC'};
channels2montage = {'mScarlet','mCitrine'};
nf = [];
numPositions = 3;
position = 3;
imScale = 0.5;
bgsubtract = 1;
%% Load images
images = struct();
for imidx = 1:numel(imagelist)
    [~, imname,~] = fileparts(imagelist{imidx});
    [im, ~, ~] = loadND(imagelist,imidx,channellist,nf,numPositions,[]);
    images.(imname) = im;
end

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
imMontage = {};
nimages = length(fieldnames(images));

for imidx = 1:nimages
    imname0 = fieldnames(images);
    imname0 = imname0{imidx};
    im0 = images.(imname0);
    
    % Get label
    plasmid = regexp(imname0,'yMM1454_pMM\d*_','match');
    plasmid = regexp(plasmid,'pMM\d*','match');
    gidx = contains(genotypelist(:,1),plasmid{:});
    genotype = genotypelist(gidx,2);
    label = strcat(imname0,' (',genotype,')');
    textsize = 12;
    
    for cidx = 1:numel(channels2montage)
        channel = channels2montage{cidx};
        im00 =[];
        nf = size(im0,3);
        for frame = 1:nf
            im000 = im0.(channel)(:,:,frame,position);
            %             % BG subtract
            %             if bgsubtract==1
            %                 bg = im0.([channel '_mode'])(frame,position);
            %                 im000 = im000 - bg;
            %             end
            %
            %             im000 = imresize(im000, imScale);
            %             cmax = intmax(class(im000));
            %             xy = size(im000);
            %             im000 = imadjust(im000);
            %             im000 = padarray(im000, [0 1], cmax/6);
            %
            %             if f==1
            %                 im00 = im000;
            %             else
            %                 im00 = [im00, im000];
            %             end
        end
        
        %
        %         % Add label and append channels (if applicable)
        %         im00 = (insertText(im00,[0.01*xy(2) 0.9*xy(1)],channel,'FontSize',textsize,'TextColor','white', 'BoxColor','black','BoxOpacity',1));
        %
        %         if cidx==1
        %             im00 = (insertText(im00,[0.01*xy(2) 0.01*xy(1)],label,'FontSize',textsize,'TextColor','white', 'BoxColor','black','BoxOpacity',1));
        %             im00 = rgb2gray(im00);
        %             imChannelOut = im00;
        %         else
        %             im00 = rgb2gray(im00);
        %             im00 = [imChannelOut; im00];
        %         end
        %
    end
    %     imChannelOut = padarray(imChannelOut, [3 3], 0.95*cmax);
    %     imMontage{imidx} = imChannelOut;
end

%
% clearvars -except im imagelist position channels2montage

%%
imOut = imMontage;
% % % xy = size(imOut{1});
% % % blank = uint16(zeros(xy));
% % % for idx = 43:48
% % %     imOut{idx} = blank;
% % % end
% imOut = reshape(imOut,10,9)';
imOut = cell2mat(imOut);
imOut = uint16(imOut);
%
imshow(imOut)
% imNameOutStart = [imagelist{1}];
% [~, imNameOutStart, ~] = fileparts(imNameOutStart);
% imNameOutEnd = [imagelist{1}];
% [~, imNameOutEnd, ~] = fileparts(imNameOutEnd);
% channelNamesOut =  join(channels2montage);
% channelNamesOut = strrep(channelNamesOut,' ','_');
% imwrite(imOut,[imNameOutStart '-' imNameOutEnd '_' channelNamesOut{:} '_position_' num2str(position) '.tif'])
%
