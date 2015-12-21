function str = prettybytes(bytes)
	%  - Damien Loterie (06/2014)
    bytes = double(bytes);
    suffixes = {' bytes','kb','Mb','Gb','Tb'};
    i = 1;
    while round(bytes)>=1000 && (i+1)<=numel(suffixes)
       bytes = bytes/1024;
       i = i+1;
    end
    
    bytes = round(bytes*10)/10;
    str = [num2str(bytes) suffixes{i}];
end

