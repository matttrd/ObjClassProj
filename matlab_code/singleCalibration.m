
%% initialization
warning('OFF','images:imshow:magnificationMustBeFitForDockedFigure')
warning('OFF','images:initSize:adjustingMag')
frame = double(mov(:,:,:,1))/255;
%% calibration
img = frame;
dim = 1;
if (length(img) > 640)
    dim = 1.5;
elseif (length(img) <= 320)
    dim = 0.67;
end
imshow(img);
title('Select ORIGIN of world coordinates')
[x0,y0] = ginput(1);
img = insertObjectAnnotation(img,'circle',[x0,y0,4],'O','Color','red','FontSize',ceil(12*dim));
Ow = [x0,y0];
imshow(img);

com = 0;
img_old = img;
while (com ~= 1)
    img = img_old;
    title('Select a point along X axis of world coordinates')
    [x1,y1,com] = ginput(1);
    img = insertObjectAnnotation(img,'circle',[x1 y1 4],'1(X)','Color','red','FontSize',ceil(12*dim));
    img = insertShape(img,'Line',[Ow x1 y1],'Color','red');
    imshow(img);
end
arrow(Ow,[x1 y1],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
X1 = input('Insert X coordinate of 1 in [m]: ');

com = 0;
img_old = img;
while (com ~= 1)
    img = img_old;
    title('Select a point along Y axis of world coordinates')
    [x2,y2,com] = ginput(1);
    img = insertObjectAnnotation(img,'circle',[x2 y2 4],'2(Y)','Color','red','FontSize',ceil(12*dim));
    img = insertShape(img,'Line',[Ow x2 y2],'Color','red');
    imshow(img);
end
arrow(Ow,[x1 y1],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
arrow(Ow,[x2 y2],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
Y2 = input('Insert Y coordinate of 2 in [m]: ');

com = 0;
img_old = img;
while (com ~= 1)
    img = img_old;
    title('Select a point along Z axis of world coordinates')
    [x3,y3,com] = ginput(1);
    img = insertObjectAnnotation(img,'circle',[x3 y3 4],'3(Z)','Color','red','FontSize',ceil(12*dim));
    img = insertShape(img,'Line',[Ow x3 y3],'Color','red');
    imshow(img);
end
arrow(Ow,[x1 y1],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
arrow(Ow,[x2 y2],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
arrow(Ow,[x3 y3],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
Z3 = input('Insert Z coordinate of 3 in [m]: ');

x = [x0,y0 ; x1,y1 ; x2,y2 ; x3,y3];
X = [0 0 0; X1,0,0; 0,Y2,0; 0,0,Z3];

i = 4;
while true
    com = 0;
    img_old = img;
    while (com ~= 1 && com ~= 3)
        img = img_old;
        title('Select a new point. RIGHT CLICK to end')
        [xN,yN,com] = ginput(1);
        if (com == 3)
            disp(['Point Acquisition Ended. ' num2str(i-1) ' points acquired.'])
            break
        end
        img = insertObjectAnnotation(img,'circle',[xN yN 4],num2str(i),'FontSize',ceil(12*dim));
        if (com == 1)
            imshow(img);
            break
        end
        img = insertShape(img,'Line',[x(end,:) xN yN]);
        imshow(img);
    end
    if (com == 3)
        break
    end
    img = img_old;
    img = insertObjectAnnotation(img,'circle',[xN yN 4],num2str(i),'FontSize',ceil(12*dim));
    arrow(Ow,[x1 y1],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
    arrow(Ow,[x2 y2],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
    arrow(Ow,[x3 y3],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
    coord = input(['Insert point reference, axis reference and absolute coordinate' ...
        '\n [point_ref axis coord axis coord axis coord]:  '],'s');
    coord = textscan(coord,'%s');
    param = size(coord{1});
    param = param(1);
    stop = false;
    while (param ~= 3 && param ~= 5 && param ~= 7)
        warning('Wrong number of parameters inserted. Retry');
        coord = input(['Insert point reference, axis reference and absolute coordinate' ...
            '\n [point_ref axis coord axis coord axis coord]:  '],'s');
        if (size(coord) == 0)
            disp(['Point Acquisition Ended. ' num2str(i) ' points acquired.'])
            stop = true;
            break
        end
        coord = textscan(coord,'%s');
        param = size(coord{1});
        param = param(1);
    end
    if stop
        break
    end
    ref = str2double(coord{1}(1));
    axis1 = coord{1}(2);
    dist1 = str2double(coord{1}(3));
    if (strcmpi(axis1,'x'))
        XN = X(ref+1,:) + [dist1 0 0];
    else if (strcmpi(axis1,'y'))
        XN = X(ref+1,:) + [0 dist1 0];
    else if (strcmpi(axis1,'z'))
        XN = X(ref+1,:) + [0 0 dist1];
        end
        end
    end
    if (param == 5 || param == 7)
        axis2 = coord{1}(4);
        dist2 = str2double(coord{1}(5));
        if (strcmpi(axis2,'x'))
            XN = XN + [dist2 0 0];
        else if (strcmpi(axis2,'y'))
            XN = XN + [0 dist2 0];
        else if (strcmpi(axis2,'z'))
            XN = XN + [0 0 dist2];
            end
            end
        end
        if (param == 7)
            axis3 = coord{1}(6);
            dist3 = str2double(coord{1}(7));
            if (strcmpi(axis3,'x'))
                XN = XN + [dist3 0 0];
            else if (strcmpi(axis3,'y'))load
                XN = XN + [0 dist3 0];
            else if (strcmpi(axis3,'z'))
                XN = XN + [0 0 dist3];
                end
                end
            end
        end
    end
    x = [x;xN,yN];
    X = [X;XN];
    img = insertShape(img,'Line',[x(ref+1,:) xN yN]);
    imshow(img);
    arrow(Ow,[x1 y1],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
    arrow(Ow,[x2 y2],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
    arrow(Ow,[x3 y3],'FaceColor',[1 0 0],'EdgeColor',[1 0 0]);
    i = i + 1;
end
P = CalibNormDLT(x,X);
imgCalib = img;
calib.P = P;
calib.imgCalib = img;
calib.xPx = x;
calib.Xworld = X;
name = [folder '/Calibration.png'];
set(gcf,'PaperPositionMode','auto')
print('-dpng','-r300', name)
%save([folder 'calib.mat'],'calib')

%% Referement Height computation 
x = calib.xPx;
X = calib.Xworld;
xBase = x(1,:);
xHigh = x(4,:);
heightRefInPix = norm(xBase-xHigh);
heightRef = X(4,3);
q = xBase;
P1 = calib.P;
Q = get3Dcoord(P1,q)';
Q = [Q(1) Q(2)];
distRef = getDistanceFromCamera(calib,Q);
calib.distRef = distRef;
calib.heightRefInPix = heightRefInPix;
calib.heightRef = heightRef;
%% place tracker
warning('OFF','images:imshow:magnificationMustBeFitForDockedFigure')
warning('OFF','images:initSize:adjustingMag')
img = frame;
P = calib.P;
figure(99)
imshow(img);
title('Delimitate one road of the place (polyline), press right button to start a new road and ENTER to stop')
clear('place');
k = 1;
s = 0;
while true
    [xR,yR,command] = ginput(1);
    if (size(command) == 0)
        break
    end
    if (command == 3 || (s == 0 && k == 1))
        k = 1;
        s = s + 1;
    elseif (command == 2)
        k = 1;
        s = 1;
        img = imread([folder num2str(c) '/normal/normal-0.jpg']);
        imshow(img);
        place = rmfield(place,'road');
    else
        k = k + 1;
    end
    place.road(s).point(k).x = xR;
    place.road(s).point(k).y = yR;
    Q = get3Dcoord(calib.P,[xR,yR]);
    place.road(s).point(k).Xworld = Q(1);
    place.road(s).point(k).Yworld = Q(2);
    img = insertShape(img,'circle',[xR yR 4],'Color',[0 0 0]);
    if (k > 1)
        img = insertShape(img,'Line',[place.road(s).point(k-1).x place.road(s).point(k-1).y xR yR],'Color',[0 0 0]);
    end
    imshow(img);
end

title('Do the same with buildings, press right button to start a new road and ENTER to stop')
k = 1;
s = 0;
while true
    [xR,yR,command] = ginput(1);
    if (size(command) == 0)
        break
    end
    if (command == 3 || (s == 0 && k == 1))
        k = 1;
        s = s + 1;
    elseif (command == 2)
        k = 1;
        s = 1;
        img = imread([folder num2str(c) '/normal/normal-0.jpg']);
        imshow(img);
        place = rmfield(place,'building');
    else
        k = k + 1;
    end
    place.building(s).point(k).x = xR;
    place.building(s).point(k).y = yR;
    Q = get3Dcoord(calib.P,[xR,yR]);
    place.building(s).point(k).Xworld = Q(1);
    place.building(s).point(k).Yworld = Q(2);
    img = insertShape(img,'circle',[xR yR 4],'Color',[255 0 0]);
    if (k > 1)
        img = insertShape(img,'Line',[place.building(s).point(k-1).x place.building(s).point(k-1).y xR yR],'Color',[255 0 0]);
    end
    imshow(img);
end
calib.places = place;

%%
img = frame;
figure(99)
clf
imshow(img);
title('Delimit area (ploygon) to watch, ENTER to end')
k = 1;
xP = [];
yP = [];
while true
    [xR,yR,command] = ginput(1);
    if (size(command) == 0)
        break
    end
    xP = [xP;xR];
    yP = [yP;yR];
    img = insertShape(img,'circle',[xR yR 4],'Color',[0 0 0.7]);
    if (k > 1)
        img = insertShape(img,'Line',[xP(k-1) yP(k-1) xR yR],'Color',[0 0 0.7]);
    end
    imshow(img);
    k = k + 1;
end
xP(k) = xP(1);
yP(k) = yP(1);
calib.watch = [xP yP];

%% Convert place points into top view map
% finds the points which has max and min x and y in world reference
%load([folder 'cameras.mat']);
global minX minY mH mW scale rotation;
place = calib.places;
maxX = place.road(1).point(1).Xworld;
minX = maxX;
maxY = place.road(1).point(1).Yworld;
minY = maxY;
for s = 1:length(place.road)
    for k = 1:length(place.road(s).point)
        if (place.road(s).point(k).Xworld > maxX)
            maxX = place.road(s).point(k).Xworld;
        end
        if (place.road(s).point(k).Xworld < minX)
            minX = place.road(s).point(k).Xworld;
        end
        if (place.road(s).point(k).Yworld > maxY)
            maxY = place.road(s).point(k).Yworld;
        end
        if (place.road(s).point(k).Yworld < minY)
            minY = place.road(s).point(k).Yworld;
        end
    end
end
if (isfield(place,'building'))
    for s = 1:length(place.building)
        for k = 1:length(place.building(s).point)
            if (place.building(s).point(k).Xworld > maxX)
                maxX = place.building(s).point(k).Xworld;
            end
            if (place.building(s).point(k).Xworld < minX)
                minX = place.building(s).point(k).Xworld;
            end
            if (place.building(s).point(k).Yworld > maxY)
                maxY = place.building(s).point(k).Yworld;
            end
            if (place.building(s).point(k).Yworld < minY)
                minY = place.building(s).point(k).Yworld;
            end
        end
    end
end

extX = maxX-minX;
extY = maxY-minY;
mH = 576;
mW = floor(mH*extX/extY);
scale = mW/extX;
top_map = uint8(255*ones(mH,mW,3));
for s = 1:length(place.road)
    for k = 1:length(place.road(s).point)
        % xM and yM are in pixel map coordinates
        xM = (place.road(s).point(k).Xworld-minX)*scale;
        yM = (place.road(s).point(k).Yworld-minY)*scale;
        % xTM and yTM are in true map coordinates (origin in the middle)
        xTM = xM - mW/2;
        yTM = -yM + mH/2;
        if (k > 1)
            top_map = insertShape(top_map,'Line',[xMold yMold xM yM;xMold+1 yMold+1 xM+1 yM+1],'Color',[0 0 0]);
        end
        xMold = xM;
        yMold = yM;
        %calib.true_map_places.road(s).point(k) = [xTM,yTM];
    end
end
if (isfield(place,'building'))
    for s = 1:length(place.building)
        for k = 1:length(place.building(s).point)
            % xM and yM are in pixel map coordinates
            xM = (place.building(s).point(k).Xworld-minX)*scale;
            yM = (place.building(s).point(k).Yworld-minY)*scale;
            xTM = xM - mW/2;
            yTM = -yM + mH/2;
            if (k > 1)
                top_map = insertShape(top_map,'Line',[xMold yMold xM yM;xMold+1 yMold+1 xM+1 yM+1],'Color','red');
            end
            xMold = xM;
            yMold = yM;
            %calib.true_map_places.building(s).point(k) = [xTM,yTM];
        end
    end
end

figure(98)
imshow(top_map)
%self rotation
top_map(:,:) = flipud(top_map(:,:));
mWr = mW;
mHr = mH;
imshow(top_map)
rotation = input('Insert map counterclockwise angle rotation in degrees ([] = 0°) : ');
if (isempty(rotation))
    rotation = 0;
end
if (rotation ~= 0)
    top_map = imrotate(top_map,rotation);
    bg = ~imrotate(true([mH,mW,3]),rotation);
    top_map(bg&~imclearborder(bg)) = 255;
    sz = size(top_map);
    mHr = sz(1);
    mWr = sz(2);
    clf
end

calib.minX = minX;
calib.maxX = maxX;
calib.minY = minY;
calib.maxY = maxY;
calib.mW = mW;
calib.mH = mH;
calib.mHr = mHr;
calib.mWr = mWr;
calib.rot = rotation;
calib.map = top_map;
calib.scale = scale;

top_map = insertShape(top_map,'Rectangle',[0.65*mW 40 0.25*mW 0.01*mH],'Color',[0 0 0]);
top_map = insertShape(top_map,'FilledRectangle',[0.65*mW 40 0.25/4*mW 0.01*mH;0.775*mW 40 0.25/4*mW 0.01*mH],'Color',[0 0 0]);
top_map = insertText(top_map,[0.64*mW 20],'0','BoxOpacity',0);
top_map = insertText(top_map,[0.64*mW+0.25/4*mW 20],num2str(chop(0.25/4*mW/scale,2)),'BoxOpacity',0);
top_map = insertText(top_map,[0.64*mW+0.25/4*2*mW 20],num2str(chop(0.25/4*2*mW/scale,2)),'BoxOpacity',0);
top_map = insertText(top_map,[0.64*mW+0.25/4*3*mW 20],num2str(chop(0.25/4*3*mW/scale,2)),'BoxOpacity',0);
top_map = insertText(top_map,[0.64*mW+0.25/4*4*mW 20],num2str(chop(0.25/4*4*mW/scale,2)),'BoxOpacity',0);
top_map = insertText(top_map,[0.91*mW 35],'m','BoxOpacity',0);
imshow(top_map);
imwrite(top_map,[folder 'map'],'jpg');
calib.map = top_map;

save([folder 'calib_' videoName '.mat'],'calib');