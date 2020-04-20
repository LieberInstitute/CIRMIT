function [mask, ROI_info] = segmentRed(redFile, im, method, sdThresh, circles, MetaData, saveMask, outputPath)

    pixelThresh = ceil(20/(MetaData.ScaleX*MetaData.ScaleY));
    if strcmp(method, 'MedianTransform')
        im = double(im);
        imT = (im-median(im(:)))/std2(im);
        mask1 = imT>sdThresh;
        mask1 = bwareaopen(mask1, pixelThresh);
        if circles
            mask1 = circlemask(mask1, pixelThresh);
        end
        D = -bwdist(~mask1);
        D = imimposemin(D,imextendedmin(D,2));
        mask2 = watershed(D);
        mask2(~mask1) = 0;
        [mask,~] = bwlabel(mask2);
        stats = regionprops(mask,'Area','Centroid','Eccentricity','BoundingBox','MajorAxisLength','MinorAxisLength','PixelList','PixelIdxList');
        if ~circles
            idx = find([stats.Eccentricity]<0.99);
            mask2 = ismember(bwlabeln(mask),idx);
        end
        mask2 = bwareaopen(mask2, pixelThresh);
        mask2 = imclearborder(mask2,8);
        [mask,m] = bwlabel(mask2);
        stats = regionprops(mask,'Area','Centroid','Eccentricity','BoundingBox','MajorAxisLength','MinorAxisLength','PixelList','PixelIdxList');
        if m==1
            ROI_info = stats;
        else
            ROI_info = struct2table(stats);
        end
        [~, name, ~] = fileparts(redFile);
        if saveMask
            if ~exist(outputPath, 'dir')
                mkdir(outputPath);
            end
            save(fullfile(outputPath, [name '_mask.mat']), 'mask', 'ROI_info', '-v6');
        end
    elseif strcmp(method, 'RegionGrow')
        imgcherry = double(im);
        imgcherry = imhmin(imgcherry,2*std2(imgcherry));
        thresh = [num2str(sdThresh) '*std2(imgcherry)'];
        [r,c] = find(imgcherry == min(imgcherry(:))); %find the coordinates of the seed
        J = regiongrowing(imgcherry,r(1),c(1),eval(thresh));
        if circles 
            BW2 = ~J;
            BW2 = circlemask(BW2, pixelThresh);
            J = ~BW2;
        end
        D = -bwdist(J);
        D = imimposemin(D,imextendedmin(D,2));
        mask = watershed(D);
        mask(J) = 0;
        stats = regionprops(bwlabeln(mask),'Area','Centroid','Eccentricity','BoundingBox','MajorAxisLength','MinorAxisLength','PixelList','PixelIdxList');
        idx = find([stats.Area]>pixelThresh);
        BW2 = ismember(bwlabeln(mask),idx);
        [mask,m] = bwlabel(BW2);
        stats = regionprops(mask,'Area','Centroid','Eccentricity','BoundingBox','MajorAxisLength','MinorAxisLength','PixelList','PixelIdxList');
        if ~circles
            idx = find([stats.Eccentricity]<0.99);
            BW2 = ismember(bwlabeln(mask),idx);
        end
        [mask,m] = bwlabel(BW2);
        idx = find([stats.Area]>pixelThresh);
        BW2 = ismember(bwlabeln(mask),idx);
        BW2 = imclearborder(BW2,8);
        [mask,m] = bwlabel(BW2);
        stats = regionprops(mask,'Area','Centroid','Eccentricity','BoundingBox','MajorAxisLength','MinorAxisLength','PixelList','PixelIdxList');
        if m==1
            ROI_info = stats; %#ok<*NASGU>
        else
            ROI_info = struct2table(stats);
        end
        [~, name, ~] = fileparts(redFile);
        if saveMask
            if ~exist(outputPath, 'dir')
                mkdir(outputPath);
            end
            save(fullfile(outputPath, [name '_mask.mat']), 'mask', 'ROI_info', '-v6');
        end
    elseif strcmp(method, 'Manual')
        lim = log10(double(im));
        %limT = max(lim(:))-lim;
        %limT = (limT-min(limT(:)))/(max(limT(:))-min(limT(:)));
        limT = 1-mat2gray(lim);
        fig = figure('WindowState', 'maximized');  
        subplot('position', [0.05 0.1 0.9 0.85]); f = imagesc(lim);colormap(gray); axis off;
        uipanel('units', 'normalized', 'position', [0.725 0.025 0.15 0.045], 'Title', 'Region Grow Threshold');
        threshDialog = uicontrol('Style', 'edit', 'units', 'normalized', 'position', [0.77 0.03 0.06 0.02], 'String', 0.05);
        threshDown = uicontrol('Style', 'push', 'units', 'normalized', 'position', [0.73 0.03 0.03 0.02], 'String', '-');
        threshUp = uicontrol('Style', 'push', 'units', 'normalized', 'position', [0.84 0.03 0.03 0.02], 'String', '+');
        saveButton = uicontrol('Style', 'push', 'units', 'normalized', 'position', [0.9 0.025 0.05 0.045], 'String', 'Save');
        set(f, 'UserData', zeros(size(im)));
        f.ButtonDownFcn = {@manualSegmentation, f, limT, threshDialog};
        threshDialog.Callback = {@changeThresh, threshDown, threshUp, 0.05};
        threshDown.Callback = {@threshDownFcn, threshUp, threshDialog};
        threshUp.Callback = {@threshUpFcn, threshDown, threshDialog};
        saveButton.Callback = {@saveManual, f, redFile, saveMask, outputPath, fig};
    else
        error('Please choose a valid segmentation method: "MedianTransform" or "RegionGrow"');
    end
    

end

function manualSegmentation(hObj, Event, f, limT, threshDialog)

    x = floor(Event.IntersectionPoint(1));
    y = floor(Event.IntersectionPoint(2));
    mask = get(hObj, 'UserData');
    if mask(y,x)
        maskLab = bwlabel(mask);
        idx = maskLab(y,x);
        delete(hObj);
        mask(maskLab==idx)=0;
        set(f, 'UserData', mask);
    else
        thresh = str2double(get(threshDialog, 'String'));
        mask = imfill(regiongrowing(limT, y, x, thresh) | mask, 'holes');
        set(hObj, 'UserData', mask);
        maskLab = bwlabel(mask);
        for i = 1:max(maskLab(:))
            [c,r] = find(maskLab==i);
            hold on
            hLine = plot(r, c, 'r.', 'ButtonDownFcn', {@manualSegmentation, f, limT, thresh});
            hold off
            set(hLine, 'UserData', mask);
        end
        
    end

end

function changeThresh(hDialog, ~, threshDown, threshUp, defaultThresh)

    thresh = str2double(get(hDialog, 'String'));
    if thresh <= 0 || thresh >= 1
        errordlg('Threshold must be between 0 and 1');
        thresh = defaultThresh;
    end
    set(hDialog, 'String', thresh);
    if thresh <= 0.01
        set(threshDown, 'Enable', 'off');
    elseif thresh >= 0.99
        set(threshUp, 'Enable', 'off');
    else
        set(threshDown, 'Enable', 'on');
        set(threshUp, 'Enable', 'on');
    end

end

function threshDownFcn(threshDown, ~, threshUp, threshDialog)

    thresh = str2double(get(threshDialog, 'String'))-0.01;
    set(threshDialog, 'String', thresh);
    if thresh<=0.01
        set(threshDown, 'Enable', 'off');
    elseif thresh>=0.99
        set(threshUp, 'Enable', 'off');
    else
        set(threshDown, 'Enable', 'on');
        set(threshUp, 'Enable', 'on');
    end
end

function threshUpFcn(threshUp, ~, threshDown, threshDialog)

    thresh = str2double(get(threshDialog, 'String'))+0.01;
    set(threshDialog, 'String', thresh);
    if thresh<=0.01
        set(threshDown, 'Enable', 'off');
    elseif thresh>=0.99
        set(threshUp, 'Enable', 'off');
    else
        set(threshDown, 'Enable', 'on');
        set(threshUp, 'Enable', 'on');
    end

end

function saveManual(~, ~, f, redFile, saveMask, outputPath, fig)

    mask = get(f, 'UserData');
    [mask,m] = bwlabel(mask);
    stats = regionprops(mask,'Area','Centroid','Eccentricity','BoundingBox','MajorAxisLength','MinorAxisLength','PixelList','PixelIdxList');
    if m==1
        ROI_info = stats; %#ok<*NASGU>
    else
        ROI_info = struct2table(stats);
    end
    [~, name, ~] = fileparts(redFile);
    if saveMask
        if ~exist(outputPath, 'dir')
            mkdir(outputPath);
        end
        save(fullfile(outputPath, [name '_mask.mat']), 'mask', 'ROI_info', '-v6');
    end
    close(fig);
    
end
