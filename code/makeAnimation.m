 function [p, corrs] = makeAnimation(smoothTraces, im, mask, ROI_info, series, greenFile, events, roiArray, jump, fps)

    figure('Name', [greenFile ' Animation'], 'WindowState', 'maximized');
    %logSeries = log(double(series));
    timePts = size(smoothTraces, 1);
    corrs = ones(size(smoothTraces,2),size(smoothTraces,2),timePts);
    for tt = 2:timePts
        corrs(:,:,tt) = corrcoef(smoothTraces(1:tt,:));
    end
    ROIs = max(mask(:));
    bb = ROI_info.BoundingBox;
    seriesCell = cell(ROIs, 1);
    r = cell(ROIs, 1);
    c = cell(ROIs, 1);
    se = strel('disk',1,0);
    mask2 = imdilate(mask, se);
    for ii = 1:ROIs
        up = max(floor(bb(ii,2))-5, 1);
        down = min(ceil(bb(ii,2))+bb(ii,4)+5, size(im, 1));
        left = max(floor(bb(ii,1))-5, 1);
        right = min(ceil(bb(ii,1))+bb(ii,3)+5, size(im, 2));
        seriesCell{ii} = series(up:down,left:right,:);
        j = bwperim(mask2(up:down,left:right));
        [r{ii},c{ii}] = find(j);
    end

    p = createSubplots(smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, 1, jump, greenFile, fps, r, c, false, false);

end

