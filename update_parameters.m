function [prmt_new, Good_case_out] = update_parameters(imgn,prmt_input, prmt_index, Good_case_in)

%% Recursive function to update the parameters for the image processing.

[fiber_img,blur_img,BI,L,lzero,prmt] = skeletonization_of_single_frame(imgn,prmt_input,prmt_index); % retain 'lzero' to remind that 'gaussian_blur' function will shrink the image.
figure('Name',['skeletonization results no.', num2str(prmt(prmt_index).frame_start)], 'Position', [400 100 800 800]);
tiledlayout(2,2,'TileSpacing','Compact','Padding','Compact');
nexttile
imshow(labeloverlay(imadjust(imgn(lzero+1:end-lzero,lzero+1:end-lzero)),L,'Transparency',0,'Colormap','spring')); title('original image') 
nexttile
imshow(labeloverlay(imadjust(fiber_img(lzero+1:end-lzero,lzero+1:end-lzero)),L,'Transparency',0,'Colormap','spring')); title('fibermetric filtering') 
nexttile
imshow(labeloverlay(blur_img,L,'Transparency',0,'Colormap','spring')); title('blurred image') 
nexttile
imshow(labeloverlay(double(BI),L,'Transparency',0,'Colormap','spring')); title('binarized image')
pause(0.1)

% To set a range of images that don't need to be confirmed every time.
msgbox('Check if you need this part first: update_parameters.m, line 20 !!');
if max(Good_case_in) < 200 || max(Good_case_in) > 50
    close all;
    prmt_new = prmt;
    Good_case_out = Good_case_in;
    Good_case_out(size(Good_case_in, 2) + 1) = prmt_index + prmt(1).frame_start - 1;   
else
    try
        Inputnum = input('Do you feel satisfied?: \n 1 = Yes! \n 2 = No! \n 7 = Not good but accepted! \n');
        close all;
        switch Inputnum
            case 1
                prmt_new = prmt;
                Good_case_out = Good_case_in;
                Good_case_out(size(Good_case_in, 2) + 1) = prmt_index + prmt(1).frame_start - 1;   % The real index in the set of the images.
            case 2
                [prmt_new, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index);
                [fiber_img,blur_img,BI,L,lzero,prmt] = skeletonization_of_single_frame(imgn,prmt_new,prmt_index_tmp);

                figure('Name',['skeletonization results no.', num2str(prmt(prmt_index).frame_start)], 'Position', [400 100 800 800]);
                tiledlayout(2,2,'TileSpacing','Compact','Padding','Compact');
                nexttile
                imshow(labeloverlay(imadjust(imgn(lzero+1:end-lzero,lzero+1:end-lzero)),L,'Transparency',0,'Colormap','spring')); title('original image')
                nexttile
                imshow(labeloverlay(imadjust(fiber_img(lzero+1:end-lzero,lzero+1:end-lzero)),L,'Transparency',0,'Colormap','spring')); title('fibermetric filtering')
                nexttile
                imshow(labeloverlay(blur_img,L,'Transparency',0,'Colormap','spring')); title('blurred image')
                nexttile
                imshow(labeloverlay(double(BI),L,'Transparency',0,'Colormap','spring')); title('binarized image')

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
                        Good_case_out(size(Good_case_in, 2) + 1) = prmt_index + prmt(1).frame_start - 1;
                    case 2
                        [prmt_new, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index);
                        [fiber_img,blur_img,BI,L,lzero,prmt] = skeletonization_of_single_frame(imgn,prmt_new,prmt_index_tmp);

                        figure('Name',['skeletonization results no.', num2str(prmt(prmt_index).frame_start)], 'Position', [400 100 800 800]);
                        tiledlayout(2,2,'TileSpacing','Compact','Padding','Compact');
                        nexttile
                        imshow(labeloverlay(imadjust(imgn(lzero+1:end-lzero,lzero+1:end-lzero)),L,'Transparency',0,'Colormap','spring')); title('original image')
                        nexttile
                        imshow(labeloverlay(imadjust(fiber_img(lzero+1:end-lzero,lzero+1:end-lzero)),L,'Transparency',0,'Colormap','spring')); title('fibermetric filtering')
                        nexttile
                        imshow(labeloverlay(blur_img,L,'Transparency',0,'Colormap','spring')); title('blurred image')
                        nexttile
                        imshow(labeloverlay(double(BI),L,'Transparency',0,'Colormap','spring')); title('binarized image')

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
                Good_case_out(size(Good_case_in, 2) + 1) = prmt_index + prmt(1).frame_start - 1;
            case 2
                [prmt_new, prmt_index_tmp] = VicFc_Inputs(prmt, prmt_index);

                [fiber_img,blur_img,BI,L,lzero,prmt] = skeletonization_of_single_frame(imgn,prmt_new,prmt_index_tmp);
                figure('Name',['skeletonization results no.', num2str(prmt(prmt_index).frame_start)], 'Position', [400 100 800 800]);
                tiledlayout(2,2,'TileSpacing','Compact','Padding','Compact');
                nexttile
                imshow(labeloverlay(imadjust(imgn(lzero+1:end-lzero,lzero+1:end-lzero)),L,'Transparency',0,'Colormap','spring')); title('original image')
                nexttile
                imshow(labeloverlay(imadjust(fiber_img(lzero+1:end-lzero,lzero+1:end-lzero)),L,'Transparency',0,'Colormap','spring')); title('fibermetric filtering')
                nexttile
                imshow(labeloverlay(blur_img,L,'Transparency',0,'Colormap','spring')); title('blurred image')
                nexttile
                imshow(labeloverlay(double(BI),L,'Transparency',0,'Colormap','spring')); title('binarized image')

                prmt = prmt_new;
                [prmt_new, Good_case_out]= update_parameters(imgn,prmt,prmt_index,Good_case_in);
            case 7
                prmt_new = prmt;
                Good_case_out = Good_case_in;
        end
    end
end
