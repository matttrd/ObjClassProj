% clear all
clc
close all force
global blob H W;
% addpath 'Video/'
folder = 'Video/Parcheggio/';

videoReader = vision.VideoFileReader([folder 'parcheggio1.avi']);
frame = step(videoReader);
H = size(frame,1);
W = size(frame,2);

time_start = 21;
time_training = 25;
time_test = 8;
videoName = 'parcheggio1';
format = '.avi';
[mov,v_obj] = read_video([folder videoName format],time_training+time_start,time_start);
H = v_obj.Height;
W = v_obj.Width;
fps = v_obj.FrameRate;
%fps = 25;

foregroundDetector = vision.ForegroundDetector('NumGaussians', 5, ...
    'NumTrainingFrames', 50, 'LearningRate',0.00001);
% for t = 1:time_start*fps-1;
%     step(videoReader);
% end
%singleCalibration;
load([folder 'calib']);
%%
close all force
clear 'blob';
mov_out = VideoWriter('report.avi');
mov_out.FrameRate = fps;
open(mov_out);
k = 0;
background = sum(double(mov(:,:,:,1:30))/255,4)/30;
background_Ycbcr  = double(rgb2ycbcr(background));

tic
for t = 2:time_training*fps;
    %frame = step(videoReader); % read the next video frame
    frame = double(mov(:,:,:,t))/255;
    result = frame;
    foreground = step(foregroundDetector,frame);
    map_act = calib.map;
    se = strel('square', 3);
    filteredForeground = imopen(foreground, se);
    filteredForeground = imfill(filteredForeground,'holes');
%     blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
%     'AreaOutputPort', true, 'CentroidOutputPort',true, 'MajorAxisLengthOutputPort',...
%         true,'MinorAxisLengthOutputPort',true,'OrientationOutputPort',true,...
%     'EccentricityOutputPort',true,'PerimeterOutputPort',true,'MinimumBlobArea', 150,...
%     'ExcludeBorderBlobs',false);
%     [area,centroid,bbox,majAx,minAx,or,ecc,per] = step(blobAnalysis, filteredForeground);     result = frame;
    cc = bwconncomp(bwareaopen(filteredForeground,150));
    bbox = [];
    if cc.NumObjects > 0
        bbox = zeros(cc.NumObjects,4);
        for i = 1:cc.NumObjects;
            shape = false(H,W);
            shape(cc.PixelIdxList{i}) = true;
            CoG = regionprops(shape,'Centroid');
            box = regionprops(shape,'BoundingBox');
            box = round(box.BoundingBox);
            shape = shape(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1);
            bbox(i,:) = box;
            ground = CoG.Centroid + double([0 box(4)/2]);
            if (inpolygon(ground(1),ground(2),calib.watch(:,1),calib.watch(:,2)) == 1)
            if ~isempty(box)    
                frameBlobYCbCr = rgb2ycbcr(frame(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,:));   
                frameBlob_Y = frameBlobYCbCr(:,:,1);
                frameBlob_Cb = frameBlobYCbCr(:,:,2);
                frameBlob_Cr = frameBlobYCbCr(:,:,3);
                fore_Y = frameBlob_Y.*shape;
                fore_Cb = frameBlob_Cb.*shape;
                fore_Cr = frameBlob_Cr.*shape;
                back_Y = background_Ycbcr(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,1);
                back_Cr = background_Ycbcr(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,2);
                back_Cb = background_Ycbcr(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,3);
                backBlob_Y = back_Y.*shape;
                backBlob_Cb = back_Cb.*shape;
                backBlob_Cr = back_Cr.*shape;
                diff_Y = fore_Y - backBlob_Y;
                diff_Cb = fore_Cb - backBlob_Cb;
                diff_Cr = fore_Cr - backBlob_Cr;

                rateCb = (fore_Cb + 1e-7)./(backBlob_Cb + 1e-7);
                rateCr = (fore_Cb + 1e-7)./(backBlob_Cb + 1e-7);
                shadows = logical(abs(diff_Y) > 10*abs(diff_Cb) & abs(diff_Y) > 10*abs(diff_Cb));
                Cb_shadow = (abs(rateCb).*shadows < 1.1) & (abs(rateCb).*shadows > .9);
                Cr_shadow = (abs(rateCr).*shadows < 1.1) & (abs(rateCr).*shadows > .9);
                shadows = shadows.*Cb_shadow.*Cr_shadow;
                shape = medfilt2(shape - shadows, [7 7]);
                shape = bwareaopen(shape,150);
                shape = imfill(shape,'holes');
                filteredForeground(find(shadows > 0)) = 0;
                box = regionprops(shape,'BoundingBox');
                if numel(box) > 1
                     box = box(1).BoundingBox;