function p = createSubplots(smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, showSeries, manualEvents)

    mn = min(series(:));
    mx = max(series(:));
    ROIs = max(mask(:));
    timePts = size(smoothTraces, 1);
    maskPos = [0.05 0.07 0.27 0.18];
    logPos = [0.36 0.07 0.27 0.18];
    corrPos = [0.67 0.07 0.27 0.18];
    colors = hsv(ROIs);
    se = strel('disk',1,0);
    ymin = -0.1;
    ymax = 1.2*max(smoothTraces(:));
    mask2 = imdilate(mask, se);
    showSeriesBox = uicontrol('Style', 'checkbox', 'String', 'Show Full Green Series', 'units', 'normalized', 'position', [0.45 0.01 0.12 0.02]);
    uipanel('units', 'normalized', 'position', [0.585 0.005 0.28 0.045], 'Title', 'Event Manipulation');
    manualCheck = uicontrol('Style', 'checkbox', 'String', 'Manually Select Events', 'units', 'normalized', 'position', [0.59 0.01 0.12 0.02]);
    set(manualCheck, 'Value', manualEvents);
    clearButton = uicontrol('Style', 'push', 'String', 'Clear Events', 'units', 'normalized', 'position', [0.69 0.01 0.08 0.02]);
    saveButton = uicontrol('Style', 'push', 'String', 'Save Events', 'units', 'normalized', 'position', [0.78 0.01 0.08 0.02]);
    uipanel('units', 'normalized', 'position', [0.225 0.005 0.15 0.045], 'Title', 'Frame Increment');
    jumpDialog = uicontrol('Style', 'edit', 'units', 'normalized', 'position', [0.27 0.01 0.06 0.02], 'String', jump);
    clearButton.Callback = {@clearEvents, smoothTraces, im, mask, series, seriesCell, roiArray, corrs, t, jumpDialog, greenFile, fps, r, c, showSeriesBox, manualCheck};
    saveButton.Callback = {@saveEvents, events, greenFile};
    for ii = 1:length(roiArray)
        jj = roiArray(ii);
        pltPos = [0.05, 1.03-ii/5.5, 0.75, 0.13];
        imgPos = [0.84, 1.03-ii/5.5, 0.14, 0.13];
        subplot('Position', pltPos);
        p(ii)=plot((t-1)/fps, smoothTraces(t,jj), 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors(jj,:), 'MarkerSize', 10);
        hold on;
        for ev = 1:length(events{jj})
           plot([(events{jj}(ev)-1)/10 (events{jj}(ev)-1)/10], [ymin ymax], '-r', 'LineWidth', 2);
        end
        l = plot((0:timePts-1)/fps, smoothTraces(:,jj), '-b', 'ButtonDownFcn', {@clickPlot, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jumpDialog, greenFile, fps, r, c, showSeriesBox, manualCheck, p});
        ylabel(["ROI: " num2str(jj)]);
        set(l, 'tag', num2str(jj));
        hold off; ylim([ymin ymax]); xlim([-2 max((timePts-1)/fps)+2]);
        subplot('Position', imgPos); h(ii+3) = imagesc(seriesCell{jj}(:,:,t),[mn mx]); colormap gray; hold on; plot(c{jj},r{jj},'r.','MarkerSize',10); hold off; axis off;
    end
    ax1 = subplot('Position', maskPos); h(1) = imagesc(label2rgb(mask2, 'hsv', 'k'), 'ButtonDownFcn', {@clickMask, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jumpDialog, greenFile, fps, r, c, showSeriesBox, manualCheck}); axis off; cellLabels(mask);
    if showSeries
        ax2 = subplot('Position', logPos); h(2) = imagesc(series(:,:,t), [mn mx]); axis off;
    else
        ax2 = subplot('Position', logPos); h(2) = imagesc(im); axis off;
    end
    set(h(2), 'ButtonDownFcn', {@clickMask, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jumpDialog, greenFile, fps, r, c, showSeriesBox, manualCheck});
    linkaxes([ax1 ax2]);
    if t == 1
        subplot('Position', corrPos); h(3)=heatmap(roiArray, roiArray, corrs(roiArray,roiArray,end)); colormap(h(3),cool); caxis([-1 1]);
    else
        subplot('Position', corrPos); h(3)=heatmap(roiArray, roiArray, corrs(roiArray,roiArray,t)); colormap(h(3),cool); caxis([-1 1]);
    end
    ii = length(roiArray);
    pltPos = [0.05, 1.03-ii/5.5, 0.75, 0.13];
    subplot('Position', pltPos); xlabel('Time (seconds)');
    playButton = uicontrol('Style', 'push', 'units', 'normalized', 'position', [0.05 0.01 0.08 0.02], 'String', 'Play');
    recordButton = uicontrol('Style', 'push', 'units', 'normalized', 'position', [0.14 0.01 0.08 0.02], 'String', 'Record');
    jumpDown = uicontrol('Style', 'push', 'units', 'normalized', 'position', [0.23 0.01 0.03 0.02], 'String', '-');
    jumpUp = uicontrol('Style', 'push', 'units', 'normalized', 'position', [0.34 0.01 0.03 0.02], 'String', '+');
    resetButton = uicontrol('Style', 'push', 'units', 'normalized', 'position', [0.9 0.01 0.08 0.02], 'String', 'Go To Start');
    jumpDialog.Callback = {@changeJump, jumpDown, jumpUp, timePts, jump};
    jumpDown.Callback = {@jumpDownFcn, jumpUp, jumpDialog, timePts};
    jumpUp.Callback = {@jumpUpFcn, jumpDown, jumpDialog, timePts};
    if jump==1
        set(jumpDown, 'Enable', 'off');
    elseif jump==timePts
        set(jumpUp, 'Enable', 'off');
    else
        set(jumpDown, 'Enable', 'on');
        set(jumpUp, 'Enable', 'on');
    end
    recordButton.Callback = {@recordVideo, smoothTraces, series, seriesCell, roiArray, corrs, p, fps, playButton, jumpDown, jumpUp, jumpDialog, showSeriesBox, resetButton, h, manualCheck, greenFile, clearButton, saveButton};
    playButton.Callback = {@playAnimation, smoothTraces, series, seriesCell, roiArray, corrs, p, t, fps, recordButton, jumpDown, jumpUp, jumpDialog, showSeriesBox, resetButton, h, manualCheck,clearButton, saveButton};
    set(showSeriesBox, 'Value', showSeries);
    showSeriesBox.Callback = {@showSeriesCheck, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, h, manualCheck};
    resetButton.Callback = {@goToStart, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, jumpDialog, greenFile, fps, r, c, showSeriesBox, manualCheck};


end

