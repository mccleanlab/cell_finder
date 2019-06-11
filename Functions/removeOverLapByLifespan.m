function [centersNew,radiiNew]=removeOverByLapLifespan(centers,radii,lifespan,tol)
% Modified from the function RemoveOverlap() by Elad
% mathworks.com/matlabcentral/fileexchange/42370-circles-overlap-remover

% This function deals with overlaping circles by removing the circle with the shortest lifespan:
% centers - (x,y) circles centers.
% radii - the circles radius
% tol - tolerance for an overlap, im number of pixels.
% Uses the function snip() from the file exchange.

l=length(centers);
for i= 1: l
    s=i+1;
    for j=s:l
        d_ij=sqrt((centers(i,1)-centers(j,1)).^2+(centers(i,2)-centers(j,2)).^2);
        k=radii(i)+radii(j)-tol;
        if d_ij < k && radii(j)>0
            if lifespan(i)>lifespan(j)
                centers(j,1)=0;
                centers(j,2)=0;
                radii(j)=0;
            else
                centers(i,1)=0;
                centers(i,2)=0;
                radii(i)=0;
            end
        end
    end
end
%create new circles vectors using snip()
centersNew=snip(centers,'0');
radiiNew=snip(radii,'0');
