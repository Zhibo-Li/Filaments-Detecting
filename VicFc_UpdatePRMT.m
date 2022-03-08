function prmt_new = update_parameters(imgn,prmt,prmt_index)

[~,blur_img,~,L] = skeletonization_of_single_frame(imgn,prmt,prmt_index);
% figure('Name','original image');
% imshow(imgn,[])
% figure('Name','fibermetric filtering');
% imshow(fiber_img,[])
% figure('Name','blurred image');
% imshow(blur_img,[])
% figure('Name','binarized image');
% imshow(BI)
figure('Name','skeletonization results');
imshow(labeloverlay(blur_img,L,'Transparency',0))

try
    Inputnum = input('Do you feel satisfied?: \n 1 = Yes \n 2 = No \n');
    close all;
    switch Inputnum
        case 1
            prmt_new = prmt;
        case 2
            [prmt_new, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index);
            [~,blur_img,BI,L] = skeletonization_of_single_frame(imgn,prmt_new,prmt_index_tmp);
            % figure('Name','original image');
            % imshow(imgn,[])
            % figure('Name','fibermetric filtering');
            % imshow(fiber_img,[])
            % figure('Name','blurred image');
            % imshow(blur_img,[])
            % figure('Name','binarized image');
            % imshow(BI)
            figure('Name','binarized image');
            imshow(BI)
            figure('Name','skeletonization results');
            imshow(labeloverlay(blur_img,L,'Transparency',0))
             
            prmt = prmt_new;
            prmt_new = update_parameters(imgn,prmt,prmt_index);

            %             elongated_objects_trajectories_optimization(imgn,prmt_new,prmt_index_tmp);
        otherwise
            msgbox('Be careful and input again!!');  % To avoid other 'wrong' inputs.
            Inputnum = input('\n \n \n \n Be careful and input again!!! \n Do you feel satisfied?: \n 1 = Yes \n 2 = No \n');
            switch Inputnum
                case 1
                    prmt_new = prmt;
                case 2
                    [prmt_new, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index);
                    [~,blur_img,BI,L] = skeletonization_of_single_frame(imgn,prmt_new,prmt_index_tmp);
                    % figure('Name','original image');
                    % imshow(imgn,[])
                    % figure('Name','fibermetric filtering');
                    % imshow(fiber_img,[])
                    % figure('Name','blurred image');
                    % imshow(blur_img,[])
                    % figure('Name','binarized image');
                    % imshow(BI)
                    figure('Name','binarized image');
                    imshow(BI)
                    figure('Name','skeletonization results');
                    imshow(labeloverlay(blur_img,L,'Transparency',0))

                    prmt = prmt_new;
                    prmt_new = update_parameters(imgn,prmt,prmt_index);
            end
    end

catch
    msgbox('Be careful and input again!!');  % To avoid other 'wrong' inputs.
    Inputnum = input('\n \n \n \n Be careful and input again!!! \n Do you feel satisfied?: \n 1 = Yes \n 2 = No \n');
    switch Inputnum
        case 1
            prmt_new = prmt;
        case 2
            [prmt_new, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index);
            [~,blur_img,BI,L] = skeletonization_of_single_frame(imgn,prmt_new,prmt_index_tmp);
            % figure('Name','original image');
            % imshow(imgn,[])
            % figure('Name','fibermetric filtering');
            % imshow(fiber_img,[])
            % figure('Name','blurred image');
            % imshow(blur_img,[])
            % figure('Name','binarized image');
            % imshow(BI)
            figure('Name','binarized image');
            imshow(BI)
            figure('Name','skeletonization results');
            imshow(labeloverlay(blur_img,L,'Transparency',0))

            prmt = prmt_new;
            prmt_new = update_parameters(imgn,prmt,prmt_index);
    end
end
