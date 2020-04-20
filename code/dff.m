function smoothTraces = dff(traces, tau, greenFile, saveSmoothTraces, outputPath)

    [T,~] = size(traces);
    Fbar = traces';
    for t = 1:T
       Fbar(:,t) = mean(Fbar(:,max(1,t-tau(1)/2):min(T,t+tau(1)/2)),2);
    end
    F0 = Fbar;
    for t =  1:T
       F0(:,t) = min(Fbar(:,max(1,t-tau(2)):t),[],2);
    end
    smoothTraces = (Fbar-F0)./F0;
    clear Fbar F0;

    smoothTraces= smoothTraces';

    [~, name, ~] = fileparts(greenFile);

    if saveSmoothTraces
        if ~exist(outputPath, 'dir')
            mkdir(outputPath);
        end
        save(fullfile(outputPath,[name,'_smoothTraces.mat']), 'smoothTraces', '-v6');
    end

end
