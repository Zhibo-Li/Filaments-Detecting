function [xy, new_FilNum_ls] = rejectfil(XY,centroid,improc,N_fil,prcs_img,missed,framelist)

%% OUTPUT: MATLAB STRUCTURE xy
%
%              WITH THE FOLLOWING STRUCTURE: xy(i).property{j}, WHERE
%
% (i) is the filament label              i = 1...FilNum = number of objects in the stack
% {j} is the sequential index            j = 1...nframe = number of analyzed frames
%
%              PROPERTY CAN BE:
%     crd = cell containing the x-y coordinates of the skeleton --> x = first column, y = second column
%     centroid = cell containing the x-y coordinates of the centroid of the skeleton
%     arclen = 1-d array of arc lengths of the skeleton
%     seglen = cell containing the length of each segment in the skeleton
%     emptyframe = 1-d array of frame where the filament cannot be detected
%     frame = frame number in the original tiff file
%     nframes = total number of frames in which the filament has been detected
%     spl = cell containing the x-y coordinates of the B-spline --> x = first column, y = second column
%     knots = cell containing the x-y coordinates used to interpolate the skeleton with B-spline
%     arclen_spl = 1-d array of arc lengths of the B-spline
%     seglen_spl = cell containing the length of each segment in the B-spline
%
% NOTE: to call xy remember that the frame index j must be enclosed between:
%
% *   curly brackets when PROPERTY is a Matlab cell (i.e. crd,centroid,seglen,spl,knots,seglen_spl),
% *   round brackets when PROPERTY is a Matlab 1-d array (i.e. arclen,emptyframe,arclen_spl,frame)
%-------- EXAMPLES:
% *         xy(1).spl{50}(:,1) gives the x-coordinates (:,1) of filament 1 at j = 50
% *         xy(1).frame(50) gives the number of the frame in the original tiff file, located at j = 50
% *         xy(3).emptyframe gives the list of frames where the filament 3 has not been detected
% *         xy(1).arclen(756) gives the arc length of filament 2 when j = 756


%% calculate the arc length of each filament in each frame
[~, pos] = ismember(prcs_img, framelist);
N_fil = N_fil(pos); new_FilNum_ls = N_fil;

for i = 1 : max(N_fil)
    for j = 1 : improc
        if numel(XY{i,j}) < 3 % 2*ds：remove segments with length ~less than 2*ds
            % Change '2*ds' to 3 for Z-scanning filament detection.
            arclen(i,j)=NaN;
        else
            [arcl,segl] = arclength(XY{i,j}(:,1),XY{i,j}(:,2),'linear');
            arclen(i,j) = arcl;
            seglen{i,j} = segl;
        end
    end
end
arclen(arclen==0)=NaN; % set to NaN zero-length filament

%% reject frames based on arclength


if improc > 2 % compute only if we have statistics
    mean_s = mean(arclen,2,"omitnan");
    std_s = std(arclen,0,2,"omitnan");    
    
    % accept only filaments within a range of arclengths, reorder the coordinates
    for j = 1 : improc
        for i = 1 : N_fil(j) 
            if abs(arclen(i,j) - mean_s(i)) < 5*std_s(i) || std_s(i) == 0 % 2*std_s(i)
                % Change to '5*std_s(i)' and add 'std_s(i) == 0' for Z-scanning filament detection.
                XYr{i,j}(:,1) = XY{i,j}(:,1);
                XYr{i,j}(:,2) = XY{i,j}(:,2);
            else
                XYr{i,j}=[];
            end
        end
    end
    
else
    XYr=XY;
end

% output coordinates
xy=struct;
missed = missed + framelist(1) - 1; % Add by Zhibo 
for i = 1 : max(N_fil)
    emptycell = cellfun('isempty',XYr(i,:)) ;
    xy(i).crd = XYr(i,imcomplement(emptycell));
    xy(i).centroid = centroid(i,imcomplement(emptycell));
    xy(i).arclen = arclen(i,imcomplement(emptycell));
    xy(i).seglen = seglen(i,imcomplement(emptycell));
    xy(i).emptyframe = sort([prcs_img(emptycell==1),missed]);
    xy(i).nframe = length(find(imcomplement(emptycell)==1));
    xy(i).frame = setdiff(framelist,xy(i).emptyframe);
end

end

