function [prmt_tmp, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index)

%% Use input dialogue to change the parameters.

prmt_index_tmp = prmt_index;
prmt_tmp = prmt;

the_inputs = {num2str(prmt(prmt_index).batch); num2str(prmt(prmt_index).FilNum);...
    num2str(prmt(prmt_index).xskip); num2str(prmt(prmt_index).yskip);num2str(prmt(prmt_index).xwin);...
    num2str(prmt(prmt_index).ywin);num2str(prmt(prmt_index).thickness);...
    num2str(prmt(prmt_index).structsensitivity);num2str(prmt(prmt_index).lnoise);...
    num2str(prmt(prmt_index).lobject);num2str(prmt(prmt_index).threshold);...
    num2str(prmt(prmt_index).sensitivity); num2str(prmt(prmt_index).MinBranchLength);...
    num2str(prmt(prmt_index).ds); num2str(prmt(prmt_index).npnts); num2str(prmt(prmt_index).initial_index); ...
    num2str(prmt(prmt_index).brightness)};


input=inputdlg({'Batch number'; 'Number of filaments'; 'Interrogation windows offset (x)'; ...
    'Interrogation windows offset (y)'; 'Interrogation windows size (x)'; 'Interrogation windows size (y)'; ...
    'Thickness of the filament'; 'Threshold for differentiating the tubular structure from the background';...
    'Lengthscale of noise'; 'Typical object size'; 'Threshhold for setting pixels to 0 after convolution with gaussian kernel';...
    'Sensitivity for adaptive image binarization'; 'Minimum branch length'; 'Constant segment length for fitting'; ...
    'Number of points per interval in the recontructed B-spline centerline'; 'Is this the initial calculating frame of the *.tif set?'; ...
    'Image intensity enhancement ratio'}, 'Parameters to be optimized', 1, the_inputs,'on');

% batch number where storing the results
prmt_tmp(prmt_index).batch = str2double(input{1,1});
% number of filaments in the current image sequence
prmt_tmp(prmt_index).FilNum = str2double(input{2,1});
% set the 'interrogation windows' offset
prmt_tmp(prmt_index).xskip = str2double(input{3,1});  % right(+) left(-)
prmt_tmp(prmt_index).yskip = str2double(input{4,1});  % up(+) down(-)
% set the 'interrogation windows' size
prmt_tmp(prmt_index).xwin = str2double(input{5,1});
prmt_tmp(prmt_index).ywin = str2double(input{6,1});


% define some parameters for the fibermetric filtering
% fibermetric works better if the elongated object has a constant thickness across the image
prmt_tmp(prmt_index).thickness = str2double(input{7,1}); % thickness of the filament in px
prmt_tmp(prmt_index).structsensitivity = str2double(input{8,1}); % threshold for differentiating the tubular structure from the background
% The default value depends on the data type of image I, and is calculated
% as 0.01*diff(getrangefromclass(I)). For example, the default threshold is
% 2.55 for images of data type uint8, and the default is 0.01 for images of
% data type double with pixel values in the range [0, 1].

% define some parameters for the gaussian blur
prmt_tmp(prmt_index).lnoise = str2double(input{9,1}); % characteristic lengthscale of noise in pixels
prmt_tmp(prmt_index).lobject = str2double(input{10,1}); % typical object size
prmt_tmp(prmt_index).threshold = str2double(input{11,1}); % threshhold for setting pixels to 0 after convolution with gaussian kernel

% define some parameters for morphological operations
prmt_tmp(prmt_index).sensitivity = str2double(input{12,1}); % sensitivity for adaptive image binarization
prmt_tmp(prmt_index).MinBranchLength = str2double(input{13,1}); % minimum branch length, in pixel, to be accepted in the skel function

% define some parameters for b-spline fitting procedure
prmt_tmp(prmt_index).ds = str2double(input{14,1}); % constant segment length (in px) used for spacing the reference points in the B-spline fitting
prmt_tmp(prmt_index).npnts = str2double(input{15,1}); % number of points per interval in the recontructed B-spline centerline

prmt_tmp(prmt_index).initial_index = logical(str2double(input{16,1}));

% define a parameters to make the fiber_img brighter
prmt_tmp(prmt_index).brightness = str2double(input{17,1});