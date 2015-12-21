function img_rgb = img_db_norm(field, normalize)
    % img_rgb = img_db_norm(field)
    %
    % Logarithmic coloring function.
    % The color thresholds are designed for an input field with a maximal
    % dynamic range of 1:10'000.
    %
    % - Damien Loterie (05/2014)


    if nargin<2 || normalize
        % Normalize field so that the total energy is 1
        field = field/sqrt(sum(abs(field(:)).^2));
    end

    % dBE map (dB = dB of electric field)
    dBE = db(field);

    % Define color map
    dBE_thresholds = [0 -10 -20 -30 -40 -50];
    white  = [1   1   1];
    red    = hsv2rgb([0.01 1.00 0.80]);
    yellow = hsv2rgb([0.16 0.92 0.96]);
    green  = hsv2rgb([0.33 0.75 0.90]);
    blue   = hsv2rgb([0.55 1.00 0.95]);
    black  = [0   0   0];

    % Create RGB picture
    dBE(dBE>max(dBE_thresholds)) = max(dBE_thresholds);
    dBE(dBE<min(dBE_thresholds)) = min(dBE_thresholds);
    img_rgb = interp1(dBE_thresholds.', ...
                  [white; red; yellow; green; blue; black], ...
                  dBE(:),...
                  'linear');
              
    img_rgb = reshape(img_rgb,[size(field) 3]);
end

