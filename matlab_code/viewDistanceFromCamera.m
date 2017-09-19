FigH = figure('WindowButtonMotionFcn', @MotionFcn);
sz = size(img);
img = insertShape(img,'line',[0 0 sz(2) sz(1); sz(2) 0 0 sz(1)],'Color',[0 255 0]);
imshow(img);