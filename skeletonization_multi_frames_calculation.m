function [L,curr_img,ROI,prmt, Good_case] = skeletonization_multi_frames_calculation(pathintif,...
    imspace,imtot,prmt,prmt_index)

FilNum = prmt(prmt_index).FilNum;
xskip = prmt(prmt_index).xskip; 
xwin = prmt(prmt_index).xwin;
ywin = prmt(prmt_index).ywin;

lnoise = prmt(prmt_index).lnoise;
lobject = prmt(prmt_index).lobject;
lzero = max(lobject,ceil(5*lnoise)); % size of each edges where gaussian_blur set values to 0

imi = prmt(prmt_index).frame_no;  % processing image

% retrieve the ROI in the image stack and the edge thickness
% first read an image and select a ROI for all the image stack

ywin = ywin+mod(ywin,2); xwin = xwin+mod(xwin,2);
[xtot, ytot] = size(imread(pathintif,1));
% define & resize a skeletonization array, due to gaussian_blur function
skel=zeros(xtot-2*lzero,ytot-2*lzero, length(imi : imspace : imtot));
curr_img = zeros(1,length(imi : imspace : imtot));

% skeletonization of the image stack

cnt=1;
for j = imi : imspace : imtot

    if j == prmt(1).frame_no

        imgn = imread(pathintif,j);  % Here does't need update_parameters because it's the first frame!
 
        thickness = prmt(prmt_index).thickness;
        structsensitivity = prmt(prmt_index).structsensitivity;

        lnoise = prmt(prmt_index).lnoise;
        lobject = prmt(prmt_index).lobject;
        threshold = prmt(prmt_index).threshold;

        sensitivity = prmt(prmt_index).sensitivity;
        MinBranchLength = prmt(prmt_index).MinBranchLength;


        % enanche fibers in the image with predefined thickness
        fiber_img = fibermetric(imgn,thickness,'StructureSensitivity',structsensitivity);
        % imshow(fiber_img);

        % apply gaussian blur
        blur_img = gaussian_blur(fiber_img,lnoise,lobject,threshold);
        blur_img = blur_img(lzero+1:end-lzero,lzero+1:end-lzero);

        % binarization and suppression of stray pixels
        BI = imbinarize(blur_img,'adaptive','ForegroundPolarity','bright','Sensitivity',sensitivity);
        BI = bwareafilt(BI,FilNum); % extract object based on area, where FilNum is the expected # of filaments
        % BI = imfill(BI,'holes'); % fill the holes in the binary image of the filament (works better than bwmorph)

        % re-apply gaussian blur to the binary image
        % BI = logical(gaussian_blur(double(BI),3,14,0.1));

        bnd = bwboundaries(BI,'noholes'); % find boundary coordinates of all objects in the FOV
        % smooth the edges of each objects in the FOV, then recontruct a binary image for each objects
        for i = 1 : FilNum
            clear xc yc
            xc = smooth(bnd{i}(:,1),1);
            yc = smooth(bnd{i}(:,2),1);
            s_full{i} = transpose(poly2mask(xc,yc,size(imgn,2)-2*lzero,size(imgn,1)-2*lzero));
        end
        BI_full = logical(sum(cat(3,s_full{:}),3));
        skel_full = bwskel(BI_full,'MinBranchLength',MinBranchLength);
        % find the connected part of the skeletonization image
        CC_full = bwconncomp(skel_full);
        % label each filament with a different number
        L_full = labelmatrix(CC_full);
        % find the centroids
        cntrds = regionprops(L_full ,'centroid');

        % select the filament you want
        figure('Name','skeletonization results');
        imshow(labeloverlay(blur_img,L_full,'Transparency',0));
        title('Please select the filament you want to follow!')
        selrect = getrect; close;

        % find the centroid which is within the rectangle
        tmp = cell2mat(struct2cell(cntrds));
        tmpctr = reshape(tmp,2,numel(tmp)/2); % All the centroids
        clear tmp;
        ctrpos = find(tmpctr(1,:)>=selrect(1) & tmpctr(1,:)<= selrect(1)+selrect(3) &...
            tmpctr(2,:)>=selrect(2) & tmpctr(2,:)<= selrect(2)+selrect(4));
        if numel(ctrpos) == 1
            thecntrd = tmpctr(:,ctrpos);
            thecntrd = 2*lzero + thecntrd; % the real coordinate in full image!
        else
            disp('Please quit and re-calculate!!!')
        end


        %% recalculate the selected region
        row1 = round(thecntrd(2)-ywin/2);
        row2 = round(thecntrd(2)+ywin/2);
        col1 = round(thecntrd(1)-xwin/2);
        col2 = round(thecntrd(1)+xwin/2);

        row1 = max(row1, 1);  row2 = min(row2, ytot);
        col1 = max(col1, 1);  col2 = min(col2, xtot);
        imgn1 = imgn(row1:row2,col1:col2);
        ROI(prmt_index).frame_no = j;
        ROI(prmt_index).row1 = row1; ROI(prmt_index).row2 = row2;
        ROI(prmt_index).col1 = col1; ROI(prmt_index).col2 = col2;
        %         imshow(imgn1,[])

        % enanche fibers in the image with predefined thickness
        fiber_img = fibermetric(imgn1,thickness,'StructureSensitivity',structsensitivity);
        % imshow(fiber_img);

        % apply gaussian blur
        blur_img = gaussian_blur(fiber_img,lnoise,lobject,threshold);
        blur_img = blur_img(lzero+1:end-lzero,lzero+1:end-lzero);

        % binarization and suppression of stray pixels
        BI = imbinarize(blur_img,'adaptive','ForegroundPolarity','bright','Sensitivity',sensitivity);
        BI = bwareafilt(BI,1); % extract object based on area, where FilNum is the expected # of filaments
        % BI = imfill(BI,'holes'); % fill the holes in the binary image of the filament (works better than bwmorph)

        % re-apply gaussian blur to the binary image
        % BI = logical(gaussian_blur(double(BI),3,14,0.1));

        %% smooth out the jags/irregularities along the boundary of the objects:

        bnd = bwboundaries(BI,'noholes'); % find boundary coordinates of all objects in the FOV
        % smooth the edges of each objects in the FOV, then recontruct a binary image for each objects
        clear xc yc
        xc = smooth(bnd{1}(:,1),1);
        yc = smooth(bnd{1}(:,2),1);
        s{1} = transpose(poly2mask(xc,yc,col2-col1+1-2*lzero,row2-row1+1-2*lzero));
        % sum all objects, with smoothed edges, to recontruct the original binary image
        BI = logical(sum(cat(3,s{:}),3));
        plank = zeros(xtot,ytot);
        plank(row1+lzero:row2-lzero,col1+lzero:col2-lzero) = BI;
        plank = logical(plank);
        % % %
        % % %         Bound_Box = regionprops(plank ,'BoundingBox');
        % % %
        %% skeletonization
        skel(:,:,cnt) = bwskel(plank(lzero+1:end-lzero, lzero+1:end-lzero),'MinBranchLength',MinBranchLength); % skeletonization function

