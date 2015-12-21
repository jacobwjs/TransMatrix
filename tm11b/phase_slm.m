function img = phase_slm(field, offset)
    % Script to convert a complex field to a phase image displayable on the
    % SLM via dx_fullscreen.
    % phase_slm(field) gives a 8-bit phase image corresponding to the given
    %                  complex field
    % phase_slm(field, offset) in addition places the phase image inside a
    %                          canvas with the size of the SLM (1920x1080),
    %                          at a given offset from the center.
    % - Damien Loterie (01/2014)
    
    
%     % For debugging: make an amplitude image
%     img = abs(field);
%     img = (img-min(img(:)))/(max(img(:))-min(img(:)));
    
%     % Make a phase image (oldest way)
%     img = angle(field)+pi;       % The range of values of the SLM is [0;2pi] while that of MATLAB is [-pi;pi]
%     img = uint8(img/(2*pi)*255);

    % Make a phase image (old way)
    img = angle(field);
    img = uint8(mod(round(img*256/(2*pi)),256));

%     % Make a phase image
%     img = round((angle(field)+pi)*(256/(2*pi)));
%     img(img==256) = 0;
%     img = uint8(img);

    % Place this image inside a canvas with the size of the SLM
    if nargin>1 && ~isempty(offset)
        [x_slm, y_slm] = slm_size();
        img = pad_center(img, [y_slm, x_slm], offset);
    end
    
    % Coordinate change: (y,x) in MATLAB -> (x,y) in DirectX
    if numel(size(img))<=2
        img = transpose(img);
    else
        img = permute(img,[2 1 3:numel(size(img))]);
    end
end

