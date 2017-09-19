function [img] = imageRebuild(split_image,rows,columns,region_height)
%[img] = imageRebuild(split_image,rows,columns,region_height)
%Rebuilds image from an image that has been split into regions (rows x
%columns), where split_image must have in its rows the vectorization of
%each region, which are in columns or further dimension
split_image = squeeze(split_image);
Nreg = rows*columns;
sz = size(split_image);
region_width = sz(1)/region_height;
for i = Nreg:-1:1
    iW = mod(i,columns);            %column index of regions
    iH = (i-iW)/columns+1;          %row index of regions
    if (iW == 0)
        iW = columns;
        iH = iH-1;
    end
    %rebuilds region
    for j = region_width:-1:1
        region(:,j) = split_image((j-1)*region_height+1:region_height*j,i);
    end
    img((iH-1)*region_height+1:region_height*iH,(iW-1)*region_width+1:region_width*iW) = region;
end

