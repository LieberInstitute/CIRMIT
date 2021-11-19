function [series, x, y, t, MetaData] = processGreen(greenFile, saveMetaData, saveSeries, outputPath, writeTiff)

    %addpath(genpath('toolbox'))
    out = ReadImage6D(greenFile);
    
    im6d = out{1};
    MetaData = out{2};
    if (MetaData.SizeC > 1)
        errordlg("The Green CZI has more than one color channel.", "Error");
    end
    series = uint16(squeeze(im6d));
    series = permute(series, [2 3 1]);
    [y, x, t] = size(series);
    
    [~, name, ~] = fileparts(greenFile);
    
    if saveSeries
        if ~exist(outputPath, 'dir')
            mkdir(outputPath);
        end
        save(fullfile(outputPath, [name '.mat']), 'series', '-v7.3');
    end
    
    data = bfopen(greenFile);
    omeMeta = data{1, 4};
    %fps = 1/double(omeMeta.getPixelsTimeIncrement(0).value());
    %MetaData.FPS = fps;
    MetaData.FPS = 4;
    if saveMetaData
        if ~exist(fullfile(outputPath, 'MetaData'), 'dir')
            mkdir(fullfile(outputPath, 'MetaData'));
        end
        save(fullfile(outputPath, 'MetaData', [name '_MetaData.mat']), 'MetaData', '-v6');
    end
    
    if writeTiff
        if ~exist(fullfile(outputPath, 'TIFF'), 'dir')
            mkdir(fullfile(outputPath, 'TIFF'));
        end
        bar = waitbar(0/size(series, 3), 'Writing Green Series TIFF', 'Name', 'Processing Green');
        for ii = 1:size(series, 3)
            waitbar(ii/size(series, 3), bar, 'Writing Green Series TIFF', 'Name', 'Processing Green');
            imwrite(squeeze(series(:,:,ii)), fullfile(outputPath, 'TIFF', [name '.tiff']), 'WriteMode', 'append', 'Compression', 'none');
        end
        close(bar);
    end

end