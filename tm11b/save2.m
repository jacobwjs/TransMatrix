function save2(path, varargin)
    % save2(path, option1, option2, ...)
    %   Improved version of "save".
    %     - Automatically saves in v7.3
    %     - More flexibility to specify which variables to save:
    %         e.g. save2('file.mat','data') saves 'data' to file.mat
    %              save2('file.mat','name:data') saves 'data' to file.mat
    %              save2('file.mat','name:data*') saves all the variables
    %                                             starting with 'data'.
    %              save2('file.mat','bytes<1e6') saves all the variables
    %                                            below ~1Mb.
    %     - Attributes for selection: name, bytes and class.
    %     - The names can be specified with regular expressions.
    %       Regular expressions will only be checked if the specified name
    %       is not a valid matlab variable name.
    %     - Exclude variables by preceding their specifier with '-'
    %     - Later specifiers have precedence:
    %         e.g. save2('file.mat','data','-data') will not save 'data'
    %              save2('file.mat','-data','data') will save 'data'
    %     - Use '/list' to see which variables are saved and not saved
    %
    %  - Damien Loterie (06/2014)
    %
    
    % Get variables from the caller workspace
    vars = evalin('caller','whos()');
    
    % Sort by size
    [~, ind] = sort([vars.bytes],'descend');
    vars = vars(ind);
    
    % List of switches to pass to the 'save' function
    switches = {};
    
    % Check all variables for inclusion
    for i=1:numel(vars)
       % Default: do not save save
       vars(i).save = false;
       
       % Walk over all the options
       for j=1:numel(varargin)
           % Get option
           option = varargin{j}; 
           
           % Check
           if ~ischar(option) || numel(option)==0
               error('Specifiers must be non-empty strings');               
           end
           
           % Ignore special commands
           if strcmp(option(1),'/')
               break;
           end
           
           % Look for negation in the start
           if strcmp(option(1),'-')
               exclude = true;
               option = option(2:end);
           else
               exclude = false;
           end
           
           % Look for special characters
           pieces = strsplit(option, {':','<','>','='});
           if numel(pieces)>2
              error(['Invalid specifier: ''' option '''. You cannot use multiple control characters in one specifier.']);
           end
           if numel(pieces)==2 && isempty(pieces(2))
              error(['Invalid specifier: ''' option '''. Control character must be followed by a non-empty condition.']); 
           end
           if numel(pieces)==1
               pieces = [{'name'}, pieces]; %#ok<AGROW>
           end
           
           % Check the possible options
           category = pieces{1};
           condition = pieces{2};
           switch category
               case 'name'
                   if isvarname(condition)
                       match = strcmp(vars(i).name,condition);
                   elseif strcmp(condition,'*')
                       match = true;
                   else
                       match = ~isempty(regexp(vars(i).name,condition, 'once'));
                   end
               case 'bytes'
                   switch option(6)
                       case '>'
                           match = vars(i).bytes>str2double(condition);
                       case '<'
                           match = vars(i).bytes<str2double(condition);
                       case '='
                           match = vars(i).bytes==str2double(condition);
                       otherwise
                           error(['Invalid operator ''' option(6) ''' with bytes']);
                   end
               case 'class'
                   match = evalin('caller', ['isa(' vars(i).name ',''' condition ''')']);
               otherwise
                   error(['Invalid category ''' category '''.']);
           end
           
           % Negate match if needed
           if match
               if exclude
                   vars(i).save = false;
               else
                   vars(i).save = true;
               end
           end
       end
        
       % Add variable if needed
       if vars(i).save
           switches = [switches, {['''' vars(i).name '''']}]; %#ok<AGROW>
       end
    end
    
	% Add version switch
	switches = [switches, {'''-v7.3'''}];
	
    % Build call
    call = ['save(''' path ''''];
    for i=1:numel(switches)
       call = [call ', ' switches{i}]; %#ok<AGROW>
    end
    call = [call ')'];
    
    % Display variables included and excluded
    if any(strcmp(varargin, '/list-saved'))
        % Variables saved
        disp(['Saving to ''' path ''':']);
        for i=1:numel(vars)
           if vars(i).save
              disp([vars(i).name ' (' prettybytes(vars(i).bytes) ')']);
           end
        end
    end
    
    % Check if any variable will be saved
    if ~any([vars.save])
        warning('No variables to save!');
        return;
    end
    
    % List variables skipped
    if any(strcmp(varargin, '/list-skipped'))
        % Variables not saved
        if any(~[vars.save])
            disp('Skipping:');
            for i=1:numel(vars)
               if ~vars(i).save
                  disp([vars(i).name ' (' prettybytes(vars(i).bytes) ')']);
               end
            end
        else
            disp('No variables skipped.');
        end
    end
    
    % Dry run
    if any(strcmp(varargin, '/no-save'))
        return;
    end
    
    % Check directory
    dir = fileparts(path);
    if ~isempty(dir) && ~exist(dir,'dir')
        warning(['The directory ''' dir ''' does not exist and will be created.']);
        mkdir(dir);
    end
    
    % Check if file already exists
    if exist(path,'file')
        if any(strcmp(varargin, '/overwrite'))
            warning(['File ''' path ''' exists already and will be overwritten (CTRL_C within 10s to abort)']);
            pause(10);
        else
            error(['File ''' path ''' exists already.']);
            return;
        end
    end
    
    % Execute
    evalin('caller', call);

end

