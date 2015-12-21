function [f,df] = mincircle_of(~,~,r)
	%  - Damien Loterie (03/2014)
    f = r;
%     df = [0,0,r];
    df = [0,0,1];
end

