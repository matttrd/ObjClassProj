clc
global blob H W
blob = [];
dbg = [];
close all force
mov_out = VideoWriter('output/report.avi');
mov_out.FrameRate = fps;
open(mov_out);
k = 0;
globalName = 0;
numBlobsPrevFrame = 0;
foregroundDetector = vision.ForegroundDetector('NumGaussians', 5, ...
    'NumTrainingFrames', 150, 'LearningRate',0.0015);
tic
background = zeros(H,W,3);
dbg_fore = [];
dbg_frame = [];
bgtime = 100;
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
    frame_double = double(mov(:,:,:,mod(t-1,buffer*fps)+1))/255;
    if (t <= bgtime)
        background = background + frame_double/bgtime;
    end
    frame_filt = imfilter(frame_double,fspecial('gaussian',[9 9],0.5),'same');
    frame = single(frame_filt);
    result = frame_double;
    foreground = step(foregroundDetector,frame);
    map_act = calib.map;
    se = strel('square', 3);
    filteredForeground = imopen(foreground, se);
    filteredForeground = imfill(filteredForeground,'holes');
    shadow_foreground = repmat(filteredForeground*1,[1 1 3]);
    cc = bwconncomp(bwareaopen(filteredForeground,250));
    bbox = [];
    k_start = k;
    if (cc.NumObjects > 0 && t > bgtime)
        i = 1;
        while (i <= cc.NumObjects)
            shape = false(H,W);
            shape(cc.PixelIdxList{i}) = true;
            CoG = regionprops(shape,'Centroid');
            box = regionprops(shape,'BoundingBox');
            box = round(box.BoundingBox);
            xCoG = round(CoG.Centroid(1));
            CoGcolumn = shape(:,xCoG);
            bottom_y = find(CoGcolumn,1,'last');
            shape = shape(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1);            
            ground = [xCoG bottom_y];
            if (inpolygon(ground(1),ground(2),calib.watch(:,1),calib.watch(:,2)) == 1 ...
                && isInside(box))
                cropped_blob = crop_blob(frame_filt,box);
                removeShadow;
                if (valid_blob)
                    k = k + 1;
                    blob(k).Centroid = CoG.Centroid;
                    area = regionprops(shape,'Area');
                    blob(k).area = area.Area;
                    blob(k).box = box;
                    blob(k).shape = shape;
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
                    blob(k).color = [1 0 0];
                    bbox(k-k_start,:) = box;
                end
            end
            i = i + 1;
        end
    end
    k_end = k;
    for k = k_start+1:k_end
        % verifico se nei paraggi di ogni blob nell'istante prima c'era
        % solo un blob o no
        close_blobs = [];
        for j = k_start-numBlobsPrevFrame+1:k_start
            if (j > 0 && areClose(k,j,blob))
                close_blobs = [close_blobs j];
            end
        end
        [fr,descr] = vl_sift(rgb2gray(crop_blob(frame,blob(k).box)));
        descr = mask_sift(fr,descr,blob(k).shape);
        blob(k).sift = descr;
        color = [1 0 0];
        % se nel frame prima non c'erano blob vicini a quello attuale,
        % considero il blob come nuovo e non procedo oltre, altrimenti, se
        % ce n'era solo uno, matcho col precedente senza guardare i
        % descrittori, altrimenti cerco tra tutti i blob vicini quale sia
        % quello che matcha meglio quello attuale
        if (isempty(close_blobs) || (length(close_blobs) == 1 && ~blob(close_blobs).lost))
            globalName = globalName + 1;
            blob(k).name = globalName;
            blob(k).path = blob(k).ground;
        elseif (length(close_blobs) == 1 && blob(close_blobs).lost)
            blob(k).name = blob(close_blobs).name;
            blob(k).path = [blob(close_blobs).path;blob(k).ground];
            blob(k).history = [blob(close_blobs).history k];
            blob(close_blobs).lost = false;
            color = [150 222 209]/255;
            blob(k).color = color;
        else
            % qui confronto i descrittori del sift
            j = 1;
            best_score = 0;
            % cerco il primo blob che non sia già stato associato
            while (~blob(close_blobs(j)).lost)
                j = j + 1;
                if (j > length(close_blobs))
                    break;
                end
            end
            if (j <= length(close_blobs))
                best_match = close_blobs(j);
                sift_confr = blob(close_blobs(j)).sift;
                if (isempty(sift_confr) || isempty(blob(k).sift))
                    score = 0;
                else
                    [matches,score] = vl_ubcmatch(blob(k).sift,sift_confr);
                end
                best_score = performance(score);
                m = 1;
                for j = close_blobs(2:end)
                    % solo se il blob non risulta già associato posso fare data
                    % association, altrimenti 2 blob potrebbero avere la stessa
                    % history
                    m = m + 1;
                    if (blob(j).lost)
                        sift_confr = blob(j).sift;
                        if (isempty(sift_confr) || isempty(blob(k).sift))
                            score = 0;
                        else
                            [matches,score] = vl_ubcmatch(descr,sift_confr);
                        end
                        if (performance(score) > best_score)
                            best_score = performance(score);
                            best_match = j;
                        end
                    end
                end
            end
            if (best_score > 0.006)
                blob(k).name = blob(best_match).name;
                blob(k).path = [blob(best_match).path;blob(k).ground];
                blob(k).history = [blob(best_match).history k];
                blob(best_match).lost = false;
                color = [0 1 0];
                blob(k).color = color;
            else
                globalName = globalName + 1;
                blob(k).name = globalName;
                blob(k).path = blob(k).ground;
            end
        end
        map_act = insertShape(map_act,'Circle',[blob(k).map 4],'Color',[0 0.5 0]);
        map_act = insertText(map_act,blob(k).map,blob(k).name,'FontSize', 16,'BoxColor',[0 0.5 0]);
        result = insertObjectAnnotation(result, 'Rectangle', blob(k).box,num2str(blob(k).name), 'Color',color);        
    end
    totalPath = [];
    if (~isempty(blob))
        [totalPath,color] = getPaths(k_start+1,k_end,blob);
        result = insertShape(result,'Line',totalPath,'color',color);
    end
    numBlobsPrevFrame = k_end-k_start;
    k = k_end;
    bnID = '';
    for j = k_start+1:k_end
        bnID{j-k_start} = num2str(j);
    end
    if (k_start < k_end)
        blobs = insertObjectAnnotation(shadow_foreground, 'Rectangle', bbox, bnID, 'Color', 'green');
    else
        blobs = shadow_foreground;
    end
    report_obj = [blobs;result];
    %imwrite(blobs,['output/blobs/blobs' num2str(t,'%04d') '.jpg']);
    %imwrite(result,['output/video/result' num2str(t,'%04d') '.jpg']);
    Hrep = max(size(map_act,1),size(report_obj,1));
    Wrep = size(map_act,2)+size(report_obj,2);
    report = zeros(Hrep,Wrep,3);
    report(1:2*H,1:W,:) = report_obj;
    report(1:size(map_act,1),W+1:end,:) = double(map_act)/255;
    f = im2frame(report);
    writeVideo(mov_out,f);
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
tic
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
end
legend(name,'FontSize',16)
toc

%% classificazione manuale degli oggetti
%manualClassify
    
    
    
    
        