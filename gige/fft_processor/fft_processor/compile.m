% Script to compile .mex files
%   - Damien Loterie (03/2015)

clear all;
clear mex;
clc;

% Parameter sets
optim_args = {'-v',...
               'OPTIMFLAGS=$OPTIMFLAGS /Oi /Ot /GL /Qpar /Qpar-report:2 /Qvec-report:2'};
debug_args = {'-g'};
include_args = {'-L"C:\Program Files (x86)\Pleora Technologies Inc\eBUS SDK\Libraries"',...
                '-I"C:\Program Files (x86)\Pleora Technologies Inc\eBUS SDK\Includes"',...
                '-L".\fftw-3.3.4-dll64"',...
                '-I".\fftw-3.3.4-dll64"',...
                '-I"..\..\gige_interface\gige_interface"',...
                '-I"..\..\disk_writer\disk_writer"'};
           
% Final parameters
% compile_args = [debug_args, include_args];
compile_args = [optim_args, include_args];
  
% Compile
disp('Compiling...');
mex(compile_args{:}, 'fftw_wrapper_r2c_mex.cpp');
mex(compile_args{:}, 'fftw_wrapper_c2c_mex.cpp');
mex(compile_args{:}, 'fftprocessor_mex.cpp');

warning('Consider using the -largeArrayDims flag when compiling, and adapting the code for this.');