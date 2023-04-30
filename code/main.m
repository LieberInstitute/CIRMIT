function main()

    % Create the main CIRMIT figure 
    fig = uifigure('Name', 'CIRMIT', 'position', [360 198 460 650]);
    % Panel for processing images and extracting data
    uipanel(fig, 'position', [15 135 435 500], 'Title', 'Process images');
    % Sub panel for selecting ROIs from red channel
    uipanel(fig, 'position', [20 520 425 90], 'Title', 'Red channel segmentation');
    % Field for red channel segmentation method
    uilabel(fig, 'position', [25 560 150 20], 'Text', 'Select thresholding method');
    threshMethod = uidropdown(fig, 'position', [195 560 125 20], 'Items',...
        {'Median transform', 'Region growing', 'Manual'}, 'Value', 'Median transform');
    % Field for standard deviation based threshold for red channel
    % segmentation
    threshLab = uilabel(fig, 'position', [325 560 100 20], 'Text', 'SD Threshold');
    sdThresh = uieditfield(fig, 'numeric', 'position', [405 560 30 20],...
        'Value', 5, 'Limits', [0 Inf], 'LowerLimitInclusive', 'off');
    % Field to select refinement method of ROIs
    refineLab = uilabel(fig, 'position', [25 530 150 20], 'Text', 'Select refinement method');
    refineMethod = uidropdown(fig, 'position', [195 530 125 20], 'Items',...
        {'Eccentricity', 'Circle finding'}, 'Value', 'Eccentricity');
    % Function for toggling available options when switching between
    % manual and other methods of image segmentation
    threshMethod.ValueChangedFcn = {@changeThreshMethod, refineMethod, sdThresh, threshLab, refineLab};
    % Sub panel for registering green series to red channel
    uipanel(fig, 'position', [20 465 425 50], 'Title', 'Registration');
    % Checkbox indicating whether registration should be performed
    registerCheck = uicheckbox(fig, 'position', [30 470 200 20], 'Text', 'Register Green Series', 'Value', 1);
    % Sub panel for trace statistic extraction
    uipanel(fig, 'position', [20 370 425 90], 'Title', 'Trace extraction');
    % Field to select trace statistic 
    uilabel(fig, 'position', [25 410 150 20], 'Text', 'Select trace statistic');
    traceStat = uidropdown(fig, 'position', [195 410 125 20], 'Items',...
        {'Mean', 'Quantile'}, 'Value', 'Mean');
    quantBox = uieditfield(fig, 'numeric', 'position', [340 410 50 20],...
        'Value', 0.5, 'Limits', [0 1], 'Enable', 'Off');
    % Checkbox to indicate whether DFF transformation should be applied
    dffCheck = uicheckbox(fig, 'position', [30 380 200 20], 'Text', 'Apply DFF Smoothing', 'Value', 1);
    % Function that enables quantBox only when quantile trace statistic is
    % selected
    traceStat.ValueChangedFcn = {@changeTraceStat, quantBox};
    % Sub panel for event detection
    uipanel(fig, 'position', [20 225 425 140], 'Title', 'Event Detection');
    % Checkbox indicating if you want to identify events
    eventCheck = uicheckbox(fig, 'position', [25 320 200 20], 'Text', 'Identify Events', 'Value', 1);
    % Correlation threshold for event detection
    ctLab = uilabel(fig, 'position', [25 265 170 20], 'Text', 'Correlation threshold');
    ctBox = uieditfield(fig, 'numeric', 'position', [200 265 100 20],...
        'Value', 0.9, 'Limits', [0 1]);
    % Height threshold for event detection
    htLab = uilabel(fig, 'position', [25 235 170 20], 'Text', 'Height threshold');
    htBox = uieditfield(fig, 'numeric', 'position', [200 235 100 20],...
        'Value', 0.2, 'Limits', [0 Inf]);
    % Checkbox indicating if height threshold should be static or a
    % multiple of each trace's standard deviation
    dynamicCheck = uicheckbox(fig, 'position', [305 235 150 20], 'Text', 'Dynamic (times SD)', 'Value', 0);
    % Function that disables event detection settings when no event
    % detection is selected
    eventCheck.ValueChangedFcn = {@toggleEvents, ctBox, htBox, dynamicCheck,...
        ctLab, htLab};
    % Sub panel for other options
    uipanel(fig, 'position', [20 170 425 50], 'Title', 'Other Options');
    % Checkbox if images should be displayed by log transform
    logCheck = uicheckbox(fig, 'position', [25 175 200 20], 'Text', 'Display Log Transform', 'Value', 1);
    % Checkbox if image processing output should be saved as MAT files
    saveCheck = uicheckbox(fig, 'position', [250 175 200 20], 'Text', 'Save all data as MATs', 'Value', 1);
    % Button to launch from processing images
    processCZI = uibutton(fig, 'push', 'position', [240 140 200 20], 'Text', 'Process New Images');
    
    % Panel for launching visualization tool from already processed data
    uipanel(fig, 'position', [15 10 435 116], 'Title', 'Launch from previously processed data');
    % Button to launch visualization
    launchFromMAT = uibutton(fig, 'push', 'position', [240 15 200 20], 'Text', 'Launch Visualization from MATs');
    % Checkbox to indicate if events should be displayed 
    eventCheck2 = uicheckbox(fig, 'position', [25 60 200 20], 'Text', 'Display Events', 'Value', 1);
    % Checkbox if images should be displayed by log transform
    logCheck2 = uicheckbox(fig, 'position', [25 80 200 20], 'Text', 'Display Log Transform', 'Value', 1);
    % Checkbox if MATs to be used have been registered
    registerCheck2 = uicheckbox(fig, 'position', [25 40 200 20], 'Text', 'Images were registered', 'Value', 1);
    % Checkbox if trace statistic MATs have had DFF transform applied
    dffCheck2 = uicheckbox(fig, 'position', [25 20 200 20], 'Text', 'DFF smoothing was applied', 'Value', 1);
    
    % Button functions to run
    processCZI.ButtonPushedFcn = {@startProcess, fig, threshMethod, sdThresh, refineMethod, registerCheck,...
        traceStat, quantBox, dffCheck, eventCheck, ctBox, htBox, dynamicCheck, logCheck, saveCheck};
    launchFromMAT.ButtonPushedFcn = {@loadAndLaunch, fig, eventCheck2, logCheck2, registerCheck2, dffCheck2};

