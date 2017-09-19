function [img_masked] = crop_blob(img,bbox)
% [img_masked] = crop_blob(img,bbox)
%fa un crop dell'immagine della dimensione data da bbox ([x_ul,y_ul,width,height])
%e applica la maschera (logical) all'immagine croppata. mask e bbox devono
%essere della stessa dimensione
img_crop = img(bbox(2):bbox(2)+bbox(4)-1,bbox(1):bbox(1)+bbox(3)-1,:);
img_masked = img_crop;
%img_masked = img_crop.*repmat(mask,[1 1 size(img_crop,3)]);
end

