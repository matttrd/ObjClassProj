
%% initialization
clear all
close all force
clc
global numHregions numWregions N H W rH rW colors fps;
addpath 'Video/'
time_start = 18;
time_training = 10;
time_test = 8;
videoName = 'cuea2';
format = '.avi';
[mov,v_obj] = read_video([videoName format],time_training+time_test+time_start,time_start);
%implay(mov)
H = v_obj.Height;
W = v_obj.Width;
fps = v_obj.FrameRate;
normalSize = time_test*fps;
trainingVideo = mov(:,:,:,1:time_training*fps);
testVideo = mov(:,:,:,time_training*fps+1:end);
clear('mov')
frame_start = 1;
Tc = 1/fps;
frame_stop = frame_start+time_test*fps-1;
numHregions = 12;
numWregions = 15;;
full = true;
colors = [255 0 0; 0 255 0; 17 96 98; 3 192 60; 255 165 0];
%singleCalibration;
%load([folder 'cameras.mat']);

%% normal space creation
GridPartition;
Y = zeros(rH*rW,normalSize,N);
%i = index for all regions, counting them row after row
%t = index for time frames
tic
for t = 1:normalSize
    frame = rgb2l(trainingVideo(:,:,:,t));
    for i = 1:N
        yt = zeros(rH*rW,1);
        iW = mod(i,numWregions);            %column index of regions
        iH = (i-iW)/numWregions+1;          %row index of regions
        if (iW == 0)
            iW = numWregions;
            iH = iH-1;
        end
        %disp(['regione = ' num2str(i) '  iW = ' num2str(iW) '  iH = ' num2str(iH)])
        relColumn = 1;              %column index of single region        
        for j = (iW-1)*rW+1:iW*rW;  %column index of single region (ref. absolute image)
            yt((relColumn-1)*rH+1:relColumn*rH) = frame((iH-1)*rH+1:iH*rH,j);
            relColumn = relColumn + 1;
        end
        %yt = frame(:);         poco più efficiente
        Y(:,t,i) = yt;
    end
end
toc
disp(['Normal space creation complete.'])

%% computes SVD
clear('NSc');
tic
for i = N:-1:1
    [U0,S0,V0] = svd(Y(:,:,i),'econ');
    NSc(i).U = U0;
    NSc(i).S = S0;
    NSc(i).sv = wrev(eig(S0))';
end
toc
disp(['SVD computed.'])
clear 'Y' 'U0' 'S0' 'V0'
%% choice of the index of truncation r, according to the intensity principle
intensity = ones(1,N); % prende la quantità di dettagli pari a 1-intensity

intensity = 0.70*intensity;  %modifiche future in base alla priorità/staticità della regione
clear 'NS'
% Ur = zeros(rH*rW,min([normalSize rW*rH]),N,C);   %pre-allocation of Ur
% Sr = zeros(min([normalSize rW*rH]),min([normalSize rW*rH]),N,C);
%r = zeros(N,C);   %support vector needed to resize Ur
for i = N:-1:1
    I = 0;
    r_i = 0;
    while I < intensity(i)
        r_i = r_i+1;
        I = sum(NSc(i).sv(1:r_i))/sum(NSc(i).sv);
    end
    %disp(['truncation index region ' num2str(i,c) '   r = ' num2str(r_i)])
    NS(i).r = r_i;
    max_err(i) = NSc(i).sv(r_i+1);
    % creation of subspace reduced Ur
    NS(i).Ur = NSc(i).U(:,1:r_i);
