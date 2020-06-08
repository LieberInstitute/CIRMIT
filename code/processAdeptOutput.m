function events = processAdeptOutput(outputPath, greenFile, smoothTraces, ct, ht, dynamicThresh, fps, saveEvents)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    
    dff1 = [];
    SD = [];
    ranges = {};
    events = {};

    dff = smoothTraces';
    T = size(smoothTraces,1);
    nROI = size(smoothTraces, 2);
    [~, name, ~] = fileparts(greenFile);
    for ii = 1:nROI
        x = dff(ii,:);
        dff1(ii,:) = interp1(1:T,x,1:fps/10:T);
        fname = [name '_adept_trace', num2str(ii), '.csv'];
        tbl = readtable(fullfile(outputPath, fname));
        ev = tbl.tau_i';
        cor = tbl.sim_i';
        rng = tbl.rng';
        SD(ii) = tbl.SD(1);
        if dynamicThresh
            idx = cor > ct & rng > ht*SD(ii);
        else
            idx = cor > ct & rng > ht;
        end
        events{ii} = (ev(idx)-1)*2.5;
        ranges{ii} = rng(idx);
                
    end
    
    [~, name, ~] = fileparts(greenFile);
    
    if saveEvents
        if ~exist(outputPath, 'dir')
            mkdir(outputPath);
        end
        save(fullfile(outputPath, [name '_corrMotif.mat']), 'dff1', 'ranges', 'SD', '-v6');
        save(fullfile(outputPath, [name '_events.mat']), 'events', '-v6');
    end
    

end

