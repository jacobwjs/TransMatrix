% Script to compile gigesource .mex files
%   - Damien Loterie (03/2015)

clear all;
clear mex;
clc;


% Parameter sets
optim_args = {'-v',...
               'OPTIMFLAGS=$OPTIMFLAGS /Oi /Ot /GL /Qpar /Qpar-report:2 /Qvec-report:2'};
debug_args = {'-g'};
include_args = {'-L"C:\Program Files (x86)\Pleora Technologies Inc\eBUS SDK\Libraries"',...
                '-I"C:\Program Files (x86)\Pleora Technologies Inc\eBUS SDK\Includes"'};
           
% Final parameters
compile_args = [optim_args, include_args, debug_args];

% Compile
disp('Compiling...');
mex(compile_args{:}, 'gigesource_mex.cpp');

warning('Consider using the -largeArrayDims flag when compiling, and adapting the code for this.');