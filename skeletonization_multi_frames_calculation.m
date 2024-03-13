function [L,curr_img,ROI,prmt, Good_case] = skeletonization_multi_frames_calculation(pathintif,...
    imspace,imtot,prmt,prmt_index)

imi = prmt(prmt_index).frame_start;  % processing image

[xtot, ytot] = size(imread(pathintif,1));
% define & resize a skeletonization array, due to gaussian_blur function
skel=zeros(xtot, ytot, length(imi : imspace : imtot));
curr_img = zeros(1,length(imi : imspace : imtot));

% skeletonization of the image stack
cnt=1;
for j = imi : imspace : imtot

    if j == prmt(1).frame_start

        imgn = imread(pathintif,j);  % Here does't need update_parameters because it's the first frame!
 
        thickness = prmt(prmt_index).thickness;
        structsensitivity = prmt(prmt_index).structsensitivity * diff(getrangefromclass(imgn));

        lnoise = prmt(prmt_index).lnoise;
        lobject = prmt(prmt_index).lobject;
        threshold = prmt(prmt_index).threshold;

        sensitivity = prmt(prmt_index).sensitivity;
        MinBranchLength = prmt(prmt_index).MinBranchLength;

        % apply 2-D median filtering to remove the 'salt & pepper' noise.
        medfilt_imgn = medfilt2(imgn);

        % enanche fibers in the image with predefined thickness
        fiber_img = fibermetric(medfilt_imgn,thickness,'StructureSensitivity',structsensitivity);

        % apply gaussian blur
        blur_img = gaussian_blur(fiber_img,lnoise,lobject,threshold);

        FilNum = prmt(prmt_index).FilNum;

        % binarization and suppression of stray pixels
        BI = imbinarize(blur_img,'adaptive','ForegroundPolarity','bright','Sensitivity',sensitivity);
        BI = bwareafilt(BI,FilNum); % extract object based on area, where FilNum is the expected # of filaments
        % BI = imfill(BI,'holes'); % fill the holes in the binary image of the filament (works better than bwmorph)

        bnd = bwboundaries(BI,'noholes'); % find boundary coordinates of all objects in the FOV
        % smooth the edges of each objects in the FOV, then recontruct a binary image for each objects
        clear s_full
        for i = 1 : FilNum
            clear xc yc 
            xc = smooth(bnd{i}(:,1),1);
            yc = smooth(bnd{i}(:,2),1);
            s_full{i} = transpose(poly2mask(xc,yc,size(imgn,2),size(imgn,1)));
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
        else
            disp('Please quit and re-calculate!!!')
        end


        %% recalculate the selected region
        % retrieve the ROI in the image
        xwin = prmt(prmt_index).xwin;
        ywin = prmt(prmt_index).ywin;
        ywin = ywin+mod(ywin,2); xwin = xwin+mod(xwin,2);

        row1 = round(thecntrd(2)-ywin/2);
        row2 = round(thecntrd(2)+ywin/2);
        col1 = round(thecntrd(1)-xwin/2);
        col2 = round(thecntrd(1)+xwin/2);

        row1 = max(row1, 1);  row2 = min(row2, xtot);
        col1 = max(col1, 1);  col2 = min(col2, ytot);
        imgn1 = imgn(row1:row2,col1:col2);
        ROI(prmt_index).frame_start = j;
        ROI(prmt_index).row1 = row1; ROI(prmt_index).row2 = row2;
        ROI(prmt_index).col1 = col1; ROI(prmt_index).col2 = col2;

        % apply 2-D median filtering to remove the 'salt & pepper' noise.
        medfilt_imgn = medfilt2(imgn1);

        % enanche fibers in the image with predefined thickness
        fiber_img = fibermetric(medfilt_imgn,thickness,'StructureSensitivity',structsensitivity);

        % apply gaussian blur
        blur_img = gaussian_blur(fiber_img,lnoise,lobject,threshold);

        % binarization and suppression of stray pixels
        BI = imbinarize(blur_img,'adaptive','ForegroundPolarity','bright','Sensitivity',sensitivity);
        BI = bwareafilt(BI,1); % extract object based on area, where FilNum is the expected # of filaments. Here, FilNum = 1
        % BI = imfill(BI,'holes'); % fill the holes in the binary image of the filament (works better than bwmorph)

        %% smooth out the jags/irregularities along the boundary of the objects:

        bnd = bwboundaries(BI,'noholes'); % find boundary coordinates of all objects in the FOV
        % smooth the edges of each objects in the FOV, then recontruct a binary image for each objects
        clear xc yc
        xc = smooth(bnd{1}(:,1),1);
        yc = smooth(bnd{1}(:,2),1);
        s{1} = transpose(poly2mask(xc,yc,col2-col1+1,row2-row1+1)); % Here, I only choose one filament!! (Zhibo)
        % The first image always has one filament for convenience!! (Zhibo added this on 10/03/2024 for Z-scanning treatment.)
        % sum all objects, with smoothed edges, to recontruct the original binary image
        BI = logical(sum(cat(3,s{:}),3));
        plank = zeros(xtot,ytot);
        plank(row1:row2,col1:col2) = BI;
        plank = logical(plank);
    
        %% skeletonization
        skel(:,:,cnt) = bwskel(plank,'MinBranchLength',MinBranchLength); % skeletonization function
        
        prmt(prmt_index+1) = prmt(prmt_index);
        prmt(prmt_index+1).frame_start = j + imspace;
        prmt(prmt_index+1).initial_index = 0;
        prmt_index = prmt_index + 1;


        curr_img(cnt)=j;
        cnt=cnt+1;

        Good_case_tmp(1) = prmt(1).frame_start;   
        % Notice: this first case might not be good case.
    else

        imgn = imread(pathintif,j);

        % ROI shifting distance.
        xskip = prmt(prmt_index).xskip;
        yskip = prmt(prmt_index).yskip;
        % retrieve the ROI in the image
        xwin = prmt(prmt_index).xwin;
        ywin = prmt(prmt_index).ywin;
        ywin = ywin+mod(ywin,2); xwin = xwin+mod(xwin,2);
        % !!! NOTE: xwin, ywin, xskip and yskip valid for next loop
        % (prmt_index + 1).

        try
            thecntrd(1) = thecntrd(1) + xskip;
            thecntrd(2) = thecntrd(2) + yskip;
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

        row1 = max(row1, 1);  row2 = min(row2, xtot);
        col1 = max(col1, 1);  col2 = min(col2, ytot);
        if col1 == 1 && col2 == ytot
            col1 = 1; col2 = ytot;
        elseif col1 == 1
            col2 = xwin+1;
        elseif col2 == ytot
            col1 = ytot-xwin;
        end
        if row1 == 1 && row2 == xtot
            row1 = 1; row2 = xtot;
        elseif row1 == 1
            row2 = ywin+1;
        elseif row2 == xtot
            row1 = xtot-ywin;
        end
        imgn1 = imgn(row1:row2,col1:col2);
        
        ROI(prmt_index).frame_start = j;
        ROI(prmt_index).row1 = row1; ROI(prmt_index).row2 = row2;
        ROI(prmt_index).col1 = col1; ROI(prmt_index).col2 = col2;

        [prmt_new, Good_case]= update_parameters(imgn1,prmt,prmt_index,Good_case_tmp);
        Good_case_tmp = Good_case;

        prmt = prmt_new;

        thickness = prmt(prmt_index).thickness;
        structsensitivity = prmt(prmt_index).structsensitivity * diff(getrangefromclass(imgn1));

        lnoise = prmt(prmt_index).lnoise;
        lobject = prmt(prmt_index).lobject;
        threshold = prmt(prmt_index).threshold;

        sensitivity = prmt(prmt_index).sensitivity;
        MinBranchLength = prmt(prmt_index).MinBranchLength;

        % apply 2-D median filtering to remove the 'salt & pepper' noise.
        medfilt_imgn = medfilt2(imgn1);

        % enanche fibers in the image with predefined thickness
        fiber_img = fibermetric(medfilt_imgn,thickness,'StructureSensitivity',structsensitivity);

        % apply gaussian blur
        blur_img = gaussian_blur(fiber_img,lnoise,lobject,threshold);

        FilNum = prmt(prmt_index).FilNum;

        % binarization and suppression of stray pixels
        BI = imbinarize(blur_img,'adaptive','ForegroundPolarity','bright','Sensitivity',sensitivity);
        BI = bwareafilt(BI,FilNum); % extract object based on area, where FilNum is the expected # of filaments
        % BI = imfill(BI,'holes'); % fill the holes in the binary image of the filament (works better than bwmorph)

        % re-apply gaussian blur to the binary image
        % BI = logical(gaussian_blur(double(BI),3,14,0.1));

        % smooth out the jags/irregularities along the boundary of the objects:

        bnd = bwboundaries(BI,'noholes'); % find boundary coordinates of all objects in the FOV
        clear s_full
        for i = 1 : FilNum
            clear xc yc
            xc = smooth(bnd{i}(:,1),1);
            yc = smooth(bnd{i}(:,2),1);
            s_full{i} = transpose(poly2mask(xc,yc,col2-col1+1,row2-row1+1));
        end
        BI_full = logical(sum(cat(3,s_full{:}),3));
        plank = zeros(xtot,ytot);
        plank(row1:row2,col1:col2) = BI_full;
        plank = logical(plank);

        cntrds = regionprops(plank ,'centroid');
        thecntrd = cell2mat(struct2cell(cntrds)); % Use the previous frame's centroids as the next frame's search area

        %% skeletonization
        skel_full = bwskel(plank,'MinBranchLength',MinBranchLength);
        % find the connected part of the skeletonization image
        CC_full = bwconncomp(skel_full);
        % label each filament with a different number
        skel(:,:,cnt) = labelmatrix(CC_full);

        prmt(prmt_index+1) = prmt(prmt_index);
        prmt(prmt_index+1).frame_start = j + imspace; 
        prmt_index = prmt_index + 1;

        curr_img(cnt)=j;
        cnt=cnt+1;

    end
end

L = skel;





