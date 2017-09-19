function [] = GridPartition()
%[numHregions,numWregions,N,rH,rW] = GridPartition(numHregions,numWregions,H,W)
%Split image into a grid made by numHregions rows and numWregions columns
global numHregions numWregions N H W rH rW;
nHnew = numHregions;
while (mod(H,nHnew) ~= 0)
    nHnew = nHnew+1;
end
if (nHnew ~= numHregions)
    warning(['Rows different from inserted. Chosen ' num2str(nHnew)...
        ' instead of ' num2str(numHregions)])
    numHregions = nHnew;
end
nWnew = numWregions;
while (mod(W,nWnew) ~= 0)
    nWnew = nWnew+1;
end
if (nWnew ~= numWregions)
    warning(['Columns different from inserted. Chosen ' num2str(nWnew)...
        ' instead of ' num2str(numWregions)])
    numWregions = nWnew;
end
N = numHregions*numWregions;
rH = H/numHregions;
rW = W/numWregions;
end