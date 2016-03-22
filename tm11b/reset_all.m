% Script to call before making a measurement.
% Clears all variables, figures, image acquisition tooblox and
% DirectX fullscreen window
% - Damien Loterie (01/2014)

% Command window
clc;

if (exist('slm', 'var'))
    clear slm;
end
    
% Close fullscreens
s = whos;
for i=1:numel(s)
    if strcmp(s(i).class,'dx_fullscreen')
       try %#ok<TRYNC>
           eval([s(i).name '.quit;']); 
           eval(['delete(' s(i).name ');']); 
       end
    end
end

% Close figures
close all;

% Cleanup variables
clear;
clear mex;

% Reset image acquisition hardware
imaqreset;
imaqmem(26*1024^3); clear ans;

% Close shutters
%shutter('reset');

% % Restart parallelpool
% if matlabpool('SIZE')>0
%     matlabpool close
% end
% matlabpool open





