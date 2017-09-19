function [close,dist] = areClose(k,j,blob)
% [close,dist] = ARECLOSE(k,j)
% verifica se i blob j e k sono vicini e restituisce un boolean e la
% distanza in metri percorsa se i blob appartengono a frame successivi
pos1 = blob(j).world_pos;
pos2 = blob(k).world_pos;
dist = norm(pos1-pos2);
if (dist <= 1.5)
    close = true;
else
    close = false;
end
end
