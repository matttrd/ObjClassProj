function [totalPath,color] = getPaths(k_start,k_end,blob)
% totalPath = getPaths(k_start,k_end)
%crea un cell array contenente i punti in coordinate immagine di una
%spezzata contenente il percorso effettuato dai blob da k_start a k_end
if (k_start > k_end)
    k_start = k_end;
end
for k = k_start:k_end
    path = blob(k).path;
    path2D = [];
    for j = 1:size(path,1)
        path2D = [path2D blob(k).path(j,:)];
    end
    if (size(path,1) == 1)
        path2D = [path2D path2D];
    end
    totalPath{k-k_start+1} = path2D;
    color(k-k_start+1,:) = blob(k).color;
end
end