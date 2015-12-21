% [pxy, Rxy, Rxx, Ryy] = corr2c2(x, y, shift)
% Complex correlation coefficient.
% Operates on the first dimension.
% Can compare one vector to many vectors.
% - Damien Loterie (07/2014)

function [pxy, Rxy, Rxx, Ryy] = corr2c2(x, y, shift)
    if ~isfloat(x) || ~isfloat(y)
       x = double(x);
       y = double(y);
    end
       
    if nargin>=3 && shift==true
        x = bsxfun(@minus, x, mean(x,1));
        y = bsxfun(@minus, y, mean(y,1));
    end
    
    Rxy = sum(bsxfun(@times, x, conj(y)), 1);
    Rxx = sum(real(x).^2 + imag(x).^2, 1);
    Ryy = sum(real(y).^2 + imag(y).^2, 1);
    
    pxy = Rxy./(sqrt(Rxx) .* sqrt(Ryy));
end

