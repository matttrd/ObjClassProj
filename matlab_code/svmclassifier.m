

%%
stat = [blob.sol
   ];
figure(200);
hist(double(stat),50);

%% DESCRIPTORS

%width-height ratio
width = double(bbox(:,numObj + 1));
height = double(bbox(:,numObj + 2));

ratios = height./width;

%color uniformity

% HOG descriptors
frameGray = rgb2gray(frame);
HOGdescr = HOG(frameGray);

%area*distance descriptor
distances = [];
AdotD = area*distances;

% velocity descriptor
% to do


%% TRAINING PHASE
% http://pascallin.ecs.soton.ac.uk/challenges/VOC/voc2007/
% training set here http://pascal.inrialpes.fr/data/human/

SVMStructCar = svmtrain(TrainCar,Group,'Car',Value);
SVMStructPeople = svmtrain(TrainPeople,Group,'People',Value);

%% CLASSIFYING PHASE



%% RESULTS
