function Free_meadowlark_slm(sdk)

% Always call Delete_SDK before exiting
calllib('Blink_SDK_C', 'Delete_SDK', sdk);
disp('Meadowlark Blink SDK successfully deleted');

% Unload the library
unloadlibrary('Blink_SDK_C');
disp('Meadowlark Blink library successfully unloaded');

end

