clc

frame = read(v_obj,start_offset+280);
frame = single(frame)/255;
k = 240;
[fr_car,descr_car] = vl_sift(rgb2l(crop_mask(frame,blob(k).shape,blob(k).box)));

frame = read(v_obj,start_offset+706);
frame = single(frame)/255;
k = 700;
[fr_man1,descr_man1] = vl_sift(rgb2l(crop_mask(frame,blob(k).shape,blob(k).box)));

frame = read(v_obj,start_offset+746);
frame = single(frame)/255;
k = 740;
[fr_man2,descr_man2] = vl_sift(rgb2l(crop_mask(frame,blob(k).shape,blob(k).box)));

[matches,score] = vl_ubcmatch(descr_man2,descr_man1);
disp('----------------man2 vs man1')
score
disp(['score = ' num2str(median(score))])
[matches,score] = vl_ubcmatch(descr_car,descr_man1);
disp('----------------man1 vs car')
score
disp(['score = ' num2str(median(score))])
[matches,score] = vl_ubcmatch(descr_car,descr_man2);
disp('----------------man2 vs car')
score
disp(['score = ' num2str(median(score))])

%% car - intraclasse
threshCarCar = [];
carBlobsHist = blob(394).history;
carBlobs = carBlobsHist(find(carBlobsHist == 77,1,'first'):end);
carBlobsCons = carBlobs([1:5:length(carBlobs)]);
i = 0;
for k = carBlobsCons
    i = i + 1;
    framek = single(read(v_obj,start_offset+blob(k).time))/255;
    [fr_k,descr_k] = vl_sift(rgb2l(crop_mask(frame,blob(k).shape,blob(k).box)));
    if (i < length(carBlobsCons))
        j = carBlobsCons(i+1);
        framej = single(read(v_obj,start_offset+blob(j).time))/255;
        [fr_j,descr_j] = vl_sift(rgb2l(crop_mask(frame,blob(j).shape,blob(j).box)));
        [matches,score] = vl_ubcmatch(descr_k,descr_j);
        if (~isempty(matches))
            mediana = median(score);
            media = mean(score);
            min_score = min(score);
            max_score = max(score);
            minmax = (max_score-min_score)/2;
            cost = sum(1./score(score~=0));
            %cost2 = sum(1./(score.^2));
            threshCarCar(k,j,:) = [mediana media min_score max_score minmax cost];
        end
    end
end

%%
threshManMan = [];
manBlobsHist = blob(720).history;
manBlobs = manBlobsHist(find(manBlobsHist == 655,1,'first'):end);
manBlobsCons = manBlobs([1:1:length(manBlobs)]);
i = 0;
for k = manBlobsCons
    i = i + 1;
    framek = single(read(v_obj,start_offset+blob(k).time))/255;
    [fr_k,descr_k] = vl_sift(rgb2l(crop_mask(frame,blob(k).shape,blob(k).box)));
    if (i < length(manBlobsCons))
        j = manBlobsCons(i+1);
        framej = single(read(v_obj,start_offset+blob(j).time))/255;
        [fr_j,descr_j] = vl_sift(rgb2l(crop_mask(frame,blob(j).shape,blob(j).box)));
        [matches,score] = vl_ubcmatch(descr_k,descr_j);
        if (~isempty(matches))
            mediana = median(score);
            media = mean(score);
            min_score = min(score);
            max_score = max(score);
            minmax = (max_score-min_score)/2;
            cost = sum(1./score);
            %cost2 = sum(1./(score.^2));
            threshManMan(k,j,:) = [mediana media min_score max_score minmax cost];
        end
    end
end

