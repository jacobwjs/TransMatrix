
s = daq.createSession('ni');
s.addCounterInputChannel('Dev1','ctr0','EdgeCount');

s.startBackground();
pause(2);
value = s.inputSingleScan();
s.stop();

s.release;
clear s ch;