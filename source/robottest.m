function [imgs,...
          sentence,...
          frame_times,...
          positions,...
          origboxes,...
          new_boxes,...
          frame_positions] ...
    = robottest(datapath)

%foo = make_transform_3d(pi/2, 0, pi, 1, 2, 3)

addpath(genpath('~/codetection/forests_edges_boxes'));
addpath('~/codetection/');

%load images from video_front.avi
vid = mmreader([datapath '/video_front.avi']);
h = vid.Height;
w = vid.Width;
d = vid.BitsPerPixel/8;
nFrames = vid.NumberOfFrames;
imgs = zeros(h,w,d,nFrames,'uint8');
for i = 1:nFrames
    imgs(:,:,:,i) = read(vid,i);
end

%load sentence from sentence.txt
fileID = fopen([datapath '/sentence.txt'],'r');
sentence = textscan(fileID, '%q');
fclose(fileID);

%load frame timing data from camera_front.txt
fileID = fopen([datapath '/camera_front.txt'],'r');
for i = 1:2 %drop 1st 2 lines (header data)
    fgetl(fileID);
end
tline = fgetl(fileID);
timing = zeros(1,2);
i = 1;
while (tline(19) ~= ' ') %ischar(tline)
    timing(i,:) = sscanf(tline,'%f:%d',[1,2]);
    i = i + 1;
    tline = fgetl(fileID);
end
fclose(fileID);
frame_times = timing(:,1);

%load position estimates from imu-log.txt (or imu-log-with-estimates.txt)
if exist([datapath '/imu-log-with-estimates.txt'], 'file') == 2  
    fileID = fopen([datapath '/imu-log-with-estimates.txt'],'r');
else
    fileID = fopen([datapath '/imu-log.txt'],'r');
end
tline = fgetl(fileID);
positions = zeros(1,4); %position is [time, x, y, theta]
i = 1; prev_time = 0.0;
while ischar(tline)
    if (tline(1) == 'E') %we have an estimate
        positions(i,1) = prev_time(1);
        positions(i,2:4) = sscanf(tline,'ESTIMATE:X:%f:Y:%f:THETA:%f',...
                                  [1,3]);
        i = i + 1;
    elseif (tline(1) == '1') % we have a time
        [prev_time,~] = sscanf(tline,'%f:%s');
    end
    tline = fgetl(fileID); %get new line and start again
end
fclose(fileID);

%match frames with positions by time
frame_positions = zeros(length(frame_times),5); 
    %each row is [frame_time, pos_time, x, y, theta]
frame_positions(:,1) = frame_times;
for i = 1:length(frame_times)
    temp = find(positions(:,1) < frame_times(i));
    idx = temp(end);
    frame_positions(i,2:5) = positions(idx,:);
end

%get proposals (edgeBoxesOut??)
addpath(genpath('sentence-codetection'));


%TEST with a single frame

%first do original scoring
imnum = 18;
top_k = 100;
frame = imgs(:,:,:,imnum);
[h,w,~] = size(frame);
%frame = imread('../training-videos/0-018.png');
origboxes = edgeBoxesOut(frame,top_k,5);
maxscore = max(origboxes(:,5));
boxes_to_plot = 20;
colors = distinguishable_colors(10*boxes_to_plot);
figure();
imshow(frame); hold all;
rectangle('Position',[1 440 w h-440],'FaceColor','white','EdgeColor','white');
baseheight = 450;
for i = 1:boxes_to_plot
    rectangle('Position',[origboxes(i,1) origboxes(i,2) origboxes(i,3) ...
        origboxes(i,4)],'LineWidth',2,'EdgeColor',...
        (origboxes(i,5)/maxscore)*colors(i,:));
    if (i > 80)
        text((i-80)*15, baseheight+30, num2str(i),'Color',...
            (origboxes(i,5)/maxscore)*colors(i,:));
    elseif (i > 40)
        text((i-40)*15, baseheight+15, num2str(i),'Color',...
            (origboxes(i,5)/maxscore)*colors(i,:));
    else
        text(i*15, baseheight, num2str(i),'Color',...
            (origboxes(i,5)/maxscore)*colors(i,:));
    end
end
title(['Original boxes, ',num2str(length(origboxes)),' boxes total']);
axis image;
hold off;

%then take boxes and find xy locations for each based on projection, then
%reject boxes that are out of bounds
pose = frame_positions(imnum,3:5); %[x y theta] m and rad
cam_offset = [-0.03 0.16 -0.2]; %estimated measurement, in m
boundary = [-3 3.05 -2.62 3.93]; %[x1 x2 y1 y2] in m
%camera calibration data
cam_k = [7.2434508362823397e+02 0.0 3.1232994017160644e+02;...
        0.0 7.2412307134397406e+02 2.0310961045807585e+02;...
        0.0 0.0 1.0]; %not sure of units here
new_boxes = zeros(top_k, 7);
nb_idx = 1;
for i = 1:top_k
    my_point = [(origboxes(i,1)+(origboxes(i,3)/2)) ...
                (origboxes(i,2)+origboxes(i,4))];
    %assume box is on ground (height = 0)
    loc = pixel_and_height_to_world(my_point,0,cam_k,pose,cam_offset);
    if ((~isnan(loc(1))) &&...
        (loc(1) >= boundary(1)) &&...
        (loc(1) <= boundary(2)) &&...
        (loc(2) >= boundary(3)) &&...
        (loc(2) <= boundary(4)))
        new_boxes(nb_idx,:) = [origboxes(i,:),loc(1),loc(2)];
        nb_idx = nb_idx + 1;
    end
end % for i
new_boxes = new_boxes(1:(nb_idx-1),:);
figure();
hold on;
title('floorplan');
plot(new_boxes(:,6),new_boxes(:,7),'o');
hold off;

figure();
imshow(frame); hold all;
rectangle('Position',[1 440 w h-440],'FaceColor','white','EdgeColor','white');
baseheight = 450;
maxscore = max(new_boxes(:,5));
for i = 1:length(new_boxes)
    rectangle('Position',[new_boxes(i,1) new_boxes(i,2) new_boxes(i,3) ...
        new_boxes(i,4)],'LineWidth',2,'EdgeColor',...
        (new_boxes(i,5)/maxscore)*colors(i,:));
    if (i > 80)
        text((i-80)*15, baseheight+30, num2str(i),'Color',...
            (new_boxes(i,5)/maxscore)*colors(i,:));
    elseif (i > 40)
        text((i-40)*15, baseheight+15, num2str(i),'Color',...
            (new_boxes(i,5)/maxscore)*colors(i,:));
    else
        text(i*15, baseheight, num2str(i),'Color',...
            (new_boxes(i,5)/maxscore)*colors(i,:));
    end
end
title(['New boxes, ',num2str(length(new_boxes)),' boxes total']);
axis image;
hold off;

% %%%%TESTING with just 2 images (temporally adjacent with cone prominent)
% frames = imgs(:,:,:,21:22);
% [bboxes, simi] = proposals_and_similarity(10,frames);





%convert pixels to locations


end

%probably need some helper functions down here
function rotmat = rotation3dx(a) %roll
    rotmat = [1,0,0,0;...
              0,cos(a),-sin(a),0;...
              0,sin(a),cos(a),0;...
              0,0,0,1];
end

function rotmat = rotation3dy(a) %pitch
    rotmat = [cos(a),0,sin(a),0;...
              0,1,0,0;...
              -sin(a),0,cos(a),0;...
              0,0,0,1];
end

function rotmat = rotation3dz(a) %yaw
    rotmat = [cos(a),-sin(a),0,0;...
              sin(a),cos(a),0,0;...
              0,0,1,0;...
              0,0,0,1];
end

function transmat = translation3d(x,y,z)
    transmat = [1,0,0,x;...
                0,1,0,y;...
                0,0,1,z;...
                0,0,0,1];
end

function trans = make_transform_3d(theta,phi,psi,x,y,z)
    transmat = translation3d(x,y,z);
    zrot = rotation3dz(theta);
    yrot = rotation3dy(phi);
    xrot = rotation3dx(psi);
    trans = transmat * zrot * yrot *xrot;
end

function world_to_cam = robot_pose_to_world__camera_txf(pose, cam_offset)
    x = cam_offset(1); y = cam_offset(2); z = cam_offset(3);
    trans1 = translation3d(x,y,z);
    trans2 = make_transform_3d((pose(3) - (pi/2)),0,-pi/2,...
                               pose(1), pose(2), 0);
    world_to_cam = trans1/trans2;                               
end 

function h = point_to_homogeneous(p)
    h = horzcat(p,1);
end

function p = homogeneous_to_point(h)
    p = h(1:(length(h)-1));
end

function p = transform_point_3d(mat, point)
    h = point_to_homogeneous(point);
    temp = mat*h';
    p = homogeneous_to_point(temp);
end

function point = pixel_and_height_to_world(pix, height, cam_k, pose, cam_offset)
    world_to_cam = robot_pose_to_world__camera_txf(pose,cam_offset);
    cam_world = transform_point_3d(inv(world_to_cam),[0,0,0]);
    fx = cam_k(1,1); fy = cam_k(2,2);
    cx = cam_k(1,3); cy = cam_k(2,3);
    px = (pix(1)-cx)/fx;
    py = (pix(2)-cy)/fy;
    pixel_world = transform_point_3d(inv(world_to_cam),[px,py,1]);
    dxyz = pixel_world - cam_world;
    if (dxyz(3) > 0)
        point = [NaN, NaN];
    else
        l = (height - cam_world(3))/dxyz(3);
        point = cam_world + dxyz*l;
    end
end 