function [neighborhood] = getNeighborhood(i,rows,columns)
%[neighborhood] = getNeighborhood(i,rows,columns)
%returns which are the neighborhood of actual region of index i, with an
%image split into rows by columns. Result is returned as struct
iW = mod(i,columns);            %column index of regions
iH = (i-iW)/columns+1;          %row index of regions
if (iW == 0)
    iW = columns;
    iH = iH-1;
end
if(iH ~= 1)
    neighborhood.north = (iH-2)*rows+iW;
end
if(iH ~= rows)
    neighborhood.south = iH*rows+iW;
end
if(iW ~= 1)
    neighborhood.west = (iH-1)*rows+iW-1;
end
if(iW ~= columns)
    neighborhood.east = (iH-1)*rows+iW+1;
end
end