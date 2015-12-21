function res = format_size(format)
    % res = format_size(format)
	%   - Damien Loterie (06/2014)

    switch format
        % char
        case 'uint8'
            res = 1;
        case 'uchar'
            res = 1;
        case 'unsigned char'
            res = 1;
        case 'int8'
            res = 1;
        case 'integer*1'
            res = 1;
        case 'schar'
            res = 1;
        case 'signed char'
            res = 1;
        case 'char*1'
            res = 1;
            
        % short
        case 'uint16'
            res = 2;
        case 'ushort'
            res = 2;
        case 'int16'
            res = 2;
        case 'integer*2'
            res = 2;
        case 'short'
            res = 2;
        
        % int32
        case 'uint'
            res = 4;
        case 'uint32'
            res = 4;
        case 'ulong'
            res = 4;
        case 'int'
            res = 4;
        case 'int32'
            res = 4;
        case 'integer*4'
            res = 4;
        case 'long'
            res = 4;
            
        % int64    
        case 'uint64'
            res = 8;
        case 'int64'
            res = 8;
        case 'integer*8'
            res = 8;

        % float
        case 'single'
            res = 4;
        case 'float'
            res = 4;
        case 'float32'
            res = 4;
        case 'real*4'
            res = 4;
        
        % double    
        case 'double'
            res = 8;
        case 'float64'
            res = 8;
        case 'real*8'
            res = 8;

        % unrecognized    
        otherwise
            error('Size cannot be determined for this format.');
    end
end

