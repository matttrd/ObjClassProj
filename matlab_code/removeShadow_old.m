load('shape_car')
shape_smooth = imfilter(shape,fspecial('gaussian',[11 11],5),'same');
edges = edge(shape);
%imshow(edges)

corner_window = 9;
edge_enl = false(size(edges,1)+2*floor(corner_window/2),size(edges,2)+2*floor(corner_window/2));
edge_enl(floor(corner_window/2)+1:floor(corner_window/2)+size(edges,1),...
    floor(corner_window/2)+1:floor(corner_window/2)+size(edges,2)) = edges;
imshow(edge_enl)
shape_enl = false(size(edges,1)+2*floor(corner_window/2),size(edges,2)+2*floor(corner_window/2));
shape_enl(floor(corner_window/2)+1:floor(corner_window/2)+size(edges,1),...
    floor(corner_window/2)+1:floor(corner_window/2)+size(edges,2)) = shape;
imshow(edge_enl)
he = size(edge_enl,1);
we = size(edge_enl,2);

pixel_ind = find(edge_enl);
edge_px = length(pixel_ind);
for i = edge_px:-1:1
    [wh,ww] = ind2sub([he,we],pixel_ind(i));
    h_ind = wh-floor(corner_window/2):wh+floor(corner_window/2);
    w_ind = ww-floor(corner_window/2):ww+floor(corner_window/2);
    blob_px = length(find(shape_enl(h_ind,w_ind)));
    conc_corner(i) = blob_px/(corner_window^2-blob_px);
end
max_sort = sort(conc_corner,'descend');
NumberOfMaxima = 10;
max_conc_value = max_sort(1:NumberOfMaxima);
max_conc_value_find = max_conc_value;
for i = NumberOfMaxima:-1:1
    max_conc = find(conc_corner == max_conc_value_find(i),1,'first');
    max_conc_value_find(i) = -inf;
    [wh,ww] = ind2sub([he,we],max_conc);
    max_conc_ind(i,:) = [wh ww];
end

shape_cor = insertShape(shape_enl,'Circle',[max_conc_ind 4]);