function dist = getDistanceFromPPP(camera,X)
% dist = GETDISTANCEFROMPPP(camera,X)
% measure distance in the ground plane between the projection of principal
% point into the ground plane and point X in world coordinates, supposed to
% be on the ground pklane too
global H W
G = get3Dcoord(camera.P,[ceil(H/2), ceil(W/2)]);
dist = norm(G(1:2)-X(1:2)');
end