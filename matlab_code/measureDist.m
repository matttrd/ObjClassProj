function distance = measureDist(P,imgOriginal)
% [Q,q] = measureDist(P,img)
% measure distance in the ground plane from 2 points on the ground and returns
% the distance in m

M_Mat = P(:,1:3);                 % Matrix M is the "top-front" 3x3 part 
p_4 = P(:,4);                     % Vector p_4 is the "top-rear" 1x3 part 
C_tilde = - M_Mat\p_4;            % calculate C_tilde 

dim = 1;
if (length(imgOriginal) > 640)
    dim = 1.5;
end

figure(99)
while true
    img = imgOriginal;
    imshow(img);
    title('Select first point on the ground plane')
    [xA,yA] = ginput(1);
    img = insertObjectAnnotation(img,'circle',[xA,yA 4],'A');
    qA = [xA yA 1]';
    X_tilde = M_Mat\qA;
    mue_N = -C_tilde(3)/X_tilde(3);
    Q1 = mue_N*(M_Mat\qA)+C_tilde;
    Q1(3) = 0;       % to avoid rounding problems

    imshow(img);
    drawnow;
    title('Select second point on the ground plane')
    [xB,yB] = ginput(1);
    img = insertObjectAnnotation(img,'circle',[xB,yB,4],'B');
    img = insertShape(img,'Line',[xA yA xB yB]);
    qB = [xB yB 1]';
    X_tilde = M_Mat\qB;
    mue_N = -C_tilde(3)/X_tilde(3);
    Q2 = mue_N*(M_Mat\qB)+C_tilde;
    Q2(3) = 0;       % to avoid rounding problems

    distance = norm(Q2-Q1);
    img = insertText(img,[xA+xB yA+yB]/2,[num2str(distance) ' m'],'FontSize',12*dim);
    imshow(img);
    drawnow;
    cont = input('Another measurement? [ [] = yes, other = no ]');
    if size(cont) ~= 0
        break;
    end
end
end