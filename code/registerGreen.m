function regSeries = registerGreen(greenFile, tiffFile, x, y, t, im, saveTranslationMatrices, saveRegistered, writeTiff, outputPath)

    [optimizer, metric] = imregconfig('monomodal');
    regcorr = zeros(3,3,t);
    regcorr(:,:,1) = eye(3);
    parfor ii = 2:t
        lastFrame = imread(tiffFile, 'Index', ii-1);
        nextFrame = imread(tiffFile, 'Index', ii);
        tform = imregtform(nextFrame, lastFrame, 'translation', optimizer, metric);
        regcorr(:,:,ii) = tform.T;
    end
    regSeries = zeros(y, x, t);
    regSeries(:,:,1) = imread(tiffFile, 'Index', 1);
    rfixed = imref2d([y x]);
    regcorr_composed = regcorr;
    for ii = 2:t
        regcorr_composed(:,:,ii) = regcorr_composed(:,:,ii-1)*regcorr(:,:,ii);
    end
    parfor ii = 2:t
        frame = imread(tiffFile, 'Index', ii);
        mn = min(frame(:));
        tform = affine2d(regcorr_composed(:,:,ii));
        frame = imwarp(frame, tform, 'OutputView', rfixed);
        frame(frame<mn) = mn-1;
        regSeries(:,:,ii) = frame;
    end
    seriesMed = median(regSeries, 3);
    [optimizer, metric] = imregconfig('multimodal');
    tform = imregtform(seriesMed, im, 'translation', optimizer, metric);
    parfor ii = 1:t
        frame = regSeries(:,:,ii);
        mn = min(frame(:));
        frame = imwarp(regSeries(:,:,ii), tform, 'OutputView', rfixed);
        frame(frame<mn) = mn-1;
        regSeries(:,:,ii) = frame;
    end
    regSeries = uint16(regSeries);
    [~, name, ~] = fileparts(greenFile);
    if saveRegistered
        if ~exist(outputPath, 'dir')
            mkdir(outputPath);
        end
        save(fullfile(outputPath, [name '_registered.mat']), 'regSeries', '-v7.3');
    end
    if saveTranslationMatrices
        if ~exist(fullfile(outputPath, 'TranslationMatrices'), 'dir')
            mkdir(fullfile(outputPath, 'TranslationMatrices'));
        end
        GreenReg = regcorr;
        RedReg = tform.T;
        save(fullfile(outputPath, 'TranslationMatrices', [name '_TranslationMatrices.mat']), 'GreenReg', 'RedReg', '-v6');
    end
    if writeTiff
        if ~exist(fullfile(outputPath, 'TIFF'), 'dir')
            mkdir(fullfile(outputPath, 'TIFF'));
        end
        bar = waitbar(0/size(regSeries, 3), 'Writing Registered Green Series TIFF', 'Name', 'Processing Green');
        for ii = 1:size(regSeries, 3)
            waitbar(ii/size(regSeries, 3), bar, 'Writing Registered Green Series TIFF', 'Name', 'Processing Green');
            imwrite(squeeze(regSeries(:,:,ii)), fullfile(outputPath, 'TIFF', [name '_registered.tiff']), 'WriteMode', 'append', 'Compression', 'none');
        end
        close(bar);
    end

end
