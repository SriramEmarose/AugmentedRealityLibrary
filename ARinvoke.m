//=============================================================================
/// \file		ARinvoke.m
///
/// Implements 2D Augmented Reality using MATLAB
///
/// \date	17 August 2015	
/// \author    Sriram Emarose
/// 
/// \ contact: sriram.emarose@gmail.com
//=============================================================================

function ARinvoke(TargetImage,choice,OverlayObject,imaqdevice,devicenumber)

img=imread(TargetImage);
img=rgb2gray(img);
boxImage=img;
disp('   ');
disp('   ');
disp('Sriram`s Augmented Reality Library Loaded');
disp('   ');
disp('Target Image Loaded');

switch choice
    
    case 1
        im2=imread(OverlayObject);
        disp('Overlay Image Loaded');
        
    case 2
        
        video = vision.VideoFileReader(OverlayObject);
        disp('Overlay Video Loaded');
end


% if (nargin==3)

 disp('Loading Image Acquisition Device....');
vid1 = videoinput(imaqdevice,devicenumber); % RGB camera
srcColor = getselectedsource(vid1);
vid1.FramesPerTrigger = 1;
fnum=800;
vid1.TriggerRepeat = fnum;
triggerconfig(vid1,'manual');
start(vid1);
pause(5);




%%
videoPlayer1 = vision.VideoPlayer;
videoPlayer = vision.VideoPlayer;


for i = 1:fnum+1
    
    trigger(vid1)
    
    if(choice==2)
    video1 = step(video);
    end
    
    sceneImage1=getdata(vid1);
    sceneImage1=sceneImage1(:,:,:,1);
    %     imshow(sceneImage);
    %
    videoFrame=rgb2gray(sceneImage1);
    
    sceneImage=videoFrame;
    
    
    
    boxPoints = detectSURFFeatures(boxImage);
    scenePoints = detectSURFFeatures(sceneImage);
    
    
    
    [boxFeatures, boxPoints] = extractFeatures(boxImage, boxPoints);
    [sceneFeatures, scenePoints] = extractFeatures(sceneImage, scenePoints);
    
    boxPairs = matchFeatures(boxFeatures, sceneFeatures);
    
    
    matchedBoxPoints = boxPoints(boxPairs(:, 1), :);
    matchedScenePoints = scenePoints(boxPairs(:, 2), :);
    %       ff=0;
    ff=size(boxPairs);
    step(videoPlayer,sceneImage1);
    
    if ff(1)>2
        [tform, inlierBoxPoints, inlierScenePoints] = ...
            estimateGeometricTransform(matchedBoxPoints, matchedScenePoints, 'affine');
        
        
        
        boxPolygon = [1, 1;...                           % top-left
            size(boxImage, 2), 1;...                 % top-right
            size(boxImage, 2), size(boxImage, 1);... % bottom-right
            1, size(boxImage, 1);...                 % bottom-left
            1, 1];                   % top-left again to close the polygon
        
        
        
        newBoxPolygon = transformPointsForward(tform, boxPolygon);
        
        
        Poly = [newBoxPolygon(1,1) newBoxPolygon(1,2) newBoxPolygon(2,1) newBoxPolygon(2,2) ...
            newBoxPolygon(3,1) newBoxPolygon(3,2) newBoxPolygon(4,1) newBoxPolygon(4,2)...
            newBoxPolygon(5,1) newBoxPolygon(5,2)];
        
        asd=insertShape(sceneImage1,'Polygon',Poly,'Color','green');
        
        
        
        if (newBoxPolygon(1,1)> newBoxPolygon(3,1))
            xx= newBoxPolygon(1,1)- newBoxPolygon(3,1);
        else
            xx= newBoxPolygon(3,1)-newBoxPolygon(1,1);
        end
        
        
        if (newBoxPolygon(1,2)> newBoxPolygon(3,2))
            yy=newBoxPolygon(1,2)-newBoxPolygon(3,2);
        else
            
            yy=newBoxPolygon(3,2)-newBoxPolygon(1,2);
        end
        xx=ceil(xx);
        yy=ceil(yy);
        H = vision.AlphaBlender('Opacity',1,'Location', [ceil(newBoxPolygon(1,1)) ceil(newBoxPolygon(1,2))]);
        
        
        if(choice==1)   %Image overlay
            
            im22=imresize(im2,[yy xx]);
            Y = step(H,sceneImage1,im22);
        end
        
        if(choice==2)  %Video Overlay
            videooverlay=imresize(video1,[yy xx]);
            videooverlay=uint8(videooverlay*255);
            
            Y = step(H,sceneImage1,videooverlay);
            %    imshow(Y);
        end
        
        step(videoPlayer1,Y);
        
        %         pause(1.5);
    end
    
    
    
    %       release(video);
end
stop(vid1);
end

