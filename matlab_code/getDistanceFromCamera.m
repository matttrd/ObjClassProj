function [dist,C] = getDistanceFromCamera(camera,X)
%[dist,C] = getDistanceFromCamera(camera,X)
% gets distance from camera centre (in m) of world point X
%
%input: X = world coordinates of point X, X = [x,y]
%
%output: distance from camera centre
%        camera centre in world coordinates

P = camera.P;
M = P(:,1:3);
C = -M\P(:,4);
dist = norm([X(1:2) 0]-C');
end