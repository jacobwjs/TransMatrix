% Script to test the gigesource class
%   - Damien Loterie (11/2014)

s1 = memory;
vid = gigesource('192.168.10.2');

set(vid,'TriggerMode','On');
set(vid,'TriggerSource','Software');
set(vid,'ExposureMode','Timed');

% Take frames with repeated start/stop
i = 0;
minutes = 10;
tic;
while toc<minutes*60
   set(vid,'ExposureTime',round(50+rand*1000));

   start(vid);
   set(vid,'TriggerSoftware');
   vid.wait(1,5);
   frame = getimages(vid,1);
   stop(vid);

   % Show information about the iteration
   i = i+1;
   t = toc;
   disp(['Iteration: ' num2str(i) ' / Time: ' num2str(round(t)) 's']);
end
delete(vid);
clear vid;
s2 = memory;