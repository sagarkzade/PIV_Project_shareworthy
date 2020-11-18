% Adjust data to span data range.
close all;
clc;
clear all;

X = imread('/Users/szade/Documents/PIV_project/PTV images/Img00010002.tif');
Y = imadjust(imread('/Users/szade/Documents/PIV_project/Img00010002.tif'));

X = imadjust(X);

imageInputSize = size(X);

% Threshold image - global threshold
BW = imbinarize(X);

% Open mask with disk
radius = 5;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imopen(BW, se);

% Create masked image.
maskedImage = X;
maskedImage(~BW) = 0;

% Find circles
[centers,radii,metric] = imfindcircles(maskedImage,[23 45],'ObjectPolarity','bright','Sensitivity',0.97);

