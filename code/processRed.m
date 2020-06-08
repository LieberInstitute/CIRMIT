function [im, MetaData] = processRed(redFile, saveMetaData, saveImage, outputPath)

    %addpath toolbox
    %addpath toolbox/bfmatlab
    
    out = ReadImage6D(redFile);
    
    im6d = out{1};
    im = squeeze(im6d);
    
    [~, name, ~] = fileparts(redFile);
    
    if saveImage
        if ~exist(outputPath, 'dir')
            mkdir(outputPath);
        end
        save(fullfile(outputPath, [name '.mat']), 'im', '-v6');
    end
    MetaData = out{2};
    if saveMetaData
        if ~exist(fullfile(outputPath, 'MetaData'), 'dir')
            mkdir(fullfile(outputPath, 'MetaData'));
        end
        save(fullfile(outputPath, 'MetaData', [name '_MetaData.mat']), 'MetaData', '-v6');
    end

end