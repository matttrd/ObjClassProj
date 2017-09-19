clc
global blob
blob = [];
close all force
mov_out = VideoWriter('output/report.avi');
mov_out.FrameRate = fps;
open(mov_out);
start_offset = time_start*fps;
k = 0;
globalName = 0;
numBlobsPrevFrame = 0;
tic
for t = 1:time_training*fps;
    if (mod(t,100) == 0)
        disp(['Frame ' num2str(t) ' processato (' num2str(100*t/(time_training*fps)) ' %).'])
    end
    % buffering video ogni 60 secondi
    if (mod(t,buffer*fps) == 1)
        disp('Buffering in corso...')
        time_left = min(buffer*fps,time_training*fps-t+1);
        mov = read(v_obj,[t+start_offset t+time_left-1+start_offset]);
        disp('Caricamento completato.')
    end
    %frame = step(videoReader); % read the next video frame
    frame_orig = single(mov(:,:,:,mod(t-1,buffer*fps)+1))/255;
    frame = imfilter(frame_orig,fspecial('gaussian',[3 3],0.5),'same');
    result = frame_orig;
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
    k_start = k;
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
            if (inpolygon(ground(1),ground(2),calib.watch(:,1),calib.watch(:,2)) == 1 ...
                && isInside(box))
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
                blob(k).world_pos = x_world;
                blob(k).dist_cam = getDistanceFromCamera(calib,x_world);
                AreaDist = blob(k).dist_cam*blob(k).area;
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
                blob(k).history = k;
                blob(k).lost = true;
                blob(k).name = num2str(k);
            end
        end
    end
%     if (k >= 722)
%         keyboard
%     end
    k_end = k;
    for k = k_start+1:k_end
%         disp(['t = ' num2str(t) '. Verifico i blob da ' num2str(k_start+1) ' a '...
%             num2str(k_end) '. La finestra precedente era da ' num2str(k_start-numBlobsPrevFrame+1)...
%             ' a ' num2str(k_start)])
        % verifico se nei paraggi di ogni blob nell'istante prima c'era
        % solo un blob o no
%         close_blobs = [];
%         for j = k_start-numBlobsPrevFrame+1:k_start
%             if (j > 0 && areClose(k,j))
%                 close_blobs = [close_blobs j];
%             end
%         end
%         %close_blobs
%         [fr,descr] = vl_sift(rgb2gray(crop_mask(frame,blob(k).shape,blob(k).box)));
%         blob(k).sift = descr;
%         color = [1 0 0];
%         % se nel frame prima non c'erano blob vicini a quello attuale,
%         % considero il blob come nuovo e non procedo oltre, altrimenti, se
%         % ce n'era solo uno, matcho col precedente senza guardare i
%         % descrittori, altrimenti cerco tra tutti i blob vicini quale sia
%         % quello che matcha meglio quello attuale
%         if (isempty(close_blobs) || (length(close_blobs) == 1 && ~blob(close_blobs).lost))
%             globalName = globalName + 1;
%             blob(k).name = globalName;
%             blob(k).path = blob(k).ground;
%         elseif (length(close_blobs) == 1 && blob(close_blobs).lost)
%             blob(k).name = blob(close_blobs).name;
%             blob(k).path = [blob(close_blobs).path;blob(k).ground];
%             blob(k).history = [blob(close_blobs).history k];
%             %disp(['Associo ' num2str(k) ' a ' num2str(close_blobs) ' per vicinanza.'])
%             blob(close_blobs).lost = false;
%             color = [0 0 0.5];
%         else
%             % qui confronto i descrittori del sift
%             j = 1;
%             best_score = 0;
%             % cerco il primo blob che non sia già stato associato
%             while (~blob(close_blobs(j)).lost)
%                 j = j + 1;
%                 if (j > length(close_blobs))
%                     break;
%                 end
%             end
%             if (j <= length(close_blobs))
%                 best_match = close_blobs(j);
%                 [matches,score] = vl_ubcmatch(blob(k).sift,blob(close_blobs(j)).sift);
%                 best_score = median(score);
%                 for j = close_blobs(2:end)
%                     % solo se il blob non risulta già associato posso fare data
%                     % association, altrimenti 2 blob potrebbero avere la stessa
%                     % history
%                     if (blob(j).lost)
%                         [matches,score] = vl_ubcmatch(descr,blob(j).sift);
%                         if (median(score) > best_score)
%                             best_score = median(score);
%                             best_match = j;
%                         end
%                     end
%                 end
%             end
%             if (best_score > 0)
%                 blob(k).name = blob(best_match).name;
%                 blob(k).path = [blob(best_match).path;blob(k).ground];
%                 blob(k).history = [blob(best_match).history k];
%                 %disp(['Associo ' num2str(k) ' a ' num2str(best_match) ' per SIFT.'])
%                 blob(best_match).lost = false;
%                 color = [0 1 0];
%             else
%                 globalName = globalName + 1;
%                 blob(k).name = globalName;
%                 blob(k).path = blob(k).ground;
%                 %disp(['Score = ' num2str(best_score)])
%             end
%         end
        %se sono all'ultimo istante tutti i blob li metto come persi
