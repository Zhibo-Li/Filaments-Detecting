function xy = elongated_objects_trajectories(pathout,basepath,tifname,prmt,prmt_index)

batch = prmt(prmt_index).batch;

ds = prmt(prmt_index).ds;
npnts = prmt(prmt_index).npnts;

initial_frame = prmt(prmt_index).frame_no;  % processing image

% FIND THE TRAJECTORIES OF THE ELONGATED OBJECT

% basic information
% find out extension and filename
[inext,~]=regexp(tifname,'.tif');
tifrooth=tifname(1:inext-1);
% ext=tifname(inext:endext);
tifpath=strcat(basepath,tifname);

% gets image stack information
InfoImage=imfinfo(tifpath);
% bit depth
% bitimg = InfoImage.BitDepth;
% number of images in the multi-tiff file
imtot=length(InfoImage);

% skeletonization of the image stack:
frame_step=1;
final_frame=imtot;
framelist = (initial_frame:frame_step:final_frame);
pathintif = strcat(basepath,tifrooth,'.tif');

% skeletonization of all selected frames
[L,curr_img,ROI,prmt,Good_case] = skeletonization_multi_frames_calculation(pathintif,frame_step,final_frame,prmt,prmt_index);
prmt(end) = [];

% coordinates & trajectories reconstruction
% obtain the sequential coordinates XY of each filament centerline in the test image
[XY,centroid,N_fil,improc,prcs_img,missed_frames] = sortcoordinates(L,curr_img,1);    
% input '1' is the expected number of filament in the image.

% reject frames based on arclength: condition s - mean(s) > std(s)
% output structure xy with coordinates, centroid, arclength
xy = rejectfil(XY,centroid,improc,N_fil,ds,prcs_img,missed_frames,framelist);
% apply B-spline to smooth out the centerline
xy = spline_centerline(xy,N_fil,ds,npnts);

% remove cases that are calculated but have more than 2 ends.
Good_case(ismember(Good_case, xy.emptyframe)) = [];  
% correct the xwin, ywin, xskip and yskip correspondingly. 
prmt_tmp = prmt;
for ii = 1: length(prmt)-1
    prmt(ii+1).xwin = prmt_tmp(ii).xwin;
    prmt(ii+1).ywin = prmt_tmp(ii).ywin;
    prmt(ii+1).xskip = prmt_tmp(ii).xskip;
    prmt(ii+1).yskip = prmt_tmp(ii).yskip;
end


file2save = strcat(pathout,filesep,'trajectory_',tifrooth,'_batch',num2str(batch));
save(strcat(file2save,'.mat'),'prmt','Good_case','framelist','InfoImage','ROI','prcs_img','xy'); 
% xy.frames includes prcs_img but is different to it.  

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