threshManCar = [];
i = 0;
tot = length(carBlobsCons)*length(manBlobsCons);
for k = carBlobsCons
    framek = single(read(v_obj,start_offset+blob(k).time))/255;
    [fr_k,descr_k] = vl_sift(rgb2l(crop_mask(frame,blob(k).shape,blob(k).box)));
    for j = manBlobsCons
        framej = single(read(v_obj,start_offset+blob(j).time))/255;
        [fr_j,descr_j] = vl_sift(rgb2l(crop_mask(frame,blob(j).shape,blob(j).box)));
        [matches,score] = vl_ubcmatch(descr_k,descr_j);
        i = i + 1;
        if (mod(i,100) == 0)
            disp(['Completamento: ' num2str(100*i/tot) ' perc.'])
        end
        if (~isempty(matches))
            mediana = median(score);
            media = mean(score);
            min_score = min(score);
            max_score = max(score);
            minmax = (max_score-min_score)/2;
            cost = sum(1./score);
            %cost2 = sum(1./(score.^2));
            threshManCar(k,j,:) = [mediana media min_score max_score minmax cost];
        end
    end
end

save('sift_thresh_data','threshManCar','threshManMan','threshCarCar','v_obj','blob','start_offset')

%%
load 'sift_thresh_data'
%%
data_car_ind = threshCarCar(:,:,4);
data_car = find(data_car_ind ~= 0);
mediana_car = threshCarCar(:,:,1);
data_car_mediana = mediana_car(data_car);
media_car = threshCarCar(:,:,2);
data_car_media = media_car(data_car);
min_car = threshCarCar(:,:,3);
data_car_min = min_car(data_car);
max_car = threshCarCar(:,:,4);
data_car_max = max_car(data_car);
minmax_car = threshCarCar(:,:,5);
data_car_minmax = minmax_car(data_car);
cost_car = threshCarCar(:,:,6);
data_car_cost = cost_car(data_car);

data_man_ind = threshManMan(:,:,4);
data_man = find(data_man_ind ~= 0);
mediana_man = threshManMan(:,:,1);
data_man_mediana = mediana_man(data_man);
media_man = threshManMan(:,:,2);
data_man_media = media_man(data_man);
min_man = threshManMan(:,:,3);
data_man_min = min_man(data_man);
max_man = threshManMan(:,:,4);
data_man_max = max_man(data_man);
minmax_man = threshManMan(:,:,5);
data_man_minmax = minmax_man(data_man);
cost_man = threshManMan(:,:,6);
data_man_cost = cost_man(data_man);

data_mc_ind = threshManCar(:,:,4);
data_mc = find(data_mc_ind ~= 0);
mediana_mc = threshManCar(:,:,1);
data_mc_mediana = mediana_mc(data_mc);
media_mc = threshManCar(:,:,2);
data_mc_media = media_mc(data_mc);
min_mc = threshManCar(:,:,3);
data_mc_min = min_mc(data_mc);
max_mc = threshManCar(:,:,4);
data_mc_max = max_mc(data_mc);
minmax_mc = threshManCar(:,:,5);
data_mc_minmax = minmax_mc(data_mc);
cost_mc = threshManCar(:,:,6);
data_mc_cost = cost_mc(data_mc);

%%
figure(1)
clf
hold on
plot3(data_mc_mediana,data_mc_cost,data_mc_media,'bo','MarkerSize',8,'LineWidth',2)
hold on
plot3(data_man_mediana,data_man_cost,data_man_media,'go','MarkerSize',8,'LineWidth',2)
hold on
plot3(data_car_mediana,data_car_cost,data_car_media,'ro','MarkerSize',8,'LineWidth',2)
xlabel('mediana')
ylabel('cost')
zlabel('media')
%%
figure(2)
clf
hold on
h1 = plot(data_mc_cost,data_mc_media,'bo','MarkerSize',8,'LineWidth',2);
hold on
h2 = plot(data_man_cost,data_man_media,'go','MarkerSize',8,'LineWidth',2);
hold on
h3 = plot(data_car_cost,data_car_media,'ro','MarkerSize',8,'LineWidth',2);
xlabel('cost')
ylabel('media')
legend([h1 h2 h3],'car vs man','man vs man','car vs car')