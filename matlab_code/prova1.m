clear all
close all
clc
addpath 'Video/'
[mov,v_obj] = read_video('videotec.avi');
implay(mov)
H = v_obj.Height;
W = v_obj.Width;
fps = v_obj.FrameRate;
Tc = 1/fps;
T = size(mov,4);

%%
frame = mov(:,:,:,400);
img = rgb2gray(frame);

figure(1)
imshow(frame)
rect = getrect;
frame = insertShape(frame,'Rectangle',rect);
imshow(frame);

%%
obj = imcrop(img,rect);
bw = edge(obj,'canny',[0.01 0.1],3);%,thresh,sigma)
bw = bwareaopen(bw,5);
figure(2)
imshow(bw)

%%
intObj = integralImage(double(obj)/255);


%%