end

function changeThreshMethod(threshMethod, ~, refineMethod, sdThresh, threshLab, refineLab)

    if strcmp(threshMethod.Value, 'Manual')
        set(refineMethod, 'Enable', 'off');
        set(sdThresh, 'Enable', 'off');
        set(threshLab, 'Enable', 'off');
        set(refineLab, 'Enable', 'off');
    else
        set(refineMethod, 'Enable', 'on');
        set(sdThresh, 'Enable', 'on');
        set(threshLab, 'Enable', 'on');
        set(refineLab, 'Enable', 'on');
    end

end

function changeTraceStat(traceStat, ~, quantBox)

    if strcmp(traceStat.Value, 'Quantile')
        set(quantBox, 'Enable', 'on');
    else
        set(quantBox, 'Enable', 'off');
    end

end

function toggleEvents(eventCheck, ~, ctBox, htBox, dynamicCheck, ctLab, htLab)

    if eventCheck.Value
        set(ctBox, 'Enable', 'on');
        set(htBox, 'Enable', 'on');
        set(dynamicCheck, 'Enable', 'on');
        set(ctLab, 'Enable', 'on');
        set(htLab, 'Enable', 'on');
    else
        set(ctBox, 'Enable', 'off');
        set(htBox, 'Enable', 'off');
        set(dynamicCheck, 'Enable', 'off');
        set(ctLab, 'Enable', 'off');
        set(htLab, 'Enable', 'off');
    end

end

