function [mov,v_obj] = read_video(name,t_stop,t_start)
%[mov,v_obj] = READ_VIDEO(name,t_stop,t_start)
% legge un video da t_start [s] a t_stop [s] e produce un oggetto con le
% propietà e il video senza audio come vettore 4D

%create video object
v_obj = VideoReader(name);

%get video properties (number of frames can be wrong on compressed videos)
nFrames = v_obj.NumberOfFrames;
h =v_obj.Height;
w = v_obj.Width;
fps = v_obj.FrameRate;

fprintf('frames: %d width: %d  height: %d frame rate: f_rate\n',nFrames, w, h);

% matlab uses plenty of memory, use a limit on the number of frames
% according to the available resources to avoid out of memory errors or
% load block of frames
% if nFrames>200
%     nFrames=200;
% end

%fprintf('frames: %d width: %d  height: %d frame rate: f_rate\n',nFrames, w, h);

% mov: for color video is a matrix [nFrames h w 3];
% read: reads nframes from the video

if (nargin == 1)
    mov = read(v_obj,[1 nFrames]);
elseif (nargin == 2)
    mov = read(v_obj,[1 min(round(t_stop*fps),nFrames)]);
else
    mov = read(v_obj,[round(t_start*fps)+1 round(t_stop*fps)]);
end

%example of empty matrix to place computation output
% be careful of the data type (larger data types for summing up multiple
% frames)
%out = zeros( h,w,3,nFrames,'uint8');

%implay opens the video player
%implay(mov);
end
