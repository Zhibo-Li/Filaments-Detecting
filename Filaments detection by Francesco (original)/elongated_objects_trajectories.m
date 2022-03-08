function xy = elongated_objects_trajectories(basepath,batch,tifname,thickness,structsensitivity,lnoise,lobject,threshold,FilNum,sensitivity,MinBranchLength,ds,npnts)

%% FIND THE TRAJECTORIES OF THE ELONGATED OBJECTS 

% find out extension and filename  
[inext,endext]=regexp(tifname,'.tif');
tifrooth=tifname(1:inext-1);
ext=tifname(inext:endext);
tifpath=strcat(basepath,tifname);

% gets image stack information 
InfoImage=imfinfo(tifpath); 
% bit depth
bitimg = InfoImage.BitDepth;
% number of images in the multi-tiff file
imtot=length(InfoImage); 

lzero = max(lobject,ceil(5*lnoise)); % size of each edges where gaussian_blur set values to 0

% path for the result files
pathout = strcat(basepath,'results\');
[status,msg,msgID] = mkdir(pathout);  


%% check if a ROI has been already created
isROI = isfile(strcat(pathout,tifrooth,'-cropped.tif'));
isBKGD = isfile(strcat(pathout,tifrooth,'-cropped-nobackground.tif'));

if isROI == 1 && isBKGD == 0
disp('One cropped image has been found')
roifound = 1; bkgdfound = 0;
elseif  isROI == 1 && isBKGD == 1  
disp('Two cropped images have been found, in one background has been removed')
roifound = 1; bkgdfound = 1;
elseif isROI == 0 && isBKGD == 1  
disp('One cropped image has been found where background has been removed')
roifound = 0; bkgdfound = 1;
else
disp('Unable to find neither a cropped image, or a background removal')
roifound = 0; bkgdfound = 0;
end

%% computation
Inputmode = input('Enter an operation mode: \n 1 = select a (new) ROI/ remove background \n 2 = optimize parameters \n 3 = run \n');
switch Inputmode  
    case 1
roiselection = input('Do you want to select a ROI? Press: \n 1 = yes \n 2 = no \n');  
backgrdremoval = input('Do you want to remove the background? Press: \n 1 = yes \n 2 = no \n');      
%% select the ROI in the image stack and subtract the background (facultative)
% first read an image and select a ROI for the image stack

if roiselection == 1 
        img=imread(tifpath,1);  
        imshow(img,[])
        [x,y]=ginput(3);[x1,~]=min(x);x1=round(x1);y1=min(y);y1=round(y1);[x2,~] = max(x);x2=round(x2);y3= max(y); y3=round(y3);
        if x2-x1 < InfoImage(1).Width 
        width=x2-x1;
        else 
        width = InfoImage(1).Width-1;  
        x1=1;
        end
        if y3-y1 < InfoImage(1).Height
        height=y3-y1;
        else 
        height = InfoImage(1).Height-1;
        y1=1;
        end
        ROI=[x1 y1 width height];
                erase_bckgrd(pathout,tifrooth,tifpath,ROI,imtot,bitimg,backgrdremoval)  
else
    ROI = [1 1 InfoImage(1).Width-1 InfoImage(1).Height-1];
                erase_bckgrd(pathout,tifrooth,tifpath,ROI,imtot,bitimg,backgrdremoval)
end
      
    case 2
       
%% check the parameters for skeletonization
if imtot~=1 
    testimg=input(strcat('Choose a test frame in the range 1-',num2str(imtot),': \n'));   
else
    testimg=1;    
end
initial_frame = testimg; frame_step = 1; final_frame = testimg; 
framelist = (initial_frame:frame_step:final_frame);

if roifound == 1 && bkgdfound == 0
cropimg = input('Do you want to use the cropped image? Press: \n 1 = yes \n 2 = no \n');
    if cropimg == 1
    pathintif = strcat(pathout,tifrooth,'-cropped.tif');
    else 
    pathintif = strcat(basepath,tifrooth,'.tif');
    end
    
elseif roifound == 1 && bkgdfound == 1
cropimg = input('Which image do you want to use? Press: \n 0 = original image \n 1 = cropped only \n 2 = cropped + background removal \n');
    if cropimg == 0
    pathintif = strcat(basepath,tifrooth,'.tif');
    elseif cropimg == 1
    pathintif = strcat(pathout,tifrooth,'-cropped.tif');
    else 
    pathintif = strcat(pathout,tifrooth,'-cropped-nobackground.tif');
    end
    
elseif roifound == 0 && bkgdfound == 1    
cropimg = input('Do you want to use the cropped + background removal image? Press: \n 1 = yes \n 2 = no \n');
    if cropimg == 1
    pathintif = strcat(pathout,tifrooth,'-cropped-nobackground.tif');
    else 
    pathintif = strcat(basepath,tifrooth,'.tif');
    end  
else
    pathintif = strcat(basepath,tifrooth,'.tif');
end

%% skeletonization of a test image
[fiber_img,blur_img,BI,~,L,curr_img,ROI] = skeletonization3(pathintif,lzero,initial_frame,frame_step,final_frame,...
    thickness,structsensitivity,lnoise,lobject,threshold,sensitivity,MinBranchLength,FilNum);

% plot the main results
img_tst = imread(strcat(pathintif),testimg);
figure('Name','original image'); 
imshow(img_tst,[])
figure('Name','fibermetric filtering'); 
imshow(fiber_img,[])
figure('Name','blurred image'); 
imshow(blur_img,[])
figure('Name','binarized image'); 
imshow(BI)
imfs = imfuse(img_tst(lzero+1:end-lzero,lzero+1:end-lzero),L);
figure('Name','skeletonization results'); 
imshow(labeloverlay(blur_img,L,'Transparency',0))


    case 3
    
%% skeletonization of the image stack:
initial_frame=input(strcat('Choose the intial frame in the range 1-',num2str(imtot),' : \n'));
frame_step=input(strcat('Choose the step between frames : \n'));
final_frame=input(strcat('Choose the final frame in the range ',num2str(initial_frame),'-',num2str(imtot),' : \n'));
framelist = (initial_frame:frame_step:final_frame); 

if roifound == 1 && bkgdfound == 0
cropimg = input('Do you want to use the cropped image? Press: \n 1 = yes \n 2 = no \n');
    if cropimg == 1
    pathintif = strcat(pathout,tifrooth,'-cropped.tif');
    else 
    pathintif = strcat(basepath,tifrooth,'.tif');
    end
    
elseif roifound == 1 && bkgdfound == 1
cropimg = input('Which image do you want to use? Press: \n 0 = original image \n 1 = cropped only \n 2 = cropped + background removal \n');
    if cropimg == 0
    pathintif = strcat(basepath,tifrooth,'.tif');
    elseif cropimg == 1
    pathintif = strcat(pathout,tifrooth,'-cropped.tif');
    else 
    pathintif = strcat(pathout,tifrooth,'-cropped-nobackground.tif');
    end
    
elseif roifound == 0 && bkgdfound == 1    
cropimg = input('Do you want to use the cropped + background removal image? Press: \n 1 = yes \n 2 = no \n');
    if cropimg == 1
    pathintif = strcat(pathout,tifrooth,'-cropped-nobackground.tif');
    else 
    pathintif = strcat(basepath,tifrooth,'.tif');
    end  
else
    pathintif = strcat(basepath,tifrooth,'.tif');
end

%% skeletonization of all selected frames 
[~,~,~,~,L,curr_img,ROI] = skeletonization3(pathintif,lzero,initial_frame,frame_step,final_frame,...
    thickness,structsensitivity,lnoise,lobject,threshold,sensitivity,MinBranchLength,FilNum);

end

%% coordinates & trajectories reconstruction
switch Inputmode 
    case 1 
        return
    case 2    
        
%% obtain the sequential coordinates of each filament centerline in the test image

[XY,centroid,N_fil,improc,prcs_img,~] = sortcoordinates(L,curr_img,FilNum);
%% reject frames based on arclength: condition s - mean(s) > std(s)
% output structure xy with coordinates, centroid, arclength
xy = rejectfil(XY,centroid,improc,N_fil,ds,prcs_img,[],framelist);
%% Apply B-spline to smooth out the centerline
xy = spline_centerline(xy,N_fil,ds,npnts);

figure('Name','centerline reconstruction');
plot(xy(1).spl{1}(:,1),xy(1).spl{1}(:,2),'-','linewidth',6)
hold on
plot(xy(1).crd{1}(:,1),xy(1).crd{1}(:,2),'.','markeredgecolor','k','markerfacecolor','w','linewidth',2)
hold on
% plot(xy(1).knots{1}(:,1),xy(1).knots{1}(:,2),'o','markeredgecolor','w','markerfacecolor','r','linewidth',0.5)

axis equal
axis equal
xlim('auto')
ylim('auto')
axis off
    case 3

%% obtain the sequential coordinates XY of each filament centerline in the test image
[XY,centroid,N_fil,improc,prcs_img,missed_frames] = sortcoordinates(L,curr_img,FilNum);
%% reject frames based on arclength: condition s - mean(s) > std(s)
% output structure xy with coordinates, centroid, arclength
xy = rejectfil(XY,centroid,improc,N_fil,ds,prcs_img,missed_frames,framelist);
%% apply B-spline to smooth out the centerline
xy = spline_centerline(xy,N_fil,ds,npnts);

file2save = strcat(pathout,'trajectory_',tifrooth,'_batch',num2str(batch));

save(strcat(file2save,'.mat'),'thickness','structsensitivity','lnoise','lobject','threshold','ds',...
    'npnts','FilNum','initial_frame',...
    'frame_step','final_frame','framelist','improc','InfoImage','L',...,
    'MinBranchLength','ROI','missed_frames',...
    'N_fil','prcs_img','sensitivity','xy')

figure('Name','trajectory');
for k =1 : xy.nframe
    
    plot(xy.spl{k}(:,1),xy.spl{k}(:,2))
    hold on
end

axis equal
xlim('auto')
ylim('auto')
xlabel(' x [ px ] ')
ylabel(' y [ px ] ')

end

