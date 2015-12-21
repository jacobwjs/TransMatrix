function map = labview(map_size, black_point, white_point)
	% Labview colormap
	%   - Damien Loterie (10/2014)
	
    % Default arguments
    if nargin<1
        map_size = 2^8;
    end
    if nargin<2
        black_point=0;
    end
    if nargin<3
        white_point=1;
    end

    % Color map
    table = [   0              0         0
                0.0353         0    0.7843
                0         0.8235    0.8588
                0.0392    1.0000         0
                1.0000    0.9020         0
                1.0000    0.4980         0
                0.7059    0.0314         0
                1.0000    1.0000    1.0000  ];
    
    pos = (black_point:((white_point-black_point)/(size(table,1)-1)):white_point)';
    
    % Black point & white point options
    if black_point~=0
        pos = [0; pos];
        table = [table(1,:); table];
    end
    if white_point~=1
        pos = [pos;1];
        table = [table; table(end,:)];
    end
    
    % Interpolation
    map = interp1(pos,...
                  table,...
                  0:1/(map_size-1):1,...
                  'linear');

    % Correction
    map(map>1) = 1;
    map(map<0) = 0;
end



%     % Original table
%     table = [   0              0         0         0
%                 0.2311    0.0353         0    0.7843
%                 0.3697         0    0.8235    0.8588
%                 0.4787    0.0392    1.0000         0
%                 0.6063    1.0000    0.9020         0
%                 0.7338    1.0000    0.4980         0
%                 0.8799    0.7059    0.0314         0
%                 1.0000    1.0000    1.0000    1.0000];
