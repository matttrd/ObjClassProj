function [MPV,MPM] = minimumPriority(image,max_level,min_level)
%[MPM] = minimumPriority(image,max_level,min_level)
%[MPM] = minimumPriority(image,max_level)
%[MPM] = minimumPriority(image)
%produces a minimum priority vector from a sample image, where the regions
%with pure green [0 255 0] will be treated as regions where the priority is
%the maximum allowed (max_level), and the others will be set as priority 0
%The image will be splitted into rows and columns.
global numHregions numWregions H W rH rW;
if (nargin < 3)
    min_level = 0;
end
if (nargin < 2)
    max_level = 5;
end
sample = imread([image '.jpg']);
sz = size(sample);
H = sz(1);
W = sz(2);
rH = H/numHregions;
rW = W/numWregions;
MPM = ones(numHregions,numWregions)*min_level;
edge = false;
threshold = 10;
for iH = 1:numHregions
    for iW = 1:numWregions
        for k = (iW-1)*rW+1:iW*rW
            for j = (iH-1)*rH+1:iH*rH
                %if the pixel (j,k) is green, then ends and the
                %corresponding region will remain at max priority
                if (sample(j,k,1) < threshold && sample(j,k,2) > 255-threshold...
                        && sample(j,k,3) < threshold)
                    edge = true;
                    MPM(iH,iW) = max_level;
                    break
                end
            end
            if (edge == true)
                edge = false;
                break
            end
        end
    end
end
MPV = zeros(1,numHregions*numWregions);
for i = 1:numHregions
    MPV((i-1)*numWregions+1:i*numWregions) = MPM(i,:);
end

