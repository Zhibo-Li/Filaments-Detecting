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
%                   MODE # 3: APPLY THE CODE TO THE ENTIRE SEQUENCE 
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

%% CODE
% path of the experiment
basepath='E:\Helicies in flow-Faustine\ALL\Multitiff\';
% name of the file to read
tifname='Test_crop_total.tif';
% batch number where storing the results
batch = 1; 
% number of filaments in the current image sequence
FilNum=1; 


% define some parameters for the fibermetric filtering
% fibermetric works better if the elongated object has a constant thickness across the image
thickness = 7; % thickness of the filament in px 
structsensitivity = 2.55; % threshold for differentiating the tubular structure from the background

% define some parameters for the gaussian blur
lnoise = 3; % characteristic lengthscale of noise in pixels
lobject = 15; % typical object size
threshold = 0.05; % threshhold for setting pixels to 0 after convolution with gaussian kernel

% define some parameters for morphological operations
sensitivity=0.900; % sensitivity for adaptive image binarization 
MinBranchLength=50; % minimum branch length, in pixel, to be accepted in the skel function

% define some parameters for b-spline fitting procedure
ds = 5; % constant segment length (in px) used for spacing the reference points in the B-spline fitting
npnts = 5; % number of points per interval in the recontructed B-spline centerline

%% RESULTS

xy = elongated_objects_trajectories(basepath,batch,tifname,thickness,...
    structsensitivity,lnoise,lobject,threshold,FilNum,sensitivity,MinBranchLength,ds,npnts);






