clc
global blobTest H W
load([folder 'SVMtraining'])
videoName = 'test';
format = '.avi';
videoTest = VideoReader([folder videoName format]);
fps = videoTest.FrameRate;
H = videoTest.Height;
W = videoTest.Width;
%%
foregroundDetector = vision.ForegroundDetector('NumGaussians', 5, ...
    'NumTrainingFrames', 150, 'LearningRate',0.001,'MinimumBackgroundRatio',0.7);
%singleCalibration;
load([folder 'calib_' videoName]);
disp('Inizializzazione video test terminata.')

%% test blob
blobTest = [];
close all force
mov_out = VideoWriter('output/report_test.avi');
mov_out.FrameRate = fps;
open(mov_out);
start_offset_test = time_start_test*fps;
k = 0;
globalName = 0;
numBlobsPrevFrame = 0;
background = zeros(H,W,3);
bgtime = 100;
tic
for t = 1:time_test*fps;
    if (mod(t,100) == 0)
        disp(['Frame ' num2str(t) ' processato (' num2str(100*t/(time_test*fps)) ' %).'])
    end
    % buffering video ogni 60 secondi
    if (mod(t,buffer*fps) == 1)
        disp('Buffering in corso...')
        time_left = min(buffer*fps,time_test*fps-t+1);
        mov = read(videoTest,[t+start_offset_test t+time_left-1+start_offset_test]);
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
    if cc.NumObjects > 0
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
                    blobTest(k).Centroid = CoG.Centroid;
                    area = regionprops(shape,'Area');
                    blobTest(k).area = area.Area;
                    blobTest(k).box = box;
                    blobTest(k).shape = shape;
                    sol = regionprops(shape,'Solidity');
                    blobTest(k).sol = sol.Solidity;
                    blobTest(k).ground = ground;
                    orient = regionprops(shape,'Orientation');
                    blobTest(k).orient = orient.Orientation;
                    x_world = get3Dcoord(calib.P,blobTest(k).ground)';
                    blobTest(k).world_pos = x_world;
                    blobTest(k).dist_cam = getDistanceFromCamera(calib,x_world);
                    AreaDist = blobTest(k).dist_cam*blobTest(k).area;
                    blobTest(k).areaDist = AreaDist;           
                    blobTest(k).map = getMapCoordinates(x_world(1:2),calib);
                    majAx = regionprops(shape,'MajorAxisLength');
                    minAx = regionprops(shape,'MinorAxisLength');
                    ecc = regionprops(shape,'Eccentricity');
                    per = regionprops(shape,'Perimeter');
                    blobTest(k).majAx = majAx.MajorAxisLength;
                    blobTest(k).minAx = minAx.MinorAxisLength;
                    blobTest(k).ecc = ecc.Eccentricity;
                    blobTest(k).per = per.Perimeter;
                    blobTest(k).time = t;
                    blobTest(k).index = i;
                    blobTest(k).history = k;
                    blobTest(k).lost = true;
                    descr = [norm1*blobTest(k).areaDist blobTest(k).sol blobTest(k).ecc...
                        norm2*abs(blobTest(k).orient)];
                    descr = descr(enabled);
                    type = libsvmpredict(1,descr,SVMtraining,'-q');
                    blobTest(k).descr = descr(enabled);
                    blobTest(k).instantType = type;
                    counter = [0 0];
                    counter(type) = 1;
                    blobTest(k).counter = counter;
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
            if (j > 0 && areClose(k,j,blobTest))
                close_blobs = [close_blobs j];
            end
        end
        [fr,descr] = vl_sift(rgb2gray(crop_mask(frame,blobTest(k).shape,blobTest(k).box)));
        blobTest(k).sift = descr;
        % se nel frame prima non c'erano blob vicini a quello attuale,
        % considero il blob come nuovo e non procedo oltre, altrimenti, se
        % ce n'era solo uno, matcho col precedente senza guardare i
        % descrittori, altrimenti cerco tra tutti i blob vicini quale sia
        % quello che matcha meglio quello attuale
        if (isempty(close_blobs) || (length(close_blobs) == 1 && ~blobTest(close_blobs).lost))
            globalName = globalName + 1;
            blobTest(k).globalName = globalName;
            setType;
            blobTest(k).name = [blobTest(k).className num2str(globalName)];
            blobTest(k).path = blobTest(k).ground;
        elseif (length(close_blobs) == 1 && blobTest(close_blobs).lost)
            setType;
            blobTest(k).name = [blobTest(k).className num2str(blobTest(close_blobs).globalName)];
            blobTest(k).globalName = blobTest(close_blobs).globalName;
            blobTest(k).path = [blobTest(close_blobs).path;blobTest(k).ground];
            blobTest(k).history = [blobTest(close_blobs).history k];
            blobTest(close_blobs).lost = false;
            blobTest(k).counter = blobTest(close_blobs).counter + blobTest(k).counter;           
        else
            % qui confronto i descrittori del sift
            j = 1;
            best_score = 0;
            % cerco il primo blob che non sia già stato associato
            while (~blobTest(close_blobs(j)).lost)
                j = j + 1;
                if (j > length(close_blobs))
                    break;
                end
            end
            if (j <= length(close_blobs))
                best_match = close_blobs(j);
                sift_confr = blobTest(close_blobs(j)).sift;
                if (isempty(sift_confr) || isempty(descr))
                    score = 0;
                else
                    [matches,score] = vl_ubcmatch(blobTest(k).sift,sift_confr);
                end
                best_score = performance(score);
                for j = close_blobs(2:end)
                    % solo se il blob non risulta già associato posso fare data
                    % association, altrimenti 2 blob potrebbero avere la stessa
                    % history
                    if (blobTest(j).lost)
                        sift_confr = blobTest(j).sift;
                        if (isempty(sift_confr) || isempty(descr))
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
                setType;            
                blobTest(k).name = [blobTest(k).className num2str(blobTest(best_match).globalName)];
                blobTest(k).globalName = blobTest(best_match).globalName;
                blobTest(k).path = [blobTest(best_match).path;blobTest(k).ground];
                blobTest(k).history = [blobTest(best_match).history k];
                blobTest(best_match).lost = false;
                blobTest(k).counter = blobTest(best_match).counter + blobTest(k).counter;
            else
                setType;
                globalName = globalName + 1;
                blobTest(k).globalName = globalName;            
                blobTest(k).name = [blobTest(k).className num2str(globalName)];
                blobTest(k).path = blobTest(k).ground;
            end
        end
        map_act = insertShape(map_act,'Circle',[blobTest(k).map 4],'Color',[0 0.5 0]);
        map_act = insertText(map_act,blobTest(k).map,blobTest(k).name,'FontSize', 16,'BoxColor',[0 0.5 0]);
        result = insertObjectAnnotation(result, 'Rectangle', blobTest(k).box,blobTest(k).name,'Color',blobTest(k).color);        
    end
    totalPath = [];
    if (~isempty(blobTest))
        [totalPath,color] = getPaths(k_start+1,k_end,blobTest);
        result = insertShape(result,'Line',totalPath,'color',color);
    end
    numBlobsPrevFrame = k_end-k_start;
    k = k_end;
    report_obj = [insertShape(shadow_foreground, 'Rectangle', bbox, 'Color', 'green');result];
    Hrep = max(size(map_act,1),size(report_obj,1));
    Wrep = size(map_act,2)+size(report_obj,2);
    report = zeros(Hrep,Wrep,3);
    report(1:2*H,1:W,:) = report_obj;
    %imwrite(map_act,['output/mapTest/map' num2str(t,'%04d') '.jpg']);
    %imwrite(result,['output/videoTest/result' num2str(t,'%04d') '.jpg']);
    report(1:size(map_act,1),W+1:end,:) = double(map_act)/255;
    f = im2frame(report);
    writeVideo(mov_out,f);
