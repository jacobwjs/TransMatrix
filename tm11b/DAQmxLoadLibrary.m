function DAQmxLoadLibrary()
	% Loads the DAQmx library
	%   - Damien Loterie (03/2014)
	
    if ~libisloaded('NIDAQmx')
        % Load library
        warning('off','MATLAB:loadlibrary:TypeNotFound');
        [notfound, warnings] = loadlibrary('nicaiu.dll',...
                                           'C:\Program Files (x86)\National Instruments\NI-DAQ\DAQmx ANSI C Dev\include\NIDAQmx.h',...
                                           'alias',...
                                           'NIDAQmx');
        warning('on','MATLAB:loadlibrary:TypeNotFound');
        
        % Write warnings and errors
        fid = fopen('DAQmxLibrary_notfound.txt','w');
        fprintf(fid, '%s\n', notfound{:});
        fclose(fid);
        
        fid = fopen('DAQmxLibrary_warnings.txt','w');
        fprintf(fid, '%s\n', warnings);
        fclose(fid);
        
%         % Gather more information about loading the library
%         M = libfunctions('NIDAQmx','-full');  % use this to show the...
%         
%         % Write extra information
%         fid = fopen('DAQmxLibrary_libfunctions.txt','w');
%         fprintf(fid, '%s\n', M{:});
%         fclose(fid);
        
    end

end