%         if (t == time_training*fps)
%             blob(k).lost = true;
%         end
        map_act = insertShape(map_act,'Circle',[blob(k).map 4],'Color',[0 0.5 0]);
        map_act = insertText(map_act,blob(k).map,blob(k).name,'FontSize', 16,'BoxColor',[0 0.5 0]);
        result = insertObjectAnnotation(result, 'Rectangle', blob(k).box,num2str(blob(k).name), 'Color',color);        
    
%                 if (blob(k).sol > 0.915)
%                     color = [0 1 0];
% %                 elseif (AreaDist > 1.76e7)
% %                     color = [0 0 0.5];
%                 else
%                     color = [1 0 0];
%                 end
    end
%     totalPath = [];
%     if (~isempty(blob))
%         totalPath = getPaths(k_start+1,k_end);
%         result = insertShape(result,'Line',totalPath,'color','g');
%     end
    % numObj = size(bbox, 1);
    % result = insertText(result, [10 10], numObj, 'BoxOpacity', 1, ...
    %     'FontSize', 14);
    % figure; imshow(result); title('Detected Cars');
    numBlobsPrevFrame = k_end-k_start;
    k = k_end;
    report_obj = [insertShape(filteredForeground*1, 'Rectangle', bbox, 'Color', 'green');result];
    Hrep = max(size(map_act,1),size(report_obj,1));
    Wrep = size(map_act,2)+size(report_obj,2);
    report = zeros(Hrep,Wrep,3);
    report(1:2*H,1:W,:) = report_obj;
    report(1:size(map_act,1),W+1:end,:) = double(map_act)/255;
%     figure(1);
%     imshow(report);
%     drawnow
    f = im2frame(report);
    writeVideo(mov_out,f);
    %keyboard
end
toc
close(mov_out);
h = mplay(['output/report.avi']);
set(findall(0,'tag','spcui_scope_framework'),'position',[0 0 1366 720]);
play(h.DataSource.Controls);

%% recupero statistiche blob
% Ogni blob contiene la history dei suoi precedenti in ordine temporale,
% riferiti alla struttura blob. Un blob non è perso solo se al frame dopo
% qualcuno lo associa nella sua history. Recupero quindi tutte le
% statistiche dei blob persi.
lost = find([blob.lost]);
stat = [];
name = [];
j = 0;
figure(10)
clf
color = randi(255,1000,3)/255;
disp('------------ Classificazione oggetti ------------')
for k = lost
    history = blob(k).history;
    %solo se il blob è durato più di 10 frame lo tengo, altrimenti lo scarto
    if (length(history) >= 25)
        j = j + 1;
        % mi salvo in una struttura generica tutte le statistiche della
        % history
        stat(j).blob = k;
        stat(j).name = blob(k).name;
        stat(j).time_lost = blob(k).time;
        stat(j).duration = length(history);
        stat(j).areaDist = [blob(history).areaDist];
        stat(j).sol = [blob(history).sol];
        stat(j).majAx = [blob(history).majAx];
        stat(j).minAx = [blob(history).minAx];
        stat(j).orient = [blob(history).orient];
        stat(j).ecc = [blob(history).ecc];
        stat(j).per = [blob(history).per];
        disp(['Oggetto classificato: ' num2str(stat(j).name)])
        hold on
        name{j} = num2str(stat(j).name);
        plot(stat(j).areaDist,'Color',color(j,:),'LineWidth',2)
    end
    legend(name,'FontSize',16)