function startProcess(~, ~, fig, threshMethod, sdThresh, refineMethod, registerCheck,...
        traceStat, quantBox, dffCheck, eventCheck, ctBox, htBox, dynamicCheck, logCheck, saveCheck)

    com.mathworks.mwswing.MJFileChooserPerPlatform.setUseSwingDialog(1)
    getRed = '*.czi;*.tiff;*.tif';
    getGreen = '*.czi;*.tiff;*.tif';
    getOutput = '.';
    if getenv('HOMEPATH')
        homepath = getenv('HOMEPATH');
    elseif getenv('HOME')
        homepath = getenv('HOME');
    end
    if ~exist(fullfile(homepath, 'CIRMIT_paths'), 'dir')
        mkdir(fullfile(homepath, 'CIRMIT_paths'));
    end
    if exist(fullfile(homepath, 'CIRMIT_paths'), 'file')
        try
            pathinfo = fileread(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths.txt'));
            pathinfo = regexp(pathinfo, '\n', 'split');
            getRed = fullfile(pathinfo{1}, '*.czi;*.tiff;*.tif');
            getGreen = fullfile(pathinfo{2}, '*.czi;*.tiff;*.tif');
            getOutput = pathinfo{3};
        catch
        end
    end
    [redFile, redPath] = uigetfile(getRed, 'Select Red Channel Image File');
    [greenFile, greenPath] = uigetfile(getGreen, 'Select Green Channel Image File');
    outputPath = uigetdir(getOutput, 'Select directory to save output');
    if ischar(redPath) & ischar(greenPath) & outputPath
        rp = strrep(redPath, '\', '/');
        gp = strrep(greenPath, '\', '/');
        op = strrep(outputPath, '\', '/');
        fid = fopen(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths.txt'), 'w');
        fprintf(fid, rp);
        fprintf(fid, '\n');
        fprintf(fid, gp);
        fprintf(fid, '\n');
        fprintf(fid, op);
        fclose(fid);
        clear rp gp op
    else
        error('Please select a red .CZI file, green .CZI file and output path');
    end
    barTotal = 6;
    if registerCheck.Value
        barTotal = barTotal+1;
    end
    if eventCheck.Value
        barTotal = barTotal+2;
    end
    if logCheck.Value
        barTotal = barTotal+1;
    end
    addpath(genpath('toolbox'))
    barCount = 1;
    bar = waitbar(barCount/barTotal, 'Processing Red', 'Name', 'Processing Image Data');
    [~,~,redExt] = fileparts(fullfile(redPath, redFile));
    if strcmpi(redExt, '.czi')
        [im, ~] = processRed(fullfile(redPath, redFile), saveCheck.Value, saveCheck.Value, outputPath);
    else
        im = imread(fullfile(redPath, redFile));
    end
    barCount = barCount+1;
    try
        waitbar(barCount/barTotal, bar, 'Processing Green', 'Name', 'Processing Image Data');
    catch
    end
    [~, name, ~] = fileparts(fullfile(greenPath, greenFile));
    if strcmpi(redExt, '.czi')
        [series1, x, y, t, MetaData] = processGreen(fullfile(greenPath, greenFile), ...
            saveCheck.Value, saveCheck.Value, outputPath, true);
        tiffFile = fullfile(outputPath, 'TIFF' , [name '.tiff']);
    else
        series1 = tiffreadVolume(fullfile(greenPath, greenFile));
        series1 = uint16(series1);
        [y, x, t] = size(series1);
        mdFig = uifigure('Name', 'CIRMIT', 'position', [360 198 325 300]);
        uilabel(mdFig, 'position', [20 260 300 25], 'Text', 'The file input was not a CZI file.');
        uilabel(mdFig, 'position', [20 245 300 25], 'Text', 'We need a little bit of information about this data!');
        uipanel(mdFig, 'position', [15 15 295 220]);
        uilabel(mdFig, 'position', [30 200 200 25], 'Text', 'Pixel scale x-dimension (microns)');
        xBox = uieditfield(mdFig, 'numeric', 'position', [50 175 75 20],...
            'Value', 0.645, 'Limits', [0 Inf], 'LowerLimitInclusive', 'off');
        uilabel(mdFig, 'position', [30 150 200 25], 'Text', 'Pixel scale y-dimension (microns)');
        yBox = uieditfield(mdFig, 'numeric', 'position', [50 125 75 20],...
            'Value', 0.645, 'Limits', [0 Inf], 'LowerLimitInclusive', 'off');
        uilabel(mdFig, 'position', [30 100 200 25], 'Text', 'Frame rate (FPS)');
        fpsBox = uieditfield(mdFig, 'numeric', 'position', [50 75 75 20],...
            'Value', 4, 'Limits', [0 Inf], 'LowerLimitInclusive', 'off');
        submit = uibutton(mdFig, 'push', 'position', [200 40 100 20], 'Text', 'Submit');
        submit.ButtonPushedFcn = {@submitMetaData, xBox, yBox, fpsBox, mdFig, fig};
        uiwait(mdFig);
        MetaData = get(fig, 'UserData');
        tiffFile = fullfile(greenPath, greenFile);
    end
    fps = MetaData.FPS;
    imDisplay = im;
    if size(im) ~= size(series1(:,:,1))
        im = imresize(im, size(series1(:,:,1)));
    end
    if strcmp(refineMethod.Value, 'Eccentricity')
        circles = false;
    else
        circles = true;
    end
    barCount = barCount+1;
    waitbar(barCount/barTotal, bar, 'Segmenting Red', 'Name', 'Processing Image Data');
    [mask, ROI_info] = segmentRed(fullfile(redPath, redFile), im, threshMethod.Value, sdThresh.Value,...
        circles, MetaData, saveCheck.Value, outputPath);
    if registerCheck.Value
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Registering Green (This might take a while)', 'Name', 'Processing Image Data');
        catch
        end
        series1 = registerGreen(greenFile, tiffFile, ...
            x, y, t, im, saveCheck.Value, saveCheck.Value, true, outputPath);
    end
    barCount = barCount+1;
    waitbar(barCount/barTotal, bar, 'Extracting Traces', 'Name', 'Processing Image Data');
    traces = traceExtraction(fullfile(greenPath, greenFile), series1, mask,...
        traceStat.Value, quantBox.Value, saveCheck.Value, outputPath);
    barCount = barCount+1;
    try
        waitbar(barCount/barTotal, bar, 'Smoothing Trace', 'Name', 'Processing Image Data');
    catch
    end
    if dffCheck.Value
        smoothTraces = dff(traces, [fps 62.5*fps], fullfile(greenPath, greenFile), saveCheck.Value, outputPath);
        fname = [name '_smoothTraces.mat'];
    else
        smoothTraces = traces;
        fname = [name '_traces.mat'];
    end
    
    if eventCheck.Value
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Motif Correlation', 'Name', 'Processing Image Data');
        catch
        end
        [dff1, Ca] = corrMotifs(smoothTraces, greenFile, 'spikes.mat', htBox.Value, dynamicCheck.Value, fps, saveCheck.Value, outputPath);
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Event Segmentation', 'Name', 'Processing Image Data');
        catch
        end
        events = findPeaks(dff1, Ca, greenFile, ctBox.Value, true, outputPath);
        
    else
        events = cell(1, max(mask(:)));
    end
    
    if logCheck.Value
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Taking Log Transformation', 'Name', 'Processing Image Data');
        catch
        end
        series1 = log(double(series1));
        imDisplay = log(double(imDisplay));
    end
    if size(imDisplay) ~= size(series1(:,:,1))
        imDisplay = imresize(imDisplay, size(series1(:,:,1)));
    end
    barCount = barCount+1;
    try
        waitbar(barCount/barTotal, bar, 'Launching Figure', 'Name', 'Processing Image Data');
    catch
    end
    [~,m]=size(smoothTraces);
    ymin = -0.1;
    ymax = 1.2*max(smoothTraces(:));
    timePts = size(smoothTraces, 1);
    for i = 1:m
        figure(1);
        plot((0:timePts-1)/fps, smoothTraces(:,i));
        hold on
        for ev = 1:length(events{i})
            plot([(events{i}(ev)-1)/10 (events{i}(ev)-1)/10], [ymin ymax], '-r', 'LineWidth', 2);
        end
        hold off
        ylim([ymin ymax]);
        figure(2);
        subplot(m, 1, i);
        plot((0:timePts-1)/fps, smoothTraces(:,i));
        hold on
        for ev = 1:length(events{i})
            plot([(events{i}(ev)-1)/10 (events{i}(ev)-1)/10], [ymin ymax], '-r', 'LineWidth', 2);
        end
        hold off
        ylim([ymin ymax]);
        figure(1);
        saveas(gcf, fullfile(outputPath, strcat(name, "_traceplot", num2str(i), ".pdf")));
        close(gcf);
    end
    figure(2);
    set(gcf, 'PaperUnits', 'Inches', 'PaperSize', [7.25, m]);
    set(gcf, 'PaperPosition', [0 0 7.25 m]);
    saveas(gcf, fullfile(outputPath, strcat(name, "_bigtraceplot.pdf")));
    close(gcf);
    m = min([m 4]);
    delete(gcp('nocreate'));
    [~, ~] = makeAnimation(smoothTraces, imDisplay, mask, ROI_info, series1, fullfile(greenPath, greenFile), events, 1:m, 1, fps);
    close(bar);
    %close(fig);

end

function submitMetaData(~, ~, xBox, yBox, fpsBox, mdFig, fig)

    MetaData = struct;
    MetaData.ScaleX = xBox.Value;
    MetaData.ScaleY = yBox.Value;
    MetaData.FPS = fpsBox.Value;
    set(fig, 'UserData', MetaData);
    close(mdFig);

end


function loadAndLaunch(~, ~, fig, eventCheck2, logCheck2, registerCheck2, dffCheck2)

    com.mathworks.mwswing.MJFileChooserPerPlatform.setUseSwingDialog(1)
    getMat = '*registered.mat';
    if getenv('HOMEPATH')
        homepath = getenv('HOMEPATH');
    elseif getenv('HOME')
        homepath = getenv('HOME');
    end
    if ~exist(fullfile(homepath, 'CIRMIT_paths'), 'dir')
        mkdir(fullfile(homepath, 'CIRMIT_paths'));
    end
    if exist(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths2.txt'), 'file')
        try
            pathinfo = fileread(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths2.txt'));
            if registerCheck2.Value
                getMat = fullfile(pathinfo, '*registered.mat');
            else
                getMat = fullfile(pathinfo, '*.mat');
            end
        catch
        end
    end
    [seriesFile, seriesPath] = uigetfile(getMat, 'Select Series .MAT File');
    if seriesPath
        sp = strrep(seriesPath, '\', '/');
        fid = fopen(fullfile(homepath, 'CIRMIT_paths', 'CIRMIT_paths2.txt'), 'w');
        fprintf(fid, sp);
        fclose(fid);
        clear sp
    else
        uialert(fig, 'Please select a series .MAT file', 'CIRMIT');
    end
    redPath = seriesPath;
    redFile = [seriesFile(1:strfind(seriesFile, 'field')+6) 'red.mat'];
    if ~exist(fullfile(redPath, redFile), 'file')
        [redFile, redPath] = uigetfile(fullfile(seriesPath, '*.mat'), 'Select Red .MAT File');
        if ~redPath
            uialert(fig, 'Please select a red image .MAT file', 'CIRMIT');
        end
    end
    [~,seriesName,seriesExt] = fileparts(seriesFile);
    [~,redName,redExt] = fileparts(redFile);
    ridx = strfind(seriesName, 'registered');
    if ridx
        seriesName = seriesName(1:ridx-2);
    else
        [~,seriesName,~] = fileparts(seriesName);
    end
    barTotal = 5;
    if eventCheck2.Value
        barTotal = barTotal+1;
    end
    if logCheck2.Value
        barTotal = barTotal+1;
    end
    barCount = 1;
    if strcmp(seriesExt, '.mat') && strcmp(redExt, '.mat')
        bar = waitbar(barCount/barTotal, 'Loading Series File', 'Name', 'Loading Data');
        try
            if ridx
                series1 = load(fullfile(seriesPath, seriesFile), 'regSeries');
                series1 = series1.regSeries;
            else
                series1 = load(fullfile(seriesPath, seriesFile), 'series');
                series1 = series1.series;
            end
        catch
            close(bar);
            uialert(fig, 'Series file did not have correct variable', 'CIRMIT');
        end
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Loading Red Image File', 'Name', 'Loading Data');
        catch
        end
        try
            load(fullfile(redPath, redFile), 'im');
        catch
            close(bar);
            uialert(fig, 'Red file did not have correct variable', 'CIRMIT');
        end
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Loading Trace File', 'Name', 'Loading Data');
        catch
        end
        if dffCheck2.Value
            try
                load(fullfile(seriesPath, [seriesName '_smoothTraces.mat']), 'smoothTraces');
            catch
                close(bar);
                uialert(fig, 'Could not find *smoothTraces.mat file with correct variable', 'CIRMIT');
            end
        else
            try
                load(fullfile(seriesPath, [seriesName '_traces.mat']), 'traces');
                smoothTraces = traces;
            catch
                close(bar);
                uialert(fig, 'Could not find *traces.mat file with correct variable', 'CIRMIT');
            end
        end
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Loading Mask File', 'Name', 'Loading Data');
        catch
        end
        try
            load(fullfile(redPath, [redName '_mask.mat']), 'mask', 'ROI_info');
        catch
            close(bar);
            uialert(fig, 'Could not find *mask.mat file with correct variables', 'CIRMIT');
        end
        if eventCheck2.Value
            barCount = barCount+1;
            try
                waitbar(barCount/barTotal, bar, 'Loading Events File', 'Name', 'Loading Data');
            catch
            end
            try
                load(fullfile(seriesPath, [seriesName '_events.mat']), 'events');
            catch
                close(bar);
                uialert(fig, 'Could not find *events.mat file with correct variable', 'CIRMIT');
            end
        else
            events = cell(1, max(mask(:)));
        end
    else
        uialert(fig, 'Please select a series .MAT file and corresponding red image .MAT file', 'CIRMIT');
    end
    if logCheck2.Value
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Taking Log Transformations', 'Name', 'Loading Data');
        catch
        end
        im = log(double(im));
        series1 = log(double(series1));
    end
    if size(im) ~= size(series1(:,:,1))
        im = imresize(im, size(series1(:,:,1)));
    end
    [~,m]=size(smoothTraces);
    m = min([m 4]);
    close(bar);
    [~, ~] = makeAnimation(smoothTraces, im, mask, ROI_info, series1, fullfile(seriesPath, seriesFile), events, 1:m, 1, 4);

end
