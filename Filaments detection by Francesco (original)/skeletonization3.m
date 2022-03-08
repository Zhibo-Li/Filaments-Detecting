function [fiber_img,blur_img,BI,skel,L,curr_img,ROI] = skeletonization3(pathintif,lzero,imi,imspace,imtot,...
    thickness,structsens,lnoise,lobject,threshold,sensitivity,MinBranchLength,FilNum)

%% retrieve the ROI in the image stack and the edge thickness
% first read an image and select a ROI for all the image stack
ROI = size(imread(pathintif,1));

%% skeletonization of the image stack

% define & resize a skeletonization array, due to gaussian_blur function
skel=zeros(ROI(1)-2*lzero,ROI(2)-2*lzero, length(imi : imspace : imtot));
L = zeros(ROI(1)-2*lzero,ROI(2)-2*lzero, length(imi : imspace : imtot));
curr_img = zeros(1,length(imi : imspace : imtot));
% % % skel=zeros(ROI(1),ROI(2), length(imi : imspace : imtot)); 

cnt=1;
for j = imi : imspace : imtot
    
imgn = imread(pathintif,j); 

% enanche fibers in the image with predefined thickness
fiber_img = fibermetric(imgn,thickness,'StructureSensitivity',structsens);
     
% apply gaussian blur
blur_img = gaussian_blur(fiber_img,lnoise,lobject,threshold);
blur_img = blur_img(lzero+1:end-lzero,lzero+1:end-lzero);

% binarization and suppression of stray pixels
BI = imbinarize(blur_img,'adaptive','ForegroundPolarity','bright','Sensitivity',sensitivity);
BI = bwareafilt(BI,FilNum); % extract object based on area, where FilNum is the expected # of filaments
% BI = imfill(BI,'holes'); % fill the holes in the binary image of the filament (works better than bwmorph)

% re-apply gaussian blur to the binary image
% BI = logical(gaussian_blur(double(BI),3,14,0.1));

%% smooth out the jags/irregularities along the boundary of the objects:

bnd = bwboundaries(BI,'noholes'); % find boundary coordinates of all objects in the FOV
% smooth the edges of each objects in the FOV, then recontruct a binary image for each objects 
 for i = 1 : FilNum
clear xc yc
xc = smooth(bnd{i}(:,1),1);
yc = smooth(bnd{i}(:,2),1);
s{i} = transpose(poly2mask(xc,yc,size(skel,2),size(skel,1)));
 end
% sum all objects, with smoothed edges, to recontruct the original binary image
BI = logical(sum(cat(3,s{:}),3));  

%% skeletonization 
skel(:,:,cnt) = bwskel(BI,'MinBranchLength',MinBranchLength); % skeletonization function

%% find all object in the image

% find the connected part of the skeletonization image
CC(:,:,cnt) = bwconncomp(skel(:,:,cnt));
% label each filament with a different number 
L(:,:,cnt) = labelmatrix(CC(:,:,cnt));

curr_img(cnt)=j;
cnt=cnt+1;
end





