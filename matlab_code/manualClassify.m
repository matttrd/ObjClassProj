global blob
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
%     mov5 = read(v_obj,time5);
%     box = blob(history(rnd_hist(2))).box;
%     img_blob5 = mov5(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,:);
%     mov6 = read(v_obj,time6);
%     box = blob(history(rnd_hist(3))).box;
%     img_blob6 = mov6(box(2):box(2)+box(4)-1,box(1):box(1)+box(3)-1,:);
    
    figure(20)
    clf
    subplot(141)
    imshow(img_blob1)
    subplot(142)
    imshow(img_blob2)
    title([num2str(name) ' (durata: ' num2str(stat(i).duration/fps)  ' s)'],...
        'FontSize',24)
    subplot(143)
    imshow(img_blob3)
    subplot(144)
    imshow(img_blob4)
%     subplot(235)
%     imshow(img_blob5)
%     subplot(236)
%     imshow(img_blob6)
    
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
save('output/stat','stat');

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
h = [];
for i = 1:length(stat)
    descr(i,:) = [norm1*mean(stat(i).areaDist) mean(stat(i).sol) ...
        mean(stat(i).ecc) norm2*abs(mean(stat(i).orient))];
    class = [class stat(i).class];
    switch (stat(i).class)
        case 1
            people = [people descr(i,:)];
        case 2
            cars = [cars descr(i,:)];
    end
    hold on
    h(i) = plot3(descr(i,1),descr(i,2),descr(i,3),'o','Color',classColor(stat(i).class,:),'MarkerSize',8,'LineWidth',2);
end
xlabel('Area x Dist','FontSize',16)
ylabel('Solidity','FontSize',16)
zlabel('Eccentricity','FontSize',16)
title('Descriptors of detected objects','FontSize',20)
grid on
legend([h(2),h(1)],'people','cars')
enabled = [1 2 3 4];
saveas(11,'SVMvectors')
%%
SVMtraining = libsvmtrain(class',descr(:,enabled),'-t 2');
save([folder 'SVMtraining'],'SVMtraining', 'descr') 
