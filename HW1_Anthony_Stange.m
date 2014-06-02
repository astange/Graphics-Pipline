% Programmed for MatLab by Anthony Stange
% I am using the left hand convention
% Make variables for world space xyz position and RGB light source for specular and diffuse
% RGB color of ambient light
% xyz position of camera and xyz point that the camera is looking at
% world space position and orientation of object
% field of view and near and far distances of viewing frustum
diffSpecLightWorldPos = [0 10 50];
diffSpecLightWorldRGB = [.3 .7 .5];
ambWorldLightRGB = [.3 .7 .8];
sBrightness = 5;
emissObjectRGB = [.3 .2 .3];
ambientObjectRGB = [.2 .3 .4];
diffObjectRGB = [.4 .3 .3];
specObjectRGB = [.4 .5 .3];
xyzPosCamera = [0 50 50];
xyzPointCamera = [50 70 250];
worldPosObject = [15 50 125];
orientObject = [30 30 60];
upVector = [0,1,0];
aspectRatio = 1;
fieldOfView = 50;
nearDist = 30;
farDist = 400;

%Predefined variables done. Lets get the matrices set up.

%Create Rotation and Translation Matrices and multiply them.
xRot = orientObject(1,1);
yRot = orientObject(1,2);
zRot = orientObject(1,3);
xRotMatrix = [1,0,0,0;0,cos(xRot),sin(xRot),0;0,-sin(xRot),cos(xRot),0;0,0,0,1];
yRotMatrix = [cos(yRot),0,-sin(yRot),0;0,1,0,0;sin(yRot),0,cos(yRot),0;0,0,0,1];
zRotMatrix = [cos(zRot),sin(zRot),0,0;-sin(zRot),cos(zRot),0,0;0,0,1,0;0,0,0,1];

translationMatrix = [1,0,0,0;0,1,0,0;0,0,1,0;worldPosObject,1];

rotAndTransMatrix = xRotMatrix * yRotMatrix;
rotAndTransMatrix = rotAndTransMatrix * zRotMatrix;
rotAndTransMatrix = rotAndTransMatrix * translationMatrix;

%Setup View Matrix
zViewAxis = (xyzPointCamera - xyzPosCamera)/norm(xyzPointCamera - xyzPosCamera);
xViewAxis = cross(upVector, zViewAxis)/norm(cross(upVector, zViewAxis));
yViewAxis = cross(zViewAxis, xViewAxis);

viewMatrix = [xViewAxis(1,1), yViewAxis(1,1), zViewAxis(1,1), 0;...
              xViewAxis(1,2), yViewAxis(1,2), zViewAxis(1,2), 0;...
              xViewAxis(1,3), yViewAxis(1,3), zViewAxis(1,3), 0;...
              -dot(xViewAxis,xyzPosCamera),-dot(yViewAxis,xyzPosCamera),-dot(zViewAxis,xyzPosCamera),1];

%Setup Persp Matrix  
yScale = cot(fieldOfView/2);
xScale = yScale/aspectRatio;
perspMatrix = [xScale,0,0,0;...
               0,yScale,0,0;...
               0,0,farDist/(farDist-nearDist),1;...
               0,0,-(farDist*nearDist)/(farDist-nearDist),0];
               
%Combine View and Multiply Matrices
perspAndViewMatrix = viewMatrix * perspMatrix;          
              
%Import Image delimited by tabs
%Image was converted to have xyz and w for each vertices of the triangle
shuttleImage = dlmread('shuttleImage.DAT');

%The Vertices have been transfered to world coordinates
shuttleImage = shuttleImage * rotAndTransMatrix;

%Lighting calculations done here
sizeVec = size(shuttleImage);
colorMatrix = zeros(sizeVec(1,1)/3,3);

