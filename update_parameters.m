function [prmt_new, Good_case_out] = update_parameters(imgn,prmt, prmt_index, Good_case_in)

%% Recursive function to update the parameters for the image processing.

[~,blur_img,~,L,lzero] = skeletonization_of_single_frame(imgn,prmt,prmt_index);
% figure('Name','original image');
% imshow(imgn,[])
% figure('Name','fibermetric filtering');
% imshow(fiber_img,[])
% figure('Name','blurred image');
% imshow(blur_img,[])
% figure('Name','binarized image');
% imshow(BI)
figure('Name',['skeletonization results no.', num2str(prmt(prmt_index).frame_no)], 'Position', [400 100 800 800]);
subplot(2,1,1);
imshow(labeloverlay(imadjust(imgn(lzero+1:end-lzero,lzero+1:end-lzero)),L,'Transparency',0,'Colormap','spring'));
subplot(2,1,2);
imshow(labeloverlay(blur_img,L,'Transparency',0,'Colormap','spring'));

try
    Inputnum = input('Do you feel satisfied?: \n 1 = Yes! \n 2 = No! \n 7 = Not good but accepted! \n');
    close all;
    switch Inputnum
        case 1
            prmt_new = prmt;
            Good_case_out = Good_case_in;
            Good_case_out(size(Good_case_in, 2) + 1) = prmt_index + prmt(1).frame_no - 1;   % The real index in the set of the images.
        case 2
            [prmt_new, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index);
            [~,blur_img,BI,L,~] = skeletonization_of_single_frame(imgn,prmt_new,prmt_index_tmp);
            % figure('Name','original image');
            % imshow(imgn,[])
            % figure('Name','fibermetric filtering');
            % imshow(fiber_img,[])
            % figure('Name','blurred image');
            % imshow(blur_img,[])
            % figure('Name','binarized image');
            % imshow(BI)
            figure('Name',['binarized image no.', num2str(prmt(prmt_index).frame_no)]);
            imshow(BI)
            figure('Name','skeletonization results');
            imshow(labeloverlay(blur_img,L,'Transparency',0,'Colormap','spring'))

            prmt = prmt_new;
            [prmt_new, Good_case_out]= update_parameters(imgn,prmt,prmt_index,Good_case_in);
        case 7
            prmt_new = prmt;
            Good_case_out = Good_case_in;
        otherwise
            msgbox('Be careful and input again!!');  % To avoid other 'wrong' inputs.
            Inputnum = input(['\n \n \n \n Be careful and input again!!! \n ' ...
                'Do you feel satisfied?: \n 1 = Yes! \n 2 = No! \n 7 = Not good but accepted! \n']);
            switch Inputnum
                case 1
                    prmt_new = prmt;
                    Good_case_out = Good_case_in;
                    Good_case_out(size(Good_case_in, 2) + 1) = prmt_index + prmt(1).frame_no - 1;
                case 2
                    [prmt_new, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index);
                    [~,blur_img,BI,L,~] = skeletonization_of_single_frame(imgn,prmt_new,prmt_index_tmp);
                    % figure('Name','original image');
                    % imshow(imgn,[])
                    % figure('Name','fibermetric filtering');
                    % imshow(fiber_img,[])
                    % figure('Name','blurred image');
                    % imshow(blur_img,[])
                    % figure('Name','binarized image');
                    % imshow(BI)
                    figure('Name',['binarized image no.', num2str(prmt(prmt_index).frame_no)]);
                    imshow(BI)
                    figure('Name','skeletonization results');
                    imshow(labeloverlay(blur_img,L,'Transparency',0,'Colormap','spring'))
                    prmt = prmt_new;
                    [prmt_new, Good_case_out]= update_parameters(imgn,prmt,prmt_index,Good_case_in);
                case 7
                    prmt_new = prmt;
                    Good_case_out = Good_case_in;
            end
    end

catch
    msgbox('Be careful and input again!!');  % To avoid other 'wrong' inputs.
    Inputnum = input(['\n \n \n \n Be careful and input again!!! \n Do you ' ...
        'feel satisfied?: \n 1 = Yes! \n 2 = No! \n 7 = Not good but accepted! \n']);
    switch Inputnum
        case 1
            prmt_new = prmt;
            Good_case_out = Good_case_in;
            Good_case_out(size(Good_case_in, 2) + 1) = prmt_index + prmt(1).frame_no - 1;
        case 2
            [prmt_new, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index);
            [~,blur_img,BI,L,~] = skeletonization_of_single_frame(imgn,prmt_new,prmt_index_tmp);
            % figure('Name','original image');
            % imshow(imgn,[])
            % figure('Name','fibermetric filtering');
            % imshow(fiber_img,[])
            % figure('Name','blurred image');
            % imshow(blur_img,[])
            % figure('Name','binarized image');
            % imshow(BI)
            figure('Name',['binarized image no.', num2str(prmt(prmt_index).frame_no)]);
            imshow(BI)
            figure('Name','skeletonization results');
            imshow(labeloverlay(blur_img,L,'Transparency',0,'Colormap','spring'))
            prmt = prmt_new;
            [prmt_new, Good_case_out]= update_parameters(imgn,prmt,prmt_index,Good_case_in);
        case 7
            prmt_new = prmt;
            Good_case_out = Good_case_in;
    end
end
