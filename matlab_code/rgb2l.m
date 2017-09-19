function [value_img] = rgb2l(img)
%[value_img] = RGB2V(img)
%Converts rgb image into Value channel

%img_hsv = rgb2hsv(img);
value_img = (img(:,:,1)+img(:,:,2)+img(:,:,3))/3;
%value_img = histeq(value_img);
end

