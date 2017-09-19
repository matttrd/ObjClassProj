function [Q] = get3Dcoord(P,q)
%[Q] = get3Dcoord(P,q)
%Returns coordinates referred to world from pixel 2D [x,y] coordinates.
%Note that only ground coordinates will be returned, so the input must be
%a point that lies on the ground plane.

M_Mat = P(:,1:3);                 % Matrix M is the "top-front" 3x3 part 
p_4 = P(:,4);                     % Vector p_4 is the "top-rear" 1x3 part 
C_tilde = - M_Mat\p_4;            % calculate C_tilde 
q = [q 1]';
X_tilde = M_Mat\q;
mue_N = -C_tilde(3)/X_tilde(3);
Q = mue_N*(M_Mat\q)+C_tilde;
Q(3) = 0;                         % to avoid rounding problems
end