%                      bbox(i,:) = box;
                     CoG = regionprops(shape,'Centroid');
                else
                    box = [box.BoundingBox];
%                     bbox(i,:) = box;
                end
            end
                k = k + 1;
                blob(k).Centroid = CoG.Centroid;
                area = regionprops(shape,'Area');
                blob(k).area = area.Area;
                blob(k).box = box;
                blob(k).shape = shape;
                convexArea = regionprops(shape,'ConvexArea');
                convexArea = max([convexArea.ConvexArea]);
                sol = regionprops(shape,'Solidity');
                blob(k).sol = sol.Solidity;
                blob(k).ground = ground;
                x_world = get3Dcoord(calib.P,blob(k).ground)';
                blob(k).dist_cam = getDistanceFromCamera(calib,x_world);
                AreaDist = blob(k).dist_cam^2*blob(k).area;
                blob(k).areaDist = AreaDist;           
                blob(k).map = getMapCoordinates(x_world(1:2),calib);
                majAx = regionprops(shape,'MajorAxisLength');
                minAx = regionprops(shape,'MinorAxisLength');
                orient = regionprops(shape,'Orientation');
                ecc = regionprops(shape,'Eccentricity');
                per = regionprops(shape,'Perimeter');
                blob(k).majAx = majAx.MajorAxisLength;
                blob(k).minAx = minAx.MinorAxisLength;
                blob(k).orient = orient.Orientation;
                blob(k).ecc = ecc.Eccentricity;
                blob(k).per = per.Perimeter;
                blob(k).time = t;
                blob(k).index = i;

                if (blob(k).sol > 0.915)
                    color = [0 1 0];
%                 elseif (AreaDist > 1.76e7)
%                     color = [0 0 0.5];
                else
                    color = [1 0 0];
                end
                map_act = insertShape(map_act,'Circle',[blob(k).map 4],'Color',[0 0.5 0]);
                map_act = insertText(map_act,blob(k).map,num2str(i),'FontSize', 16,'BoxColor',[0 0.5 0]);
%                 if ~isempty(box)    
                result = insertObjectAnnotation(result, 'Rectangle', box,num2str(i), 'Color',color);        
%                 end
            end
        end
        % numObj = size(bbox, 1);
        % result = insertText(result, [10 10], numObj, 'BoxOpacity', 1, ...
        %     'FontSize', 14);
        % figure; imshow(result); title('Detected Cars');
    end
    report_obj = [insertShape(filteredForeground*1, 'Rectangle', box, 'Color', 'green');result];
    Hrep = max(size(map_act,1),size(report_obj,1));
    Wrep = size(map_act,2)+size(report_obj,2);
    report = zeros(Hrep,Wrep,3);
    report(1:2*H,1:W,:) = report_obj;
    report(1:size(map_act,1),W+1:end,:) = double(map_act)/255;
%     figure(1);
%     imshow(report);
%     title('Clean Foreground');
    f = im2frame(report);
    writeVideo(mov_out,f);

end
toc
close(mov_out);
h = mplay(['report.avi']);
set(findall(0,'tag','spcui_scope_framework'),'position',[0 0 1366 720]);
play(h.DataSource.Controls);

%%
stat = [blob.sol];
figure(200);
hist(double(stat),50);

%% DESCRIPTORS

%width-height ratio
width = double(bbox(:,numObj + 1));
height = double(bbox(:,numObj + 2));

ratios = height./width;

%color uniformity

% HOG descriptors
frameGray = rgb2gray(frame);
HOGdescr = HOG(frameGray);

%area*distance descriptor
distances = [];
AdotD = area*distances;

% velocity descriptor
% to do


%% TRAINING PHASE
% http://pascallin.ecs.soton.ac.uk/challenges/VOC/voc2007/
% training set here http://pascal.inrialpes.fr/data/human/

SVMStructCar = svmtrain(TrainCar,Group,'Car',Value);
SVMStructPeople = svmtrain(TrainPeople,Group,'People',Value);

%% CLASSIFYING PHASE



%% RESULTS
