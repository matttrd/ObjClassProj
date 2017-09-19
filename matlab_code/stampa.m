function [] = stampa(figura,nome)
%prende in ingresso un numero corrispondente alla figura e stampa in png a
%300 dpi nome.png di dimensioni lxh
figure(figura)
%h = figure(figura);
set(figura,'Units','normalized')
set(figura,'Position',[0 0 800 600])
nome = ['report/Immagini/' nome '.png'];
set(gcf,'PaperPositionMode','auto')
print('-dpng','-r300', nome)

%crop
imgCol = imread(nome);
img = rgb2gray(imgCol);
for k = 1:size(img,2)
    f = find(img(:,k) ~= 255);
    if (~isempty(f))
        break
    end
end
left = k-1;
for k = size(img,2):-1:1
    f = find(img(:,k) ~= 255);
    if (~isempty(f))
        break
    end
end
right = k+1;
for k = 1:size(img,1)
    f = find(img(k,:) ~= 255);
    if (~isempty(f))
        break
    end
end
top = k-1;
for k = size(img,1):-1:1
    f = find(img(k,:) ~= 255);
    if (~isempty(f))
        break
    end
end
bottom = k+1;
imgCol = imgCol(top:bottom,left:right,:);
imwrite(imgCol,nome)
end