imageIndex = 1;
colorIndex = 1;
while imageIndex < sizeVec(1,1) + 1
    tempVector1 = shuttleImage(imageIndex + 1,1:3) - shuttleImage(imageIndex,1:3);
    tempVector2 = shuttleImage(imageIndex + 2, 1:3) - shuttleImage(imageIndex, 1:3);
    normalVector = cross(tempVector1,tempVector2);
    normalVector = normalVector/norm(normalVector);
    
    centerPoint = (shuttleImage(imageIndex, 1:3) + shuttleImage(imageIndex + 1, 1:3) + shuttleImage(imageIndex + 2, 1:3))/3;
    
    lVector = diffSpecLightWorldPos - centerPoint;
    lVector = lVector/norm(lVector);
    
    eyeVector = xyzPosCamera - centerPoint;
    eyeVector = eyeVector/norm(eyeVector);
    
    halfVector = (eyeVector + lVector)/sum(eyeVector + lVector);
    
    diffuseLight = max(dot(lVector,normalVector),0) * (diffObjectRGB.*diffSpecLightWorldRGB);
    ambientLight = ambientObjectRGB.*ambWorldLightRGB;
    specularLight = ((max(dot(normalVector,halfVector),0))^sBrightness) * (specObjectRGB.*diffSpecLightWorldRGB);
  
    colorMatrix(colorIndex, 1:3) = emissObjectRGB + ambientLight + diffuseLight + specularLight;
    imageIndex = imageIndex + 3;
    colorIndex = colorIndex + 1;
end

%Viewing and projection already combined so lets get that done here
shuttleImage = shuttleImage * perspAndViewMatrix;

for i=1:sizeVec(1,1)
    shuttleImage(i,1:4) = shuttleImage(i,1:4)/shuttleImage(i,4);
end

%Z-Sorting
colorIndex = 1;
imageIndex = 1;
zSortedArray = [];
while imageIndex < sizeVec(1,1) + 1
    vertex1 = shuttleImage(imageIndex,1:3);
    vertex2 = shuttleImage(imageIndex + 1, 1:3);
    vertex3 = shuttleImage(imageIndex + 2, 1:3);
    avgZ = (vertex1(1,3) + vertex2(1,3) + vertex3(1,3))/3;
    
    if(avgZ > 1 || avgZ < 0)
        imageIndex = imageIndex + 3;
        colorIndex = colorIndex + 1;
        continue;
    end
    
    zSortedArray = [zSortedArray; [vertex1(1,1),vertex2(1,1),vertex3(1,1),vertex1(1,2),vertex2(1,2),vertex3(1,2), avgZ, colorIndex]];
    imageIndex = imageIndex + 3;
    colorIndex = colorIndex + 1;
end

zSortedArray = sortrows(zSortedArray,7);
zSortedArray = flip(zSortedArray);

%Drawing the image onto the screen
axis([-1 1 -1 1])
axis square

i = 1;
sizeVec = size(zSortedArray);
while i < sizeVec(1,1) + 1
    patch([zSortedArray(i,1) zSortedArray(i,2) zSortedArray(i,3)],...
        [zSortedArray(i,4) zSortedArray(i,5) zSortedArray(i,6)],...
        colorMatrix(zSortedArray(i,8),1:3))
    i = i + 1;
end



%Lazy way I used to convert the shuttle image to format that would make it
%easier to work with

%sizeVec = size(shuttleImage)
%numRows = sizeVec(1,1)

%vertexCell = zeros(sizeVec(1,1)*3,4)

%vertexIndex = 1
%for i=1:numRows
%    vertexCell(vertexIndex,1:3) = shuttleImage(i,1:3)
%    vertexCell(vertexIndex,4) = 1
%    vertexIndex = vertexIndex + 1
%    vertexCell(vertexIndex,1:3) = shuttleImage(i,4:6)
%    vertexCell(vertexIndex,4) = 1
%    vertexIndex = vertexIndex + 1
%    vertexCell(vertexIndex,1:3) = shuttleImage(i,7:9)
%    vertexCell(vertexIndex,4) = 1
%    vertexIndex = vertexIndex + 1
%end
%
%save -ascii -tabs 'shuttleImage.DAT' vertexCell