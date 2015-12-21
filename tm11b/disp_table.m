function disp_table(A, output_function, row_names, col_names)
    % Print data in a nicely formatted table
	%   - Damien Loterie (02/2014)

    % Check input
    if numel(size(A))>2
       error('Invalid dimensions.'); 
    end
    if nargin<2
       output_function = @(n)num2str(n,3);
    end
    if nargin<3
       row_names = 1:size(A,1);
       
    end
    if nargin<4
       col_names = 1:size(A,2);
    end
    if isnumeric(row_names)
       tmp = row_names;
       row_names = cell(size(row_names));
       for i=1:numel(row_names)
          row_names{i} = output_function(tmp(i)); 
       end
    elseif ~iscell(row_names)
        error('Invalid row names');
    end
    if isnumeric(col_names)
       tmp = col_names;
       col_names = cell(size(col_names));
       for i=1:numel(col_names)
          col_names{i} = output_function(tmp(i)); 
       end
    elseif ~iscell(col_names)
        error('Invalid column names');
    end
    if numel(row_names)~=size(A,1)
       error('Invalid number of row names');
    end
    if numel(col_names)~=size(A,2)
       error('Invalid number of column names');
    end
    
    % Row names and col names dimensions
    row_names = row_names(:);
    col_names = col_names(:);
    if size(row_names,1)==1
       row_names = row_names.'; 
    end
    if size(col_names,2)==1
       col_names = col_names.'; 
    end

    % Convert input data
    Astr = cell(size(A));
    for i=1:numel(A)
       Astr{i} = output_function(A(i)); 
    end
    
    % Append row and column names
    Astr = [col_names; Astr];
    Astr = [[' ';row_names], Astr];
    
    % Column sizes
    lengths = zeros(size(Astr));
    for i=1:numel(Astr)
       lengths(i) = length(Astr{i}); 
    end
    col_sizes = max(lengths,[],1);
    
    % Expand with spaces
    for i=1:size(Astr,1)
        for j=1:size(Astr,2)
            str = Astr{i,j};
            str((end+1):col_sizes(j)) = ' ';
            Astr{i,j} = str;
        end
    end
    
    % Join the strings
    row_str = cell(size(Astr,1),1);
    for i=1:size(Astr,1)
        row_str{i} = [Astr{i,1} ' |'];
        for j=2:size(Astr,2)
            row_str{i} = [row_str{i} ' ' Astr{i,j} ' '];
        end
    end
    
    % Add a separator for the column names
    sep = '-';
    sep(1:numel(row_str{1})) = '-';
    sep(col_sizes(1)+2) = '+';
    
    row_str = [row_str(1); {sep}; row_str(2:end)];
    
    % Display
    for i=1:numel(row_str)
        disp(row_str{i});
    end
end

