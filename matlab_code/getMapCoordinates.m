function [xym,xyTM] = getMapCoordinates(xy,camera,mode)
% GETMAPCOORDINATES gets map coordinates of world points xy which lie on the
% ground plane
%
% [xym,xyTM] = GETMAPCOORDINATES(xy,camera)
%
% [xym,xyTM] = GETMAPCOORDINATES(xy,camera,mode)
%
% input: xy is a Nx2 vector of coordinates in world reference
%        camera is a struct which contains various information of the map
%        mode is a string which allows you to do only the backtransform if
%           set to 'true'
% output: xym is a Nx2 pixel map coordinates related to xy
%         xyTM is a Nx2 true map coordinates related to xy
sz = size(xy);
if (sz(2) > 2)
    xy = xy(:,1:2);
end
if (nargin == 3 && strcmp(mode,'true') == 1)
    %then I've got yet true map coordinates and I need only the last
    %conversion
    true_map = true;
    xyTM = xy;
else
    true_map = false;
end
sz = size(xy);
for i = sz(1):-1:1
    if (~true_map)
        %extracts pixel map points
        xM = (xy(i,1)-camera.minX)*camera.scale;
        yM = (xy(i,2)-camera.minY)*camera.scale;
        %converts these into true map points
        xTM = xM - camera.mW/2;
        yTM = -yM + camera.mH/2;
        yTM = -yTM;     % due to flipud in the map
        %rotates points if necessary
        Rz = [cos(camera.rot*2*pi/360) -sin(camera.rot*2*pi/360) ; ...
            sin(camera.rot*2*pi/360) cos(camera.rot*2*pi/360)];
        xymi = Rz*[xTM;yTM];
        xyTM(i,:) = xymi';
    else
        xymi = xy(i,:)';
    end
    %backtransforms into pixel map points
    xym(i,1) = xymi(1) + camera.mWr/2;
    xym(i,2) = camera.mHr/2 - xymi(2);
end
end

