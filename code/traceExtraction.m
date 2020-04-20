function traces = traceExtraction(greenFile, regSeries, mask, metric, q, saveTraces, outputPath)

    flatMask = mask(:);
    clear mask
    [y,x,t] = size(regSeries);
    traces = zeros(t, max(flatMask));
    inFrame = ones(t, max(flatMask));
    for ii = 1:t
        flatFrame = regSeries(:,:,ii);
        flatFrame = flatFrame(:);
        mn = min(flatFrame);
        for jj = 1:max(flatMask)
            idx = flatMask==jj & flatFrame>mn;
            if sum(idx)
                if strcmp(metric, 'mean')
                    traces(ii, jj) = mean(flatFrame(idx));
                elseif strcmp(metric, 'median')
                    traces(ii, jj) = median(flatFrame(idx));
                elseif strcmp(metric, 'quantile')
                    traces(ii, jj) = quantile(flatFrame(idx), q);
                end
            else
                inFrame(ii, jj) = 0;
            end
        end
    end

    [path, name, ext] = fileparts(greenFile);


    if saveTraces
        if ~exist(outputPath, 'dir')
            mkdir(outputPath)
        end
        save(fullfile(outputPath, [name '_traces.mat']), 'traces', 'inFrame', '-v6');
    end

end
