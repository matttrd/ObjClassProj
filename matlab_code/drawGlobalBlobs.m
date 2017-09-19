
%function img = drawGlobalBlobs(img)
global multi_blobs colors cameras matching;
for c = cameras
    if (multi_blobs(c).network.objects > 0)
        blobs = multi_blobs(c).network;
        for k = blobs.objects:-1:1
            rect = int32([blobs.object(k).absoluteX_ul ...
                 blobs.object(k).absoluteY_ul blobs.object(k).width ...
                 blobs.object(k).height]);
            circle = int32([blobs.object(k).absoluteX_cog ...
                 blobs.object(k).absoluteY_cog,3]);
            circle_old = int32([blobs.object(k).absoluteX_cog_old ...
                 blobs.object(k).absoluteY_cog_old,3]);
            found = false;
            for obj = 1:matching.objects
                sz = size(matching.object(obj).source);
                for mp = 1:sz(1)
                    if (matching.object(obj).source(mp,1) == c && matching.object(obj).source(mp,2) == k)
                        found = true;
                        break
                    end
                end
                if (found)
                    break
                end
            end
            multi_blobs(c).network.object(k).globalName = obj;
            img_track(:,:,:,c) = insertShape(img_track(:,:,:,c),'Circle',circle,'Color','red');
            img_track(:,:,:,c) = insertShape(img_track(:,:,:,c),'FilledCircle',circle_old,'Color','yellow');
            img_track(:,:,:,c) = insertObjectAnnotation(img_track(:,:,:,c),'Rectangle',rect,[matching.object(obj).type num2str(obj)],'Color',[0 255*255 0]);
        end
    end
end
%end