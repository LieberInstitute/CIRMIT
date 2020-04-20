function mask2 = circlemask(mask, pixelThresh)

    areas = regionprops(mask, 'Area');
    mxArea = max([areas.Area]);
    se = strel('disk',max([floor(sqrt(mxArea)/10) 1]));
    emask = imerode(mask, se);
    [c,r] = imfindcircles(emask, [round(sqrt(pixelThresh/pi)) 2*(round(sqrt(pixelThresh))+1)]);
    mask2 = false(size(mask));
    for i = 1:length(r)
        [xgrid, ygrid] = meshgrid(1:size(mask,2), 1:size(mask,1));
        thisCircle = ((xgrid-c(i,1)).^2 + (ygrid-c(i,2)).^2) < r(i).^2;
        if (mean(mask(thisCircle)) > 0.5)
            mask2 = mask2 | (thisCircle & mask);
        end
    end


end
