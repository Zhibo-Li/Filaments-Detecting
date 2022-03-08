function varargout = erase_bckgrd(pathout,tifrooth,tifpath,ROI,imtot,bitimg,backgrdremoval)

%% import images from the folder and calculate the mean

if bitimg==8
    BG = uint8(zeros(ROI(4)+1,ROI(3)+1));
elseif bitimg==16
    BG = uint16(zeros(ROI(4)+1,ROI(3)+1));
else
    disp('images have unknown bit depth \n')
    return
end


if imtot == 1
    
    disp('Tiff file has only 1 frame --> background image cannot be computed \n')
    
    bck = imcrop(imread(tifpath,1),ROI);
    imwrite(bck,strcat(pathout,tifrooth,'-cropped.tif'))
    
    return
    
elseif imtot ~= 1 && backgrdremoval == 2
    
    bck = imcrop(imread(tifpath,1),ROI);
    imwrite(bck,strcat(pathout,tifrooth,'-cropped.tif'));
    for j = 2 : imtot
        bck = imcrop(imread(tifpath,j),ROI);
        imwrite(bck,strcat(pathout,tifrooth,'-cropped.tif'),'writemode', 'append')
    end
    
elseif imtot ~= 1 && backgrdremoval == 1
    
    for j = 1 : imtot
        
        BG = BG + 1/imtot * imcrop(imread(tifpath,j),ROI);
        
    end
    
    %% subtract the background and save the results
    
    bck = imcrop(imread(tifpath,1),ROI)-BG;
    bck(bck<0)=0;
    
    imwrite(bck,strcat(pathout,tifrooth,'-cropped-nobackground.tif'));
    
    for j = 2 : imtot
        
        bck = imcrop(imread(tifpath,j),ROI) - BG;
        bck(bck<0)=0;
        
        imwrite(bck,strcat(pathout,tifrooth,'-cropped-nobackground.tif'),'writemode', 'append')
        
    end
    
end

end

