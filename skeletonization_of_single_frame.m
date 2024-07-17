function [fiber_img,blur_img,BI,L,lzero] = skeletonization_of_single_frame(imgn,prmt,prmt_index)

%% Calculate the skeleton of an individual frame.

FilNum = prmt(prmt_index).FilNum;

thickness = prmt(prmt_index).thickness;
structsensitivity = prmt(prmt_index).structsensitivity * diff(getrangefromclass(imgn));

lnoise = prmt(prmt_index).lnoise;
lobject = prmt(prmt_index).lobject;
threshold = prmt(prmt_index).threshold;

sensitivity = prmt(prmt_index).sensitivity;
MinBranchLength = prmt(prmt_index).MinBranchLength;

lzero = max(lobject,ceil(5*lnoise)); % size of each edges where gaussian_blur set values to 0

% apply 2-D median filtering to remove the 'salt & pepper' noise (on top of the gaussian blur).
medfilt_imgn = medfilt2(gaussian_blur(imgn,lnoise,lobject,threshold));

% enanche fibers in the image with predefined thickness
fiber_img = fibermetric(medfilt_imgn,thickness,'StructureSensitivity',structsensitivity);
% % fiber_img = vesselness2D(medfilt_imgn,thickness,[1;1],structsensitivity,true);

% apply gaussian blur
blur_img = gaussian_blur(fiber_img,lnoise,lobject,threshold);
blur_img = blur_img(lzero+1:end-lzero,lzero+1:end-lzero);

% binarization and suppression of stray pixels
BI = imbinarize(blur_img,'adaptive','ForegroundPolarity','bright','Sensitivity',sensitivity);
BI = bwareafilt(BI,FilNum); % extract object based on area, where FilNum is the expected # of filaments
% BI = imfill(BI,'holes'); % fill the holes in the binary image of the filament (works better than bwmorph)

% smooth out the jags/irregularities along the boundary of the objects:
bnd = bwboundaries(BI,'noholes'); % find boundary coordinates of all objects in the FOV
% smooth the edges of each objects in the FOV, then recontruct a binary image for each objects
for i = 1 % This is for parameters update, so there is only ONE interesting filament!
    clear xc yc
    xc = smooth(bnd{i}(:,1),1);
    yc = smooth(bnd{i}(:,2),1);
    s{i} = transpose(poly2mask(xc,yc,size(imgn,2)-2*lzero,size(imgn,1)-2*lzero));
end
% sum all objects, with smoothed edges, to recontruct the original binary image
BI = logical(sum(cat(3,s{:}),3));
% skeletonization
skel = bwskel(BI,'MinBranchLength',MinBranchLength);
% find the connected part of the skeletonization image
CC = bwconncomp(skel);
% label each filament with a different number
L = labelmatrix(CC);