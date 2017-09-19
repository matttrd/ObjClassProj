function MotionFcn(FigH, EventData)
global calib;
x = get(FigH, 'CurrentPoint');
x = get(get(FigH, 'CurrentAxes'), 'CurrentPoint');
X = get3Dcoord(calib.P,x(1,1:2));
dist = getDistanceFromPPP(calib,X');
dist = getDistanceFromCamera(calib,X');
%dist = norm(X);
X1 = num2str(chop(X(1),15));
X2 = num2str(chop(X(2),15));
dist = num2str(chop(dist,15));
title(['Real world position: [' X1(1:5) ',' X2(1:5) '], distance from camera = ' dist(1:5) ' m']);
%title(['Real world position: [' num2str(x) ']']);
end