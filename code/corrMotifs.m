function [dff1, Ca] = corrMotifs(smoothTraces, greenFile, spikesFile, height, fps, saveCorr, outputPath)


    dff = smoothTraces';

    [m,T]=size(dff);
    load(spikesFile);
    dff1 = [];
    SD = [];
    Ca = {};
    ranges = {};

    for ii = 1:m
       x = dff(ii,:);
       %fps = fps1;
       x = interp1(1:T,x,1:fps/10:T);
       dff1(ii,:) = x;
       SD(ii) = std(x);
       parfor i=1:length(spikes)
           snippet = spikes{i};
           L = length(snippet);
           C = zeros(size(x));
           rng = zeros(size(x));
           for j=1:length(x)-(L-1)
               x_snippet = x(j:j+L-1);
               if(range(x_snippet)>height)
                   rng(j) = range(x_snippet);
                   R = corrcoef(x_snippet,snippet);
                   C(j) = R(1,2);

                   if j == length(x)-(L-1)
                       for j1 = length(x)-(L-2):length(x)-round(L/2)
                           x_snippet = x(j1:end);
                           R = corrcoef(x_snippet,snippet(1:length(x_snippet)));
                           C(j1) = R(1,2);
                           rng(j1) = range(x_snippet);
                       end
                   end
               end
            end
        Call(i,:) = C;
        RNG(i,:) = rng;
       end
       ranges{ii} = RNG;
       Ca{ii} = Call;
    end

    [~, name, ~] = fileparts(greenFile);
    if saveCorr
        if ~exist(outputPath, 'dir')
            mkdir(outputPath);
        end
        save(fullfile(outputPath, [name '_corrMotif.mat']), 'dff1', 'Ca', 'ranges', 'SD', '-v6');
    end

end
