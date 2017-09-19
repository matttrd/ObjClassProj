function [reg] = getRegion()

global numHregions numWregions N H W rH rW;
[x,y] = ginput(1);
iW = floor(x/rW)+1;
iH = floor(y/rH)+1;
reg = (iH-1)*numWregions + iW;
disp(['Selected region is number ' num2str(reg) '   iH = ' num2str(iH) ', iW = ' num2str(iW)])
end