%         figure('Name', num2str(j));
%         padded_im = padarray(skel(:,:,cnt), [lzero, lzero], 'both');
%         zoomin_to_show = padded_im(row1:row2,col1:col2);
%         imshow(labeloverlay(imadjust(imgn1),zoomin_to_show,'Colormap','hot','Transparency',0));
        
        prmt(prmt_index+1) = prmt(prmt_index);
        prmt(prmt_index+1).frame_no = j + imspace;
        prmt(prmt_index+1).initial_index = 0;
        prmt_index = prmt_index + 1;


        curr_img(cnt)=j;
        cnt=cnt+1;

        Good_case_tmp(1) = prmt(1).frame_no;
    else

        imgn = imread(pathintif,j);

        try
            thecntrd(1) = thecntrd(1) + xskip;
            row1 = round(thecntrd(2)-ywin/2);
            row2 = round(thecntrd(2)+ywin/2);
            col1 = round(thecntrd(1)-xwin/2);
            col2 = round(thecntrd(1)+xwin/2);
        catch
            row1 = ROI.row1;
            row2 = ROI.row2;
            col1 = ROI.col1;
            col2 = ROI.col2;
        end

        row1 = max(row1, 1);  row2 = min(row2, ytot);
        col1 = max(col1, 1);  col2 = min(col2, xtot);
        if col1 == 1; col2 = xwin+1; end
        if col2 == xtot; col1 = xtot-xwin; end
        if row1 == 1; row2 = ywin+1; end
        if row2 == ytot; row1 = ytot-ywin; end
        imgn1 = imgn(row1:row2,col1:col2);
        
        ROI(prmt_index).frame_no = j;
        ROI(prmt_index).row1 = row1; ROI(prmt_index).row2 = row2;
        ROI(prmt_index).col1 = col1; ROI(prmt_index).col2 = col2;

        [prmt_new, Good_case]= update_parameters(imgn1,prmt,prmt_index,Good_case_tmp);
        Good_case_tmp = Good_case;

        prmt = prmt_new;

        thickness = prmt(prmt_index).thickness;
        structsensitivity = prmt(prmt_index).structsensitivity;

        lnoise = prmt(prmt_index).lnoise;
        lobject = prmt(prmt_index).lobject;
        threshold = prmt(prmt_index).threshold;

        sensitivity = prmt(prmt_index).sensitivity;
        MinBranchLength = prmt(prmt_index).MinBranchLength;

        % enanche fibers in the image with predefined thickness
        fiber_img = fibermetric(imgn1,thickness,'StructureSensitivity',structsensitivity);

        % apply gaussian blur
        blur_img = gaussian_blur(fiber_img,lnoise,lobject,threshold);
        blur_img = blur_img(lzero+1:end-lzero,lzero+1:end-lzero);

        % binarization and suppression of stray pixels
        BI = imbinarize(blur_img,'adaptive','ForegroundPolarity','bright','Sensitivity',sensitivity);
        BI = bwareafilt(BI,1); % extract object based on area, where FilNum is the expected # of filaments
        % BI = imfill(BI,'holes'); % fill the holes in the binary image of the filament (works better than bwmorph)

        % re-apply gaussian blur to the binary image
        % BI = logical(gaussian_blur(double(BI),3,14,0.1));

        % smooth out the jags/irregularities along the boundary of the objects:

        bnd = bwboundaries(BI,'noholes'); % find boundary coordinates of all objects in the FOV

        % smooth the edges of each objects in the FOV, then recontruct a binary image for each objects
        clear xc yc
        xc = smooth(bnd{1}(:,1),1);
        yc = smooth(bnd{1}(:,2),1);
        s{1} = transpose(poly2mask(xc,yc,col2-col1+1-2*lzero,row2-row1+1-2*lzero));
        % sum all objects, with smoothed edges, to recontruct the original binary image
        BI = logical(sum(cat(3,s{:}),3));
        plank = zeros(xtot,ytot);
        plank(row1+lzero:row2-lzero,col1+lzero:col2-lzero) = BI;
        plank = logical(plank);

        cntrds = regionprops(plank ,'centroid');
        thecntrd = cell2mat(struct2cell(cntrds)); % Use the previous frame's centroids as the next frame's search area

        % skeletonization
        skel(:,:,cnt) = bwskel(plank(lzero+1:end-lzero, lzero+1:end-lzero),'MinBranchLength',MinBranchLength); % skeletonization function

%         figure('Name', num2str(j));
%         padded_im = padarray(skel(:,:,cnt), [lzero, lzero], 'both');
%         zoomin_to_show = padded_im(row1:row2,col1:col2);
%         imshow(labeloverlay(imadjust(imgn1),zoomin_to_show,'Colormap','hot','Transparency',0));

%         prmt = prmt_new;
%         ROI = ROI_new;
        prmt(prmt_index+1) = prmt(prmt_index);
        prmt(prmt_index+1).frame_no = j + imspace; 
        prmt_index = prmt_index + 1;

        curr_img(cnt)=j;
        cnt=cnt+1;

    end
end

L = skel;





