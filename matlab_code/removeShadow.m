foreYCbCr = rgb2ycbcr(cropped_blob);
fore_Y = foreYCbCr(:,:,1);
fore_Cb = foreYCbCr(:,:,2);
fore_Cr = foreYCbCr(:,:,3);

back = crop_blob(background,box);
backYCbCr = rgb2ycbcr(back);
backYCbCr = rgb2ycbcr(back);
back_Y = backYCbCr(:,:,1);
back_Cb = backYCbCr(:,:,2);
back_Cr = backYCbCr(:,:,3);

diff_Y = fore_Y - back_Y;
diff_Cb = fore_Cb - back_Cb;
diff_Cr = fore_Cr - back_Cr;

threshY = 0.09;
threshCbr = 0.3;

sh = logical((diff_Y < -threshY | diff_Y > 0) & abs(diff_Cb) < threshCbr & abs(diff_Cr) < threshCbr);
%%
shape_new = shape & sh;
se = strel('square',5);
shape_new = imfill(shape_new,'holes');
shape_new = imdilate(shape_new,se);
shape_new = imfill(shape_new,'holes');
CC = bwconncomp(shape_new);
valid_blob = false;
if (CC.NumObjects >= 1)
    lengths = [];
    for id = 1:length(CC.PixelIdxList)
        lengths(id) = length(CC.PixelIdxList{id});
    end
    max_cc = find(lengths == max(lengths),1,'first');
    shape_cc1 = logical(0*shape);
    shape_cc1(CC.PixelIdxList{max_cc}) = true;
    max2 = find(lengths >= 0.5*lengths(max_cc) & lengths < lengths(max_cc));
    if (~isempty(max2))
        disp(['t = ' num2str(t) ' : sdoppiamento'])
        old_obj = cc.NumObjects;
        cc.NumObjects = old_obj + length(max2);
        id2 = 1;
        for id = max2
            new_shape = logical(0*shape);
            new_shape(CC.PixelIdxList{id}) = true;
            new_glob_shape = false(H,W);
            new_glob_shape(box(2):box(4)+box(2)-1,box(1):box(3)+box(1)-1) = new_shape;
            nCC = bwconncomp(new_glob_shape);
            cc.PixelIdxList{old_obj+id2} = nCC.PixelIdxList{1};
            id2 = id2 + 1;
        end
    end
    box_new = regionprops(shape_cc1,'BoundingBox');
    area = regionprops(shape_cc1,'Area');
    if (area.Area > 200)
        valid_blob = true;
        box_new = box_new.BoundingBox;
        box_rel = round(box_new);
        box_old = box;
        CoG = regionprops(shape_cc1,'Centroid');
        box_new(1) = box_new(1) + box(1);
        box_new(2) = box_new(2) + box(2);
        box = round(box_new);
        shape = shape_new(box_rel(2):box_rel(2)+box_rel(4)-1,box_rel(1):box_rel(1)+box_rel(3)-1);
        glob_mask = false(H,W);
        glob_mask(box(2):box(4)+box(2)-1,box(1):box(3)+box(1)-1) = shape;
        xCoG = round(CoG.Centroid(1)+box_old(1));
        CoGcolumn = glob_mask(:,xCoG);
        bottom_y = find(CoGcolumn,5,'last');
        bottom_y = bottom_y(1);
        ground = [xCoG bottom_y];
        %shadow_foreground(:,:,1) = shadow_foreground(:,:,1).*glob_mask*1;
        shadow_foreground(:,:,2) = shadow_foreground(:,:,2).*~glob_mask*1;
        shadow_foreground(:,:,3) = shadow_foreground(:,:,3).*~glob_mask*1;
    end
end


