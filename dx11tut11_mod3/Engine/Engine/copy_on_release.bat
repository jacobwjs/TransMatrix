@echo off

set destination="\\LAPDPC18\Damien\dx_fullscreen\"

exit

copy /Y ..\Release\*.exe          			%destination%
copy /Y .\*.ps                    			%destination%
copy /Y .\*.vs                    			%destination%
copy /Y ..\MATLAB\dx_fullscreen.m 			%destination%
copy /Y ..\MATLAB\dx_fullscreen_mex.cpp 	%destination%
copy /Y ..\MATLAB\dx_fullscreen_mex.mexw64 	%destination%