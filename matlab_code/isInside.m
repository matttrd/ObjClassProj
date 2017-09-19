function inside = isInside(box)
% inside = isInside(box)
% verifca se il blob contenuto in box è completamente dentro all'immagine o
% meno
global H W
inside = true;
if (box(2) <= 5 || box(2)+box(4)-1 >= H-5 || box(1) <= 5 || box(1)+box(3)-1 >= W-5)
    inside = false;
end
end