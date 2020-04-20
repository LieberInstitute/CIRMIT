function main()

    fig = uifigure('Name', 'CIRMIT', 'position', [360 198 460 200]);
    uipanel(fig, 'position', [15 15 210 175]);
    uipanel(fig, 'position', [235 15 210 175]);
    processCZI = uibutton(fig, 'push', 'position', [20 20 200 20], 'Text', 'Process New CZIs');
    launchFromMAT = uibutton(fig, 'push', 'position', [240 20 200 20], 'Text', 'Launch Visualization from MATs');
    registerCheck = uicheckbox(fig, 'position', [30 150 200 20], 'Text', 'Register Green Series', 'Value', 1);
    eventCheck = uicheckbox(fig, 'position', [30 120 200 20], 'Text', 'Identify Events', 'Value', 1);
    logCheck = uicheckbox(fig, 'position', [30 90 200 20], 'Text', 'Display Log Transform', 'Value', 1);
    saveCheck = uicheckbox(fig, 'position', [30 60 200 20], 'Text', 'Save all data as MATs', 'Value', 1);
    eventCheck2 = uicheckbox(fig, 'position', [250 120 200 20], 'Text', 'Display Events', 'Value', 1);
    logCheck2 = uicheckbox(fig, 'position', [250 90 200 20], 'Text', 'Display Log Transform', 'Value', 1);
    processCZI.ButtonPushedFcn = {@startProcess, fig, registerCheck, eventCheck, logCheck, saveCheck};
    launchFromMAT.ButtonPushedFcn = {@loadAndLaunch, fig, eventCheck2, logCheck2};

end

function startProcess(~, ~, fig, registerCheck, eventCheck, logCheck, saveCheck)

    com.mathworks.mwswing.MJFileChooserPerPlatform.setUseSwingDialog(1)
    getRed = '*.czi';
    getGreen = '*.czi';
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
            getRed = fullfile(pathinfo{1}, '*.czi');
            getGreen = fullfile(pathinfo{2}, '*.czi');
            getOutput = pathinfo{3};
        catch
        end
    end
    [redFile, redPath] = uigetfile(getRed, 'Select Red Channel CZI File');
    [greenFile, greenPath] = uigetfile(getGreen, 'Select Green Channel CZI File');
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
    barCount = 1;
    bar = waitbar(barCount/barTotal, 'Processing Red', 'Name', 'Processing CZI Data');
    [im, ~] = processRed(fullfile(redPath, redFile), saveCheck.Value, saveCheck.Value, outputPath);
    barCount = barCount+1;
    try
        waitbar(barCount/barTotal, bar, 'Processing Green', 'Name', 'Processing CZI Data');
    catch
    end
    [series1, x, y, t, MetaData] = processGreen(fullfile(greenPath, greenFile), saveCheck.Value, saveCheck.Value, outputPath, true);
    fps = MetaData.FPS;
    if size(im) ~= size(series1(:,:,1))
        im = imresize(im, size(series1(:,:,1)));
    end
    barCount = barCount+1;
    waitbar(barCount/barTotal, bar, 'Segmenting Red', 'Name', 'Processing CZI Data');
    [mask, ROI_info] = segmentRed(fullfile(redPath, redFile), im, 'RegionGrow', 5, true, MetaData, saveCheck.Value, outputPath);
    [~, name, ~] = fileparts(fullfile(greenPath, greenFile));
    if registerCheck.Value
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Registering Green (This might take a while)', 'Name', 'Processing CZI Data');
        catch
        end
        series1 = registerGreen2(greenFile, fullfile(outputPath, 'TIFF' , [name '.tiff']), x, y, t, im, saveCheck.Value, saveCheck.Value, true, outputPath);
    end
    barCount = barCount+1;
    waitbar(barCount/barTotal, bar, 'Extracting Traces', 'Name', 'Processing CZI Data');
    traces = traceExtraction(fullfile(greenPath, greenFile), series1, mask, 'quantile', .75,  saveCheck.Value, outputPath);
    barCount = barCount+1;
    try
        waitbar(barCount/barTotal, bar, 'Smoothing Trace', 'Name', 'Processing CZI Data');
    catch
    end
    smoothTraces = dff(traces, [4 250], fullfile(greenPath, greenFile), saveCheck.Value, outputPath);
    if eventCheck.Value
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Motif Correlation', 'Name', 'Processing CZI Data');
        catch
        end
        [dff1, Ca] = corrMotifs(smoothTraces, greenFile, 'spikes.mat', .1, fps, saveCheck.Value, outputPath);
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Event Segmentation', 'Name', 'Processing CZI Data');
        catch
        end
        events = findPeaks(dff1, Ca, greenFile, .9, true, outputPath);
    else
        events = cell(1, max(mask(:)));
    end
    if logCheck.Value
        barCount = barCount+1;
        try
            waitbar(barCount/barTotal, bar, 'Taking Log Transformation', 'Name', 'Processing CZI Data');
        catch
        end
        series1 = log(double(series1));
        im = log(double(im));
    end
    barCount = barCount+1;
    try
        waitbar(barCount/barTotal, bar, 'Launching Figure', 'Name', 'Processing CZI Data');
    catch
    end
    [~,m]=size(smoothTraces);
    m = min([m 4]);
    delete(gcp('nocreate'));
    [~, ~] = makeAnimation(smoothTraces, im, mask, ROI_info, series1, fullfile(greenPath, greenFile), events, 1:m, 1, fps);
    close(bar);
    %close(fig);

end

function loadAndLaunch(~, ~, fig, eventCheck2, logCheck2)

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
            getMat = fullfile(pathinfo, '*registered.mat');
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
        try
            load(fullfile(seriesPath, [seriesName '_smoothTraces.mat']), 'smoothTraces');
        catch
            close(bar);
            uialert(fig, 'Could not find *smoothTraces.mat file with correct variable', 'CIRMIT');
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
    [~,m]=size(smoothTraces);
    m = min([m 4]);
    close(bar);
    [~, ~] = makeAnimation(smoothTraces, im, mask, ROI_info, series1, fullfile(seriesPath, seriesFile), events, 1:m, 1, 4);

end
