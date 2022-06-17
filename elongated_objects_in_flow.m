%% MAIN SCRIPT
%% FIND THE TRAJECTORY OF ELONGATED OBJECTS IN FLOW
%~~~~~  GENERAL DESCRIPTION   :
%
% *  READ AN IMAGE STACK --> ONLY MULTIPAGE TIFF ARE ACCEPTED (ex: "filaname.tif")
% *  COMPUTE THE SKELETON OF THE ELONGATED OBJECT
% *  FIND THE X-Y COORDINATES (CENTERLINE) OF THE SKELETON (DISORDERED 2-COLUMNS MATRIX OF PIXELS).
% *  FIND THE ENDPOINTS OF THE CENTERLINE.
% *  ORDER THE COORDINATES STARTING FROM ONE ENDPOINT, UNTIL THE WHOLE CENTERLINE HAS BEEN COVERED.
% *  CALCULATE THE ARC LENGTH OF THE CENTERLINE
% *  DISREGARD FRAMES WHERE THE CENTERLINE IS TOO SHORT OR TOO LONG (WHIT RESPECT TO THE MEAN ARC LENGTH)
% *  INTERPOLATE THE CENTERLINE SHAPE USING B-SPLINE FUNCTIONS
%
% IMPORTANT NOTES:
%           -THE CODE CAN HANDLE MULTIPLE OBJECTS IN THE SAME IMAGE STACK
%           -OBJECTS SHOULD BE FAR AWAY FROM THE EDGES OF THE IMAGE
%
%~~~~~  WHILE RUNNING, CODE ASKS THE OPERATION MODE (FOLLOW THE INSTRUCTIONS ON THE SCREEN)
%
%                   THREE MODES --> 1,2,3
%
%                   MODE # 1: REGION OF INTEREST (ROI) SELECTION &/OR BACKGROUND REMOVAL (FACULTATIVE)-->
%                   SAVE THE NEW IMAGE STACK ON THE RESULT FOLDER (in the path of the tiff file)
%                   THE ROI MAY BE THE WHOLE IMAGE AS WELL
%
%                   MODE # 2: PARAMETER OPTIMIZATION -->
%                   CHOOSE A FRAME TO ANALYZE AMONG THE WHOLE STACK. DISPLAY THE RESULTS AFTER:
%                   (i)   FIBERMETRIC FILTERING
%                   (ii)  GAUSSIAN BLUR
%                   (iii) BINARIZATION
%                   (iv)  SKELETONIZATION
%                   (v)   CENTERLINE RECONSTRUCTION
%
%                   MODE # 3: APPLY THE CODE TO THE ENTIRE SEQUENCE (CALCULATION)
%
%
%
%~~~~~ OUTPUT: MATLAB STRUCTURE xy 
%
%              WITH THE FOLLOWING STRUCTURE: xy(i).property{j}, WHERE
%
% (i) is the filament label              i = 1...FilNum = number of objects in the stack
% {j} is the sequential index            j = 1...nframe = number of analyzed frames
%
% IMPORTANT NOTES:
% FilNum must be constant in the whole sequence, and MUST be specified before running the code
% nframe is returned by the code
%
% PROPERTY ARE:
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
% NOTE: to call xy remember that index j must be enclosed between:
%
% *   curly brackets when PROPERTY is a Matlab cell (i.e. crd,centroid,seglen,spl,knots,seglen_spl),
% *   round brackets when PROPERTY is a Matlab 1-d array (i.e. arclen,emptyframe,arclen_spl,frame)
%
%-------- EXAMPLES:
% *         xy(1).spl{50}(:,1) gives the x-coordinates (:,1) of filament 1 at j = 50
% *         xy(3).frame(50) indicates, for filament 3, the frame number in the tiff file, when j = 50
% *         xy(2).emptyframe gives the list of frames where the filament 2 has not been detected
% *         xy(1).arclen(756) gives the arc length of filament 2 when j = 756
%
% THE REULTS ARE STORED IN A MATLAB FILE CALLED "trajectory_filename_batch#.mat" where:
% *   filename is the SAME name (without extension) of the tiff file
% *   # is the batch number where the results are stored

% (12/02/2022) Zhibo LI modify and improve the code to achieve follow functions:
% * Combine the PARAMETER OPTIMIZATION & CALCULATION modes together, so don't
%   need the second run.
%
% * With only one click of 'run', do the optimization continuously in Dialog Box 
%   until it's satisfied to calculate.
%
% * Reconstruction checks are performed in real-time for each frame, and optimization 
%   parameters can be changed during computation.
%
% * Delete the no-needed parts, such as the REGION OF INTEREST (ROI)
%   SELECTION &/OR BACKGROUND REMOVAL.



%% CODE
clear; close all; clc;

[filename, pathname]=uigetfile({'G:\PhD, PMMH, ESPCI\Experimental Data (EXTRACTED)\20220217-Actin\AfterAveBGR\*.tif'}, 'Choose a file to be processed');  % input file

% path for the result files
pathout = uigetdir('G:\PhD, PMMH, ESPCI\Processing\20220217-Actin\results\', 'Choose the saving folder');
[status,msg,msgID] = mkdir(pathout);

% path of the experiment
basepath=pathname;
% name of the file to read
tifname=filename;
 
% prmt: the parameters used for calculating.
% batch number where storing the results
prmt(1).batch = 1;
% number of filaments in the current image sequence
prmt(1).FilNum = 3;
% set the 'interrogation windows' offset
prmt(1).xskip = 20;  % right(+) left(-)
prmt(1).yskip = 0;  % up(+) down(-)
% set the 'interrogation windows' size
prmt(1).xwin = 600;
prmt(1).ywin = 300;


% define some parameters for the fibermetric filtering
% fibermetric works better if the elongated object has a constant thickness across the image
prmt(1).thickness = 50; % thickness of the filament in px
prmt(1).structsensitivity = 0.7; % Here, the value indicates the percentage of the diff(getrangefromclass(I)).
% !!! The structsensitivity of the results calculated before 2022/06/17
% meant the absolute value. !!!
% threshold for differentiating the tubular structure from the background
% The default value depends on the data type of image I, and is calculated 
% as 0.01*diff(getrangefromclass(I)). For example, the default threshold is
% 2.55 for images of data type uint8, and the default is 0.01 for images of 
% data type double with pixel values in the range [0, 1].

% define some parameters for the gaussian blur
prmt(1).lnoise = 3; % characteristic lengthscale of noise in pixels
prmt(1).lobject = 30; % typical object size
prmt(1).threshold = 0.1; % threshhold for setting pixels to 0 after convolution with gaussian kernel

% define some parameters for morphological operations
prmt(1).sensitivity = 0.7; % sensitivity for adaptive image binarization
prmt(1).MinBranchLength = 20; % minimum branch length, in pixel, to be accepted in the skel function

% define some parameters for b-spline fitting procedure
prmt(1).ds = 5; % constant segment length (in px) used for spacing the reference points in the B-spline fitting
prmt(1).npnts = 5; % number of points per interval in the recontructed B-spline centerline

%% Change the start frame:
prmt(1).frame_no = 3; % the first frame you want to deal with.
prmt_index = 1; % index of prmt

%% TO CALCULATE!!!!!!!

elongated_objects_trajectories(pathout,basepath,tifname,prmt,prmt_index);



