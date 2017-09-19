function img = drawBlobs(img)
global blobs colors;
if (blobs.objects > 0)
    for k = blobs.objects:-1:1
        rect = int32([blobs.object(k).absoluteX_ul ...
             blobs.object(k).absoluteY_ul blobs.object(k).width ...
             blobs.object(k).height]);
        circle = int32([blobs.object(k).absoluteX_cog ...
             blobs.object(k).absoluteY_cog,2]);
        img = insertObjectAnnotation(img,'rectangle',rect,[blobs.object(k).type num2str(k)],'Color',colors(1,:));
        img = insertShape(img,'circle',circle,'Color','red');
    end
end