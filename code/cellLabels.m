function cellLabels(mask)
    [l,m] = bwlabel(mask);
    stats = regionprops(l,'Area','Centroid','Eccentricity','BoundingBox','MajorAxisLength','MinorAxisLength');
    if m==1
        ROI_info = stats; %#ok<*NASGU>
    else 
        ROI_info = struct2table(stats);
    end
    for k = 1:m
        text(ROI_info.BoundingBox(k,1)+ROI_info.BoundingBox(k,3)+3,ROI_info.BoundingBox(k,2)-3,num2str(k), 'Color', 'white', 'Fontsize',7); 
    end
end