end

%% distinzione manuale tra oggetti
for i = 1:length(stat)
    history = blob(stat(i).blob).history;
    time1 = blob(history(1)).time + start_offset;
    time3 = blob(history(end)).time + start_offset;
    mid = round((length(history)-1)/2);
    time2 = blob(history(mid)).time + start_offset;
    rnd_hist = randi(length(history),1,3);
    time4 = blob(history(rnd_hist(1))).time + start_offset;
    time5 = blob(history(rnd_hist(2))).time + start_offset;
    time6 = blob(history(rnd_hist(3))).time + start_offset;
    
    name = stat(i).name;
    mov1 = read(v_obj,time1);
    box = blob(history(1)).box;
    img_blob1 = mov1(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,:);
    mov2 = read(v_obj,time2);
    box = blob(history(mid)).box;
    img_blob2 = mov2(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,:);
    mov3 = read(v_obj,time3);
    box = blob(history(end)).box;
    img_blob3 = mov3(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,:);
    mov4 = read(v_obj,time4);
    box = blob(history(rnd_hist(1))).box;
    img_blob4 = mov4(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,:);
    mov5 = read(v_obj,time5);
    box = blob(history(rnd_hist(2))).box;
    img_blob5 = mov5(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,:);
    mov6 = read(v_obj,time6);
    box = blob(history(rnd_hist(3))).box;
    img_blob6 = mov6(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,:);
    figure(20)
    clf
    subplot(231)
    imshow(img_blob1)
    subplot(232)
    imshow(img_blob2)
    title([num2str(name) ' (durata: ' num2str(stat(i).duration/fps)  ' s)'],...
        'FontSize',24)
    subplot(233)
    imshow(img_blob3)
    subplot(234)
    imshow(img_blob4)
    subplot(235)
    imshow(img_blob5)
    subplot(236)
    imshow(img_blob6)
    
    input_wait = waitforbuttonpress;
    if input_wait
        key = get(gcf,'CurrentCharacter');
        if (strcmp(key,'p'))
            stat(i).type = 'people';
            stat(i).class = 1;
        elseif (strcmp(key,'c'))
            stat(i).type = 'car';
            stat(i).class = 2;
        else
            stat(i).type = 'other';
            stat(i).class = 3;
        end
    end
end    
close(20)

%% elimino gli elementi classificati come 'altro'
good_stat = find([stat.class] ~= 3);
stat_old = stat;
stat = stat(good_stat);

%% creazione dei vettori dei descrittori
descr = [];
classColor = [0 0.5 0;1 0 0;0.3 0.3 0.3]; % verde = persone, rosso = macchine
figure(11)
clf
people = [];
cars = [];
class = [];
norm1 = 1e5;
for i = 1:length(stat)
    descr(i,:) = [mean(stat(i).areaDist) norm1*mean(stat(i).sol) norm1*mean(stat(i).ecc)];
    class = [class stat(i).class];
    switch (stat(i).class)
        case 1
            people = [people descr(i,:)];
        case 2
            cars = [cars descr(i,:)];
    end
    hold on
    plot3(descr(i,1),descr(i,2),descr(i,3),'o','Color',classColor(stat(i).class,:),'MarkerSize',8,'LineWidth',2)
end
xlabel('Area x Dist')
ylabel('solidity')
zlabel('eccentricity')
%legend(name,'FontSize',16)

%% creazione svm
class(class == 2) = -1;
SVMtraining = vl_svmtrain(descr,class);

    
    
    
    
    
    
    
        