end
toc
close(mov_out);
h = mplay(['output/report_test.avi']);
set(findall(0,'tag','spcui_scope_framework'),'position',[0 0 1366 720]);
play(h.DataSource.Controls);

%% recupero statistiche blob
% Ogni blob contiene la history dei suoi precedenti in ordine temporale,
% riferiti alla struttura blob. Un blob non è perso solo se al frame dopo
% qualcuno lo associa nella sua history. Recupero quindi tutte le
% statistiche dei blob persi.
lost = find([blobTest.lost]);
statTest = [];
name = [];
j = 0;
figure(10)
clf
color = randi(255,1000,3)/255;
disp('------------ Classificazione oggetti ------------')
for k = lost
    history = blobTest(k).history;
    %solo se il blob è durato più di 10 frame lo tengo, altrimenti lo scarto
    if (length(history) >= 25)
        j = j + 1;
        % mi salvo in una struttura generica tutte le statistiche della
        % history
        statTest(j).blob = k;
        statTest(j).history = history;
        statTest(j).name = blobTest(k).name;
        statTest(j).time_lost = blobTest(k).time;
        statTest(j).duration = length(history);
        statTest(j).areaDist = [blobTest(history).areaDist];
        statTest(j).sol = [blobTest(history).sol];
        statTest(j).majAx = [blobTest(history).majAx];
        statTest(j).minAx = [blobTest(history).minAx];
        statTest(j).orient = [blobTest(history).orient];
        statTest(j).ecc = [blobTest(history).ecc];
        statTest(j).per = [blobTest(history).per];
        statTest(j).type = [blobTest(history).instantType];
        disp(['Oggetto classificato: ' num2str(statTest(j).name)])
        hold on
        name{j} = num2str(statTest(j).name);
        plot(statTest(j).areaDist,'Color',color(j,:),'LineWidth',2)
    end
    legend(name,'FontSize',16)
    xlabel('time')
    ylabel('areaDist')
end
save('output/statTest','statTest')
%%
figure(11)
descr = [];
for i = 1:length(statTest)
    descr(i,:) = [norm1*mean(statTest(i).areaDist) mean(statTest(i).sol) mean(statTest(i).ecc)];
    hold on
    plot3(descr(i,1),descr(i,2),descr(i,3),'x','Color',[0 0 0.5],'MarkerSize',8,'LineWidth',2,'DisplayName',statTest(i).name)
end

%%
figure(11)
hgload('SVMvectors');
i = 2;
ht = [];
for t = 1:statTest(i).duration
    %delete(h);
    hold on
    if t == 1
        j = 1;
    else
        j = t-1;
    end
    ht(t) = plot3(norm1*[statTest(i).areaDist(t) statTest(i).areaDist(j)],...
        [statTest(i).sol(t) statTest(i).sol(j)],...
        [statTest(i).ecc(t) statTest(i).ecc(j)],'-','Color',[0 0 0.6]+blobTest(statTest(i).history(t)).color,...
        'LineWidth',2,'DisplayName',statTest(i).name);
    pause(1/fps)   
end
legend([ht(1) ht(5)],'people classification','car classification')
