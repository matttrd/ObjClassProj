function [blobs] = getBlobs(regions,error_bin,error_scale)
%[blob] = getBlob(regions)
%returns blob info from matrix group info. regions is typically the output
%of make_regions. blob is a structure
global numHregions numWregions N H W rH rW areaVector multi;
if (regions(1,1) == 0)
    blobs.objects = 0;
    return
end
error_bin = squeeze(error_bin);
% rebuilds a rectangular region for where we will build the pixel regions
% where the error is over a certain threshold
% length(regions) = # of unconnected blobs
blobs.objects = length(regions);
sz = size(regions);
items = sz(1);
j = 1;
while (j <= items)
    eol = find(regions(j,:) == 0,1,'first');
    if (isempty(eol))
        connected_regions = sz(2);
    else
        connected_regions = eol - 1;
    end
    right = 1;
    bottom = 1;
    left = numWregions;
    top = numHregions;
    for k = connected_regions:-1:1
        [iH,iW] = getMatrixIndex(regions(j,k));
        if (iW < left)
            left = iW;
        end
        if (iW > right)
            right = iW;
        end
        if (iH < top)
            top = iH;
        end
        if (iH > bottom)
            bottom = iH;
        end
    end
    % now we have the most left, top, bottom and right regions
    % from now on, we will work on a reduced image, which has different
    % dimensions respect to the original one
    %disp(['Analysing item ' num2str(j) '/' num2str(items)])
    % picks up the error_img for whole the regions included into the bounds
    % just found. If an image didn't trigger an error, it will pick up a
    % vectorized region with only 0s (this is done by the caller)
    mini_zone = zeros(1,(bottom-top+1)*(right-left+1));
    q = 1;
    for l = left:right
        for m = top:bottom
            mini_zone(q) = (m-1)*numWregions+l;
            q = q + 1;
        end
    end
%     disp(['mini_zone = ' num2str(mini_zone)])
%     disp(['alarms    = ' num2str(regions(j,:))])
%     disp(['bounds    = ' num2str([left right top bottom])])
%     disp(['-----------------------------------'])
    reduced_img = imageRebuild(error_bin(:,mini_zone),bottom-top+1,right-left+1,rH);
    red_img_scale = reduced_img;
    %imageRebuild(error_scale(:,mini_zone),bottom-top+1,right-left+1,rH);
    kernels = [0.1 0.2 0.3 0.4 0.6];
    cog = [];
    for i = length(kernels):-1:1
        kernelPx = find(red_img_scale > kernels(i));
        thrImg = zeros(size(red_img_scale));
        thrImg(kernelPx) = 1;
        red_img_scale(kernelPx) = 0;
        centr = regionprops(thrImg,'centroid');
        if(~isempty(centr))
            cog(i,:) = centr.Centroid;
        end     
    end
    ccArea = bwareaopen(reduced_img,5);
    conv_hull = bwconvhull(ccArea);
    centroid = regionprops(reduced_img,'centroid');
    if (~isempty(cog))
        centroid_old = centroid;
        centroid = [];
        centr = [sum(cog(:,1)) sum(cog(:,2))]/size(cog,1);
        centroid.Centroid = centr;
    end
    bbox = regionprops(conv_hull,'BoundingBox');
    if (~isempty(centroid) && ~isempty(bbox) > 0)
        centroid = floor(centroid.Centroid);
        blobs.object(j).reduced_img = reduced_img;
        blobs.object(j).x_cog = centroid(1);
        blobs.object(j).y_cog = centroid(2);
        blobs.object(j).x_ul = floor(bbox.BoundingBox(1));
        blobs.object(j).y_ul = floor(bbox.BoundingBox(2));
        blobs.object(j).width = ceil(bbox.BoundingBox(3));
        blobs.object(j).height = ceil(bbox.BoundingBox(4));
        blobs.object(j).region_alarms = regions(j,:);
        blobs.object(j).absoluteX_ul = blobs.object(j).x_ul + (left-1)*rW;
        blobs.object(j).absoluteY_ul = blobs.object(j).y_ul + (top-1)*rH;
        blobs.object(j).absoluteX_cog = blobs.object(j).x_cog + (left-1)*rW;
        blobs.object(j).absoluteY_cog = blobs.object(j).y_cog + (top-1)*rH;
        blobs.object(j).absoluteX_cog_old = centroid_old.Centroid(1) + (left-1)*rW;
        blobs.object(j).absoluteY_cog_old = centroid_old.Centroid(2) + (top-1)*rH;
        blobs.object(j).convexHull = conv_hull;
        blobs.object(j).bbox_large = [(left-1)*rW+1,(top-1)*rH+1,(right-left+1)*rW,(abs(bottom-top)+1)*rH];
        blobs.object(j).bbox = ceil(bbox.BoundingBox(1:4));
        blobs.object(j).bbox_xRange = blobs.object(j).absoluteX_ul:blobs.object(j).absoluteX_ul+size(conv_hull,2)-1;
        blobs.object(j).bbox_yRange = blobs.object(j).absoluteY_ul:blobs.object(j).absoluteY_ul+size(conv_hull,1)-1;
        blobs.object(j).bbox_large_xRange = (left-1)*rW+1:right*rW;
        blobs.object(j).bbox_large_yRange = (top-1)*rW+1:bottom*rW;
        ecc = regionprops(reduced_img,'eccentricity');
        sol = regionprops(reduced_img,'solidity');
        max_l = regionprops(reduced_img,'MajorAxisLength');
        min_l = regionprops(reduced_img,'MinorAxisLength');
        or = regionprops(reduced_img,'orientation');
        blobs.object(j).ecc = ecc.Eccentricity;
        blobs.object(j).sol = sol.Solidity;
        blobs.object(j).max_l = max_l.MajorAxisLength;
        blobs.object(j).min_l = min_l.MinorAxisLength;
        blobs.object(j).or = or.Orientation;
        area = bwarea(ccArea);
        blobs.object(j).area = area;
        areaVector = [areaVector area];
        blobs.areaVector = areaVector;
        j = j + 1;
        blobs.object(j).type = 'object';
    else
        % if an object is too small, then the number of objects will be
        % decreased and the index j will not be increased, so every index
        % of the structure will have a true item. If this is the last
        % expected object, no j-th field will be inserted
        %disp(['object ' num2str(j) ' too small. Item decreased to ' num2str(items-1)])
        items = items - 1;
    end
end
blobs.objects = items;
end

