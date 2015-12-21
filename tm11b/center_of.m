function [xc,yc] = center_of(x,y)
    % This function gives a definition of the center of an image.
    % The purpose of having a separate function for this is to ensure a
    % consistent definition in all the other functions.
    %
    % Give the (x,y) size of an image, and this function returns the center
    % (xc,yc). The center is given in MATLAB coordinates (first index is 1).
    % The definition used here is the same as for the DC component in an
    % fftshifted image.
    %
    %  - Damien Loterie (03/2015)
    
    narginchk(1,2);
    if nargin<2
        xc = zeros(size(x),'like',x);
        for i=1:numel(x)
            if mod(x(i),2)==0
                xc(i) = x(i)/2 + 1;
            elseif mod(x(i),2)==1
                xc(i) = (x(i) + 1)/2;
            else
                error('Unexpected input: the size of the image should be an integer');
            end 
        end
    else
        % x-coordinate
        if mod(x,2)==0
            xc = x/2 + 1;
        elseif mod(x,2)==1
            xc = (x + 1)/2;
        else
            error('Unexpected input: the size of the image should be an integer');
        end 
        
        % y-coordinate
        if mod(y,2)==0
            yc = y/2 + 1;
        elseif mod(y,2)==1
            yc = (y + 1)/2;
        else
            error('Unexpected input: the size of the image should be an integer');
        end 
    end




end