function clickMask(~, Event, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jumpDialog, greenFile, fps, r, c, showSeriesBox, manualCheck)

    showSeries = get(showSeriesBox, 'Value');
    manualEvents = get(manualCheck, 'Value');
    jump = str2double(get(jumpDialog, 'String'));
    X = floor(Event.IntersectionPoint(1));
    Y = floor(Event.IntersectionPoint(2));
    se = strel('disk', 5);
    mask2 = imdilate(mask, se);
    roiIdx = mask2(Y,X);
    if roiIdx ~= 0
        if ismember(roiIdx, roiArray)
            roiArray = roiArray(~ismember(roiArray, roiIdx));
        else
            endPt = min(3, length(roiArray));
            roiArray = [roiIdx roiArray(1:endPt)];
        end
        clf;
        createSubplots(smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, showSeries, manualEvents);
    end

end

function clickPlot(~, Event, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jumpDialog, greenFile, fps, r, c, showSeriesBox, manualCheck, p)

    showSeries = get(showSeriesBox, 'Value');
    manualEvents = get(manualCheck, 'Value');
    jump = str2double(get(jumpDialog, 'String'));
    if manualEvents
        t = floor(get(p(1), 'XData')*fps+1);
        roi = str2double(get(Event.Source, 'tag'));
        X = Event.IntersectionPoint(1);
        e = floor(X*10+1);
        E = events{roi};
        keep = true(size(E));
        for i = 1:length(E)
            if abs(E(i)-e) < 20
                keep(i) = false;
            end
        end
        if sum(keep) < length(keep)
            events{roi} = E(keep);
            createSubplots(smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, showSeries, manualEvents);
        else
            events{roi} = sort([E e]);
            createSubplots(smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, showSeries, manualEvents);
        end
    else
        X = Event.IntersectionPoint(1);
        t = floor(X*fps+1);
        createSubplots(smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, showSeries, manualEvents);
    end
end

function recordVideo(hButton, ~, smoothTraces, series, seriesCell, roiArray, corrs, p, fps, playButton, jumpDown, jumpUp, jumpDialog, showSeriesBox, resetButton, h, manualCheck, greenFile, clearButton, saveButton)

    com.mathworks.mwswing.MJFileChooserPerPlatform.setUseSwingDialog(1)
    setAvi = '*.avi';
    if getenv('HOMEPATH')
        homepath = getenv('HOMEPATH');
    elseif getenv('HOME')
        homepath = getenv('HOME');
    end
    if ~exist(fullfile(homepath, 'CIRMIT_paths'), 'dir')
        mkdir(fullfile(homepath, 'CIRMIT_paths'));
    end
    pathinfo = '';
    if exist(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths3.txt'), 'file')
        try
            pathinfo = fileread(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths3.txt')); 
            
        catch
        end
    end
    [~, greenName, ~] = fileparts(greenFile);
    ridx = strfind(greenName, 'registered');
    if ridx
        greenName = greenName(1:ridx-2);
    end
    setAvi = fullfile(pathinfo, [greenName '.avi']);
    [vidFile, vidPath] = uiputfile(setAvi);
    [~, ~, vidExt] = fileparts(vidFile);
    if ischar(vidPath) & strcmp(vidExt, '.avi')
        vp = strrep(vidPath, '\', '/');
        fid = fopen(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths3.txt'), 'w');
        fprintf(fid, vp);
        fclose(fid);
        clear vp
        set(hButton, 'Enable', 'off');
        set(playButton, 'Enable', 'off');
        set(jumpDown, 'Enable', 'off');
        set(jumpUp, 'Enable', 'off');
        set(jumpDialog, 'Enable', 'off');
        set(showSeriesBox, 'Enable', 'off');
        set(resetButton, 'Enable', 'off');
        set(manualCheck, 'Enable', 'off');
        set(clearButton, 'Enable', 'off');
        set(saveButton, 'Enable', 'off');
        jump = str2double(get(jumpDialog, 'String'));
        showSeries = get(showSeriesBox, 'Value');
        timePts = size(smoothTraces, 1);
        v = VideoWriter(fullfile(vidPath, vidFile));
        open(v);
        for tt = 1:jump:timePts
            for ii = 1:length(roiArray)
                jj = roiArray(ii);
                p(ii).XData = (tt-1)/fps; p(ii).YData = smoothTraces(tt,jj);
                set(h(ii+3), 'CData', seriesCell{jj}(:,:,tt));
            end
            set(h(3), 'ColorData', corrs(roiArray,roiArray,tt));
            if showSeries
                set(h(2), 'CData', series(:,:,tt));
            end
            drawnow
            frame = getframe(gcf);
            writeVideo(v, frame);
        end
        close(v);
        set(hButton, 'Enable', 'on');
        set(playButton, 'Enable', 'on');
        set(jumpDown, 'Enable', 'on');
        set(jumpUp, 'Enable', 'on');
        set(jumpDialog, 'Enable', 'on');
        set(showSeriesBox, 'Enable', 'on');
        set(resetButton, 'Enable', 'on');
        set(manualCheck, 'Enable', 'on');
        set(clearButton, 'Enable', 'on');
        set(saveButton, 'Enable', 'on');
    else
        errordlg('Please create a filename in the .AVI format');
    end

end

function playAnimation(hButton, ~, smoothTraces, series, seriesCell, roiArray, corrs, p, t, fps, recordButton, jumpDown, jumpUp, jumpDialog, showSeriesBox, resetButton, h, manualCheck, clearButton, saveButton)

    if strcmp(hButton.String, 'Play')
        if get(hButton, 'UserData')
            t = get(hButton, 'UserData');
        end
        hButton.String = 'Stop';
        set(recordButton, 'Enable', 'off');
        set(jumpDown, 'Enable', 'off');
        set(jumpUp, 'Enable', 'off');
        set(jumpDialog, 'Enable', 'off');
        set(showSeriesBox, 'Enable', 'off');
        set(resetButton, 'Enable', 'off');
        set(manualCheck, 'Enable', 'off');
        set(clearButton, 'Enable', 'off');
        set(saveButton, 'Enable', 'off');
        jump = str2double(get(jumpDialog, 'String'));
        showSeries = get(showSeriesBox, 'Value');
        timePts = size(smoothTraces, 1);
        set(hButton, 'UserData', false);
        for tt = t:jump:timePts
            if get(hButton, 'UserData')
                set(hButton, 'UserData', tt);
                break
            end
            for ii = 1:length(roiArray)
                jj = roiArray(ii);
                p(ii).XData = (tt-1)/fps; p(ii).YData = smoothTraces(tt,jj);
                set(h(ii+3), 'CData', seriesCell{jj}(:,:,tt));
            end
            set(h(3), 'ColorData', corrs(roiArray,roiArray,tt));
            if showSeries
                set(h(2), 'CData', series(:,:,tt));
            end
            drawnow
        end
        set(recordButton, 'Enable', 'on');
        set(jumpDown, 'Enable', 'on');
        set(jumpUp, 'Enable', 'on');
        set(jumpDialog, 'Enable', 'on');
        set(showSeriesBox, 'Enable', 'on');
        set(resetButton, 'Enable', 'on');
        set(manualCheck, 'Enable', 'on');
        set(clearButton, 'Enable', 'on');
        set(saveButton, 'Enable', 'on');
    else
        hButton.String = 'Play';
        set(hButton, 'UserData', true);
        set(recordButton, 'Enable', 'on');
        set(jumpDown, 'Enable', 'on');
        set(jumpUp, 'Enable', 'on');
        set(jumpDialog, 'Enable', 'on');
        set(showSeriesBox, 'Enable', 'on');
        set(resetButton, 'Enable', 'on');
        set(manualCheck, 'Enable', 'on');
        set(clearButton, 'Enable', 'on');
        set(saveButton, 'Enable', 'on');
    end

end

function changeJump(hDialog, ~, jumpDown, jumpUp, timePts, prevJump)

    jump = str2double(get(hDialog, 'String'));
    if mod(jump, 1)~=0 || jump < 1 || jump>timePts
        errordlg(['Frame Increment must be integer between 1 and ' num2str(timePts)]);
        jump = prevJump;
    end
    set(hDialog, 'String', jump);
    if jump==1
        set(jumpDown, 'Enable', 'off');
    elseif jump==timePts
        set(jumpUp, 'Enable', 'off');
    else
        set(jumpDown, 'Enable', 'on');
        set(jumpUp, 'Enable', 'on');
    end

end

function jumpDownFcn(jumpDown, ~, jumpUp, jumpDialog, timePts)

    jump = str2double(get(jumpDialog, 'String'))-1;
    set(jumpDialog, 'String', jump);
    if jump==1
        set(jumpDown, 'Enable', 'off');
    elseif jump==timePts
        set(jumpUp, 'Enable', 'off');
    else
        set(jumpDown, 'Enable', 'on');
        set(jumpUp, 'Enable', 'on');
    end
end

function jumpUpFcn(jumpUp, ~, jumpDown, jumpDialog, timePts)

    jump = str2double(get(jumpDialog, 'String'))+1;
    set(jumpDialog, 'String', jump);
    if jump==1
        set(jumpDown, 'Enable', 'off');
    elseif jump==timePts
        set(jumpUp, 'Enable', 'off');
    else
        set(jumpDown, 'Enable', 'on');
        set(jumpUp, 'Enable', 'on');
    end

end

function showSeriesCheck(hObj, ~, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, h, manualCheck)

    manualEvents = get(manualCheck, 'Value');
    if get(hObj, 'Value') == 1
        set(h(2), 'CData', series(:,:,t), 'ButtonDownFcn', {@clickMask, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, hObj, manualEvents});
    else
        set(h(2), 'CData', im, 'ButtonDownFcn', {@clickMask, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, hObj, manualEvents});
    end

end

function goToStart(~, ~, smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, jumpDialog, greenFile, fps, r, c, showSeriesBox, manualCheck)

    manualEvents = get(manualCheck, 'Value');
    showSeries = get(showSeriesBox, 'Value');
    jump = str2double(get(jumpDialog, 'String'));
    createSubplots(smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, 1, jump, greenFile, fps, r, c, showSeries, manualEvents);

end

function clearEvents(~, ~, smoothTraces, im, mask, series, seriesCell, roiArray, corrs, t, jumpDialog, greenFile, fps, r, c, showSeriesBox, manualCheck)

    a = questdlg('Are you sure you want to clear events? You will have to reload the figure to restore these events to the plot.', ...
        'Clear Events',...
        'Yes', 'No', 'No');
    if strcmp(a, 'Yes')
        numROI = size(smoothTraces, 2);
        events = cell(1, numROI);
        manualEvents = get(manualCheck, 'Value');
        showSeries = get(showSeriesBox, 'Value');
        jump = str2double(get(jumpDialog, 'String'));
        createSubplots(smoothTraces, im, mask, series, seriesCell, events, roiArray, corrs, t, jump, greenFile, fps, r, c, showSeries, manualEvents);
    end

end

function saveEvents(~, ~, events, greenFile)

    com.mathworks.mwswing.MJFileChooserPerPlatform.setUseSwingDialog(1)
    setMat = '*.mat';
    if getenv('HOMEPATH')
        homepath = getenv('HOMEPATH');
    elseif getenv('HOME')
        homepath = getenv('HOME');
    end
    if ~exist(fullfile(homepath, 'CIRMIT_paths'), 'dir')
        mkdir(fullfile(homepath, 'CIRMIT_paths'));
    end
    [~, greenName, ~] = fileparts(greenFile);
    ridx = strfind(greenName, 'registered');
    if ridx
        greenName = greenName(1:ridx-2);
    end
    if exist(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths4.txt'), 'file')
        try
            pathinfo = fileread(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths4.txt'));
            setMat = fullfile(pathinfo, [greenName '_events.mat']);
        catch
        end
    end
    [matFile, matPath] = uiputfile(setMat);
    [~, ~, matExt] = fileparts(matFile);
    if ischar(matPath) & strcmp(matExt, '.mat')
        mp = strrep(matPath, '\', '/');
        fid = fopen(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths4.txt'), 'w');
        fprintf(fid, mp);
        fclose(fid);
        clear mp
        save(fullfile(matPath, matFile), 'events', '-v6');
    end

end