end
disp(['Reduced normal space.'])
clear 'NSc'
%% choice of the error threshold
% we project the original frames of normal space into the reduced normal
% space, the we compute mean and variance of the projection error. We
% define the threshold as mean + 3*sigma, where sigma is the standard
% deviation
error_norm = zeros(normalSize,N);
err_threshold = zeros(1,N);
mean_err = zeros(1,N);
var_max = 0;
for t = normalSize-20:normalSize 
    frame = rgb2l(trainingVideo(:,:,:,t));
    for i = N:-1:1
        %extracts i-th region and vect it
        yt = zeros(rH*rW,1);
        iW = mod(i,numWregions);            %column index of regions
        iH = (i-iW)/numWregions+1;          %row index of regions
        if (iW == 0)
            iW = numWregions;
            iH = iH-1;
        end
        relColumn = 1;              %column index of single region
        for j = (iW-1)*rW+1:iW*rW;  %column index of single region (ref. absolute image)
            yt((relColumn-1)*rH+1:relColumn*rH) = frame((iH-1)*rH+1:iH*rH,j);
            relColumn = relColumn + 1;
        end
        error_norm(t,i) = norm(yt-NS(i).Ur*(NS(i).Ur'*yt));    %regions in rows
        mean_err(i) = mean(error_norm(:,i));
        var_err(i) = var(error_norm(:,i)-mean_err(i));
        if var_err(i) > var_max
            var_max = var_err(i); 
            sigma = sqrt(var_max);
        end    
        sigma = sqrt(var_err(i));
        err_threshold(i) = mean_err(i) + 2*sigma;
        err_threshold(i) = max_err(i);
    end
end

%% comparison with new frames
close all force
warning('OFF','images:initSize:adjustingMag')
clear('blobs');
clear('blob_hist');
global blobs;

max_priority = 5;
MPV = minimumPriority([videoName '_priority'],5,1);
PM = max_priority*ones(N,1); %actual priority matrix, initially set as its maximum
TM = ones(N,1);              %actual threshold variation coefficient
checks = zeros(N,1);         %time passed with no alarms
priority_time = zeros(N,1);  %time passed since last scan

frame_step = 5;       %n. of static frames to wait before lowering the priority
%Pt = [zeros(frame_stop-frame_start,N,C)];

clear('error_norm');
clear('error_proj');
clear('error_bin');
error_norm = zeros(frame_stop-frame_start+1,N);
error_bin = zeros(rH*rW,N);
img_track = zeros(H,W,3);
error_img = zeros(H,W,3);
threshold = 40;         %binary threshold default 80
mean_trend = zeros(frame_stop-frame_start+1,N);
region_alarms = zeros(1,N);
error_dc = mean_err;

mov = VideoWriter('report.avi');
mov.FrameRate = fps;
open(mov);
start_proc = tic;
descr = struct([]);
for t = 1:size(testVideo,4)-1
    %map_act = multi.global_map.map;
    ind_alarms = 1;
    frameCol = testVideo(:,:,:,t);
    frame = rgb2l(frameCol);
    for i = N:-1:1
        %if the priority isn't max, I will not scan every frame
        %if (PM(i) < max_priority && priority_time(i) < 2^(5-max_priority)-1)
        if (PM(i) < max_priority && priority_time(i) < 2^(max_priority-PM(i))-1)
            %does nothing because this isn't the turn to analyse the frame
            error_norm(t,i) = error_norm_old(t,i);
            priority_time(i) = priority_time(i) + 1;
        else
            priority_time(i) = 0;
            checks(i) = checks(i) + 1;  %otherwise I will check the error

            %extracts i-th region and vect it
            yt = zeros(rH*rW,1);
            [iH,iW] = getMatrixIndex(i);
            relColumn = 1;              %column index of single region
            for j = (iW-1)*rW+1:iW*rW;  %column index of single region (ref. absolute image)
                yt((relColumn-1)*rH+1:relColumn*rH) = frame((iH-1)*rH+1:iH*rH,j);
                relColumn = relColumn + 1;
            end

            err_pr = abs(yt-NS(i).Ur*(NS(i).Ur'*yt));
            error_proj(:,t,i) = err_pr;
            err_normalized = err_pr;
            projectors = NS(i).Ur'*yt;
            error_norm(t,i) = norm(yt-NS(i).Ur*projectors);    %regions in rows
            filtered_error(t,i) = error_norm(t,i)+TM(i)*(-error_dc(i) - err_threshold(i) +mean_err(i));
            filtered_error(t,i) = error_norm(t,i)-err_threshold(i);
            thr(t,i) = -(-error_dc(i) - err_threshold(i) +mean_err(i));
            error_bin(:,i) = zeros(rH*rW,1);
            if filtered_error(t,i) > 0
                %increases the priority of the region
                if (PM(i) >= max_priority-2)
                    PM(i) = max_priority;
                else
                    PM(i) = PM(i) + 2;
                end
                checks(i) = 0;
                error_bin(:,i) = im2bw(err_normalized,threshold/255);
                err_scale(:,i) = err_normalized;
                %triggers alarm only if the priority is max or 4 (filter fast false alarms)
                %in this way, for example, if the priority has changed from 0
                %to 2, it will not trigger an alarm immediately, but only if at
                %next check it will trigger an error. Many events that lasts
                %less than 8+2 frames and are isolated does not trigger a true alarm
                if (PM(i) >= max_priority-1)
                    region_alarms(ind_alarms) = i;
                    ind_alarms = ind_alarms + 1;
                    PM = increasePriority(PM(:),i,getNeighborhood(i,numHregions,numWregions));
                    if(t > 50)
                        TM(i) = 1;
                    end
                end
            else
                %no error
                if (checks(i) == frame_step)
                    %if the entire step is passed, lowers the priority until
                    %minimum priority is reached (not always 0)
                    if (PM(i) ~= MPV(i))
                        %PM(i) = PM(i)-1;       %TOGLIERE X ELIMINARE PRIORITÀ             
                        TM(i) = 1;
                    end
                    checks(i) = 0;  %resets the counter
                end
            end

            %error dc component update
            win = ceil(20*fps); %ampiezza finestratura in frame
            error_tmp.old(t,i) = 1/t*(error_norm(t,i)-error_dc(i));

            if t > win
                error_dc(i) = error_dc(i) + 1/t*(error_norm(t,i)-error_dc(i))...
                    -error_tmp.old(t-win+1,i); %evito il transitorio
            else
                error_dc(i) = error_dc(i) + 1/t*(error_norm(t,i)-error_dc(i));
            end

        end 
        mean_trend(t,i) = error_dc(i);
    end
    img_track = frameCol;
    img_edges = zeros(H,W);
    error_3D = imageRebuild(255*error_proj(:,t,:),numHregions,numWregions,rH);
%     figure(4)
%     mesh(error_3D)
%     axis([0 W 0 H 0 150])
%     drawnow
    
    %tracking
    regions = make_regions(region_alarms(1:ind_alarms-1));
    blobs = getBlobs(regions,error_bin);%,err_scale);
    if (blobs.objects > 0)      %METTERE >
        for k = blobs.objects:-1:1
%            [world,px] = getBottom(k);
%             img_track = insertShape(img_track,'Circle',[px 4],'Color',colors);
%             [top_pos,measure] = getGlobalCoordinates(world(1:2)',c);
%             blobs.object(k).global_map_pos = top_pos;
%             blobs.object(k).global_pos = measure.global(c,:);
%             blobs.object(k).camera_dist = measure.camera_distance(c);
%             bottom = getBottom(k,c);
%             dist = getDistanceFromCamera(multi.camera(c),bottom');
%             areaDist = blobs.object(k).area*dist;
%             blobs.object(k).areaDist = areaDist;
%             if (isCar(k))
%                 blobs.object(k).type = 'car ';
%             else
%                 blobs.object(k).type = 'person ';
%             end
%             if (top_pos(1) < 0)
%                 top_pos(1) = 0;
%             end
%             if (top_pos(1) > multi.global_map.mWr)
%                 top_pos(1) = multi.global_map.mWr;
%             end
%             if (top_pos(2) < 0)
%                 top_pos(2) = 0;
%             end
%             if (top_pos(2) > multi.global_map.mHr)
%                 top_pos(2) = multi.global_map.mHr;
%             end
%             %disp(['t = ' num2str(t) ' cam = ' num2str(c) ' obj' num2str(k) ' areaDist = ' num2str(blobs.object(k).areaDist)])
%             map_act = insertShape(map_act,'Circle',[top_pos 4],'Color',colors(1,:));
             %blobs.object(k).edges = edge(frame(blobs.object(k).bbox_large_yRange,blobs.object(k).bbox_large_xRange),'canny',[0.01 0.1],5);%,thresh,sigma)
%              crop_image = frame(blobs.object(k).bbox_large_yRange,blobs.object(k).bbox_large_xRange);
%              [dx,dy] = imgradientxy(crop_image);
%              blobs.object(k).edges = (dx.*dy);
              img_edges(blobs.object(k).bbox_yRange,blobs.object(k).bbox_xRange) = blobs.object(k).convexHull*1;
            iD = length(descr) + 1;
              descr(iD).ecc = blobs.object(k).ecc;
              descr(iD).sol = blobs.object(k).sol;
              descr(iD).max_l = blobs.object(k).max_l;
              descr(iD).min_l = blobs.object(k).min_l;
              descr(iD).or = blobs.object(k).or;
        end
    end
    img_track = drawBlobs(img_track); %MANCA IL TIPO DI OGGETTO
    error_img(:,:,1) = imageRebuild(255*error_bin,numHregions,numWregions,rH);
    error_img(:,:,2) = error_img(:,:,1);
    error_img(:,:,3) = error_img(:,:,1);

    % plots report
    % report = [[img_track; error_img] map_act];
    report = [error_img/255];
    figure(3)
    imshow(img_edges)
    drawnow
    f = im2frame(report);
    writeVideo(mov,f)
    if (mod(t,100) == 0)
        if full
            disp(['Frame ' num2str(t) ' processed (' num2str(chop(100*t,3)) '%)'])
        else
            com = input(['Frame ' num2str(t) ' processed. Process other frames? [ENTER = yes, other = no]'],'s');
            if (~isempty(com))
                break;
            end
        end
    end
    error_norm_old = error_norm;
end
time = toc(start_proc);
disp(['Projection completed. Time elapsed: ' num2str(time) ' s (' num2str(chop(t/time,3)) ' fps)'])
full = false;
close(mov);

%%
descr_cell = struct2cell(descr);
ecc = cell2mat(descr_cell(1,:));
sol = cell2mat(descr_cell(2,:));
max_l = cell2mat(descr_cell(3,:));
min_l = cell2mat(descr_cell(4,:));
or = cell2mat(descr_cell(5,:));
figure(4)
clf
hist(ecc)
figure(5)
clf
hist(sol)
figure(6)
clf
hist(abs(or))

%%
%h = mplay(report(:,:,:,1:t-frame_start+1),fps);
h = mplay(['report.avi']);
set(findall(0,'tag','spcui_scope_framework'),'position',[0 0 1366 720]);
play(h.DataSource.Controls);

%% makes video
%createVideo(report,[folder 'multicamera'])
%Conclusions