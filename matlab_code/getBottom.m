function [world,pixel] = getBottom(object)
%[world,pixel] = getBottom(object)
%returns bottom world coordinates of the object, which is supposed to lie
%on the ground plane. Returns also point in pixel coordinates. c is the
%camera of reference
global blobs multi
pixel = [blobs.object(object).absoluteX_cog ...
    blobs.object(object).absoluteY_ul+blobs.object(object).height];
world = get3Dcoord(multi.camera(1).P,pixel);
end

