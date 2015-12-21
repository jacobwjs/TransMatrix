function [c, ceq, gradc, gradceq] = mincircle_nlc(x0,y0,r,P)
	%  - Damien Loterie (03/2014)
    c   = (x0 - P(:,1)).^2 + (y0 - P(:,2)).^2 - r^2;
    ceq = [];
    
    if nargout > 2
       gradc = [2*(x0-P(:,1).');
                2*(y0-P(:,2).');
                -2*repmat(r,[1 size(P,1)])];
       gradceq = [];
    end
    
end

