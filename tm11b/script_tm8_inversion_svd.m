% Script defining the inversion method for the TM
%  - Damien Loterie (04/2015)

% Define different ways of inverting
tic_inv = tic;
% inversion_methods = {'T'''};
% inversion_methods = {'T''',...
%                      'V * diagmat(svd_filter_inv(s, ''tikhonov'', undb(-20)), sdims) * (U'')',...
%                      'V * diagmat(svd_filter_inv(s, ''tikhonov by index'',  4500), sdims) * (U'')'};
inversion_methods = {'T''',...
                     'V * diagmat(svd_filter_inv(s, ''tikhonov'', undb(-20)), sdims) * (U'')'};


% SVD
disp('Singular value decomposition...');
[U,S,V] = svd(T);
s = diag(S);
sdims = size(S);
sdims = sdims([2 1]);
toc(tic_inv);


% Calculate the different inversion operators
disp('Inversions...');
inversions = struct();
for i=1:numel(inversion_methods)
    disp(inversion_methods{i});
    inversions(i).T_inv = eval(inversion_methods{i});
    inversions(i).InversionMethod = inversion_methods{i};
end
inversion_time_total = toc(tic_inv); toc(tic_inv);
disp(' ');