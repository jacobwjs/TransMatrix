% Script to test the gigesource class
%   - Damien Loterie (11/2014)

vid = gigesource('192.168.10.2');

set(vid,'TriggerMode','On');
set(vid,'TriggerSource','Software');
set(vid,'ExposureMode','Timed'); 


start(vid);

i = 0;
minutes = 10;
tic;
while toc<minutes*60
   set(vid,'ExposureTime',round(50+rand*1000));

   set(vid,'TriggerSoftware');
%   vid.wait(1,5);
   frame = getimages(vid,1);
   image(frame);
   
   pause(0.1);
   i = i+1;
   disp(i);
end

stop(vid);
