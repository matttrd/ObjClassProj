function [iH,iW] = getMatrixIndex(i)
%[iH,iW] = getMatrixIndex(i)
%returns matrix row and column indexes given sequential index number of a
%matrix of width numWregions
global numWregions;
iW = mod(i,numWregions);            %column index of regions
iH = (i-iW)/numWregions+1;          %row index of regions
if (iW == 0)
    iW = numWregions;
    iH = iH-1;
end
end