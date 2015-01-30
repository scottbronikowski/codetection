function slamtest()

addpath(genpath('~/codetection/EKF_monoSLAM_1pRANSAC'));

%%MODIFIED from:
%%~/codetection/EKF_monoSLAM_1pRANSAC/matlab_code/mono_slam.m
%-----------------------------------------------------------------------
% 1-point RANSAC EKF SLAM from a monocular sequence
%-----------------------------------------------------------------------

% Copyright (C) 2010 Javier Civera and J. M. M. Montiel
% Universidad de Zaragoza, Zaragoza, Spain.

% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation. Read http://www.gnu.org/copyleft/gpl.html for details

% If you use this code for academic work, please reference:
%   Javier Civera, Oscar G. Grasa, Andrew J. Davison, J. M. M. Montiel,
%   1-Point RANSAC for EKF Filtering: Application to Real-Time Structure from Motion and Visual Odometry,
%   to appear in Journal of Field Robotics, October 2010.

%-----------------------------------------------------------------------
% Authors:  Javier Civera -- jcivera@unizar.es 
%           J. M. M. Montiel -- josemari@unizar.es

% Robotics, Perception and Real Time Group
% Arag�n Institute of Engineering Research (I3A)
% Universidad de Zaragoza, 50018, Zaragoza, Spain
% Date   :  May 2010
%-----------------------------------------------------------------------

clear variables; close all;% clc;
rand('state',0); % rand('state',sum(100*clock));

%-----------------------------------------------------------------------
% Sequence, camera and filter tuning parameters, variable initialization
%-----------------------------------------------------------------------

% Camera calibration
cam = my_initialize_cam;

% Set plot windows
set_plots; %MIGHT NEED TO CHANGE THIS

% Sequence path and initial image
%sequencePath = '../sequences/ic/rawoutput';
fileName = '~/codetection/test-run-data/video_front.avi';
%initIm = 90;
initIm = 1;
vid = mmreader(fileName);
%lastIm = 2169;
lastIm = vid.NumberOfFrames;

% Initialize state vector and covariance
[x_k_k, p_k_k] = initialize_x_and_p;

% Initialize EKF filter
sigma_a = 0.007; % standar deviation for linear acceleration noise
sigma_alpha = 0.007; % standar deviation for angular acceleration noise
sigma_image_noise = 1.0; % standar deviation for measurement noise
filter = ekf_filter( x_k_k, p_k_k, sigma_a, sigma_alpha, sigma_image_noise, 'constant_velocity' );

% variables initialization
features_info = [];
trajectory = zeros( 7, lastIm - initIm );
% other
min_number_of_features_in_image = 25;
generate_random_6D_sphere;
measurements = []; predicted_measurements = [];

%---------------------------------------------------------------
% Main loop
%---------------------------------------------------------------

%im = takeImage( sequencePath, initIm );
im = mytakeImageFromAvi(vid,initIm);

for step=initIm+1:lastIm
    fprintf('Step %d\n', step);
    
    % Map management (adding and deleting features; and converting inverse depth to Euclidean)
    [ filter, features_info ] = my_map_management( filter, features_info, cam, im, min_number_of_features_in_image, step );
    %features_info
    
    % EKF prediction (state and measurement prediction)
    [ filter, features_info ] = ekf_prediction( filter, features_info );
    %features_info
    
    % Grab image
    %im = takeImage( sequencePath, step );
    im = mytakeImageFromAvi(vid,step);
    %size(im)
    %imshow(im)
    
    % Search for individually compatible matches
    features_info = search_IC_matches( filter, features_info, cam, im );
    %features_info
    
    % 1-Point RANSAC hypothesis and selection of low-innovation inliers
    features_info = ransac_hypotheses( filter, features_info, cam );
    
    % Partial update using low-innovation inliers
    filter = ekf_update_li_inliers( filter, features_info );
    
    % "Rescue" high-innovation inliers
    features_info = rescue_hi_inliers( filter, features_info, cam );
    
    % Partial update using high-innovation inliers
    filter = ekf_update_hi_inliers( filter, features_info );

    % Plots,
    plots; display( step );
    
    % Save images
    % saveas( figure_all, sprintf( '%s/image%04d.fig', directory_storage_name, step ), 'fig' );

end

% Mount a video from saved Matlab figures
% fig2avi;


end