% Complex correlation coefficient
% - Damien Loterie (11/2013)

function res = corr2c(A, B, noshift)
    if nargin<3
        noshift = false;
    end 
    
    if isinteger(A) || isinteger(B)
       A = double(A);
       B = double(B);
    end
       
    if strcmpi(noshift,'noshift') || noshift==true
        A_shift = A(:);
        B_shift = B(:);
    else
        A_shift = A(:) - mean(A(:));
        B_shift = B(:) - mean(B(:));
    end
    
    A_norm = sqrt(sum(A_shift .* conj(A_shift)));
    B_norm = sqrt(sum(B_shift .* conj(B_shift)));
    
    if (A_norm~=0 || B_norm~=0)
        res = sum(conj(A_shift) .* B_shift)/(A_norm*B_norm);
    else
        res = 0;
    end
end

