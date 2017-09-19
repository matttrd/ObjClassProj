clear all
clc
close all force
run('Toolbox/vlfeat/toolbox/vl_setup')
warning('OFF','images:imshow:magnificationMustBeFitForDockedFigure')
warning('OFF','images:initSize:adjustingMag')
global H W blob calib;
folder = 'Video/PETS2000/';

buffer = 30;
time_start = 40;
time_start_test = 0;
time_training = 15;
time_test = 58;
videoName = 'training';
format = '.mp4';
v_obj = VideoReader([folder videoName format]);
fps = v_obj.FrameRate;
H = v_obj.Height;
W = v_obj.Width;
start_offset = time_start*fps;

norm1 = 2e-6;
norm2 = 1/90;

%singleCalibration;
load([folder 'calib_' videoName]);
disp('Inizializzazione terminata.')
save('init_data')
