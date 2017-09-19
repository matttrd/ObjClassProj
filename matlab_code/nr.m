function nr(region)
%plots which region is "region" for 10 s
global numHregions numWregions N H W rH rW;
figure(2)
h = findobj(gcf,'type','image');
actualImage = get(h,'CData');
[iH,iW] = getMatrixIndex(region);
h = rectangle('Position',[(iW-1)*rW+1,(iH-1)*rH+1,rW,rH],'LineStyle','-');
set(h,'edgecolor',[243 188 0]/255,'LineWidth',2)
%pause(3)
%imshow(actualImage)
%drawBlobs();
end

