function [XY,centroid,N_fil,improc,prcs_img,missed] = sortcoordinates(L,curr_img,FilNum)

improc = size(L,3); 

missed=[]; 
cnt=1; % initiate a counter
for j = 1 : improc
   
U=unique(L(:,:,j)); % number of labels, including background (0)
N_fil = size(U,1)-1; % extract number of filaments in the j-th frame

% check if the number of filament correspond to what expected & store the
% frame number where they do not coincide

if N_fil ~= FilNum
  disp(strcat('Error: wrong number of filaments in  image: ', num2str(j)))
  disp(strcat('Expected:',num2str(FilNum)));
  disp(strcat('Found:',num2str(N_fil)));
  missed = [missed,j];
else
    
% take out the jumbled list of pixels belonging to objects in the skeletonized image stack
rp = regionprops(L(:,:,j) ,'PixelList'); % find pixel indexes of all objects (not in sequential order) 
% compute centroid of all objects in the FOV
cntrd = regionprops(L(:,:,j) ,'centroid'); 



for i = 1 : N_fil

% find the jumbled x & y coordinates of each filament in the FOV    
crd{i,cnt}(:,1) = rp(i).PixelList(:,1);
crd{i,cnt}(:,2) = size(L,2)-rp(i).PixelList(:,2);

% find the centroid position of the filament
centroid{i,cnt} = [cntrd(i).Centroid(1),size(L,2)-cntrd(i).Centroid(2)];

% determines the locations of endpoints in the given skeleton.
end_pts = ...
    find_skel_ends(ismember(L(:,:,j),i*ones(size(L(:,:,j),1),size(L(:,:,j),2))),'not testing');
end_pts(:,2) = size(L(:,:,j),2) - end_pts(:,2);
[~,ipr] = min( sqrt( end_pts(:,1).^2 + end_pts(:,2).^2));
% find the position of the end points in the coordinate matrix
[~,pos] = ismember(end_pts(ipr,:),crd{i,cnt}(:,:),'rows') ;

% ---> doesn't work everytime
% % % % for each objects, find the position of the farthest point from the center of mass,
% % % % and use it as the starting point for ordering the coordianates  
% % % d_from_cntd = sqrt( (crd{i,cnt}(:,1)-centroid{i,cnt}(1)).^2 +(crd{i,cnt}(:,2)-centroid{i,cnt}(2)).^2); 
% % % [~,pos] = max(d_from_cntd);
% % % % check if there exists multiple maxima, remove unwanted ones
% % % if length(pos)>1
% % %     pos(2:end)=[];
% % % end

% define the coordinates at the one extremity of the filament
xsrt = crd{i,cnt}(pos,1);
ysrt = crd{i,cnt}(pos,2);

% rearrange the coordinate matrix by putting the starting point at the beginning of the matrix 
strpnts=[xsrt,ysrt];
crd{i,cnt}(pos,:)=[];
crd{i,cnt}=[strpnts;crd{i,cnt}(:,:)];

% compute the distance matrix between all coordinates
Dij = squareform(pdist(crd{i,cnt},'Euclidean')); % D(i,j) is the distance between points i and j 
Dij(Dij==0)=NaN;  % replace 0 by NaN for exluding O from the minima

numcrd = size(crd{i,cnt},1); % number of points in the filament
XY{i,cnt} = strpnts; % define the matrix where to store the sequential coordinates 
 
k=1; 
ind=1;  % start appending the coordinates from the starting point
while k < numcrd
    
[~,ind] = min(Dij(ind,:)); % point having the smallest distance from the reference point
Dij(:,ind) = NaN; % replace NaN to avoid counting the same point two times

XY{i,cnt} = [XY{i,cnt};crd{i,cnt}(ind,:)];  % append the next coordinates sequentially 
    k=k+1;    

end
end
prcs_img(cnt)=curr_img(j); % store the orginal index of the image stack
cnt=cnt+1;
end
end
improc=improc-length(missed); % number of processed image, with right number of filaments
end

