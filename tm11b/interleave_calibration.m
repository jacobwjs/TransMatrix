function frames = interleave_calibration(factor, data_length, data, calibration, n)
%INTERLEAVE_CALIBRATION
%             Interleave a frame sequence with calibration frames.
%             This is a more practical version of INTERLEAVE.
%
% Usage: frames  = interleave_calibration(factor, data_length, data, calibration, n)
%        indices = interleave_calibration(factor, data_length)
%
% The inputs are:
%    * data:
%        The data source for the interleaved sequence. This must be a
%        function taking input indices n, and returning the corresponding
%        frame stacks.
%    * data_length:
%        Number of frames of the data source.
%    * calibraton:
%        The calibration frame to use for interleaving.
%    * factor: 
%        The interleave factor, i.e. one out of 'factor' frames is a
%        calibration frame.
%    * n: 
%        Indices indicating which frames from the interleaved sequence 
%        should be returned.
%
% The function returns (depending on the inputs):
%   * frames:
%        The interleaved sequence, as a frame stack.
%   * indices:
%        The index of each frame within data, or 0 where there is a
%        calibration frame.
%
% - Damien Loterie (12/2013)
%

    % Handle calling syntax
    if nargin~=2 && nargin~=5
        error('Unexpected syntax'); 
    end
    if ~isscalar(data_length)
       error('data_length must be a scalar'); 
    end

    % Calculate length of the interleaved sequence
    interleave_length = data_length + ceil(data_length/(factor-1)) + 1;
    if nargin<5
        n = 1:interleave_length;
    end
    
    % Convert index to doubles if necessary
    n = double(n);
    
    % Calculate source and indices
    % Assign 'block numbers' to the n-indices, to create the interleave
    % sequence
    mods = mod(n-1, factor);
    blocks = ((n-1)-mods)/factor;
    
    % Find which source corresponds to which frame
    mods = mods+1;
    pattern = [0 ones(1,factor-1)];
    source = pattern(mods);

    % Within each block, determine what the frame index is in the data
    % sequence
    frame_shifts = zeros(size(pattern));
    frame_shifts(pattern==1) = 1:(factor-1);
   
    % Determine for every n the corresponding index in the respective data
    % sources.
    indices = zeros(numel(n),1);
    indices(source==1) = (factor-1)*blocks(source==1) + frame_shifts(mods(source==1));
    indices(n==interleave_length) = 0;
    
    % Make the frame stack
    if nargin>=5
        frames = zeros([size(calibration) numel(n)], 'like', calibration);
        
        if sum(indices~=0)>0
            frames(:,:,indices~=0) = data(indices(indices~=0));
        end
        frames(:,:,indices==0) = repmat(calibration, [1 1 sum(indices==0)]);
    elseif nargin==2
        frames = indices;
    else
        error('Unexpected syntax'); 
    end
    

end

