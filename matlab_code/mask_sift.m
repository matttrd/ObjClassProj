function descr_new = mask_sift(fr,descr,shape)
% descr = MASK_SIFT(fr,descr,shape)
points = round(fr([1 2],:));
descr_new = [];
for i = 1:size(points,2)
    if (shape(points(2,i),points(1,i)))
        descr_new = [descr_new descr(:,i)];
    end
end
end
