function vsync_config(d, exposure)
    % Configure synchronized triggering
	%  - Damien Loterie (05/2014)
    d.setConfig('pulseEnable',      true);
    d.setConfig('pulseNumber',      1);
    d.setConfig('pulseHighTime',    exposure*1e-6);
    d.setConfig('pulseLowTime',     1e-6);
    d.setConfig('pulseDelayTime',   vsync_delay(d.getConfig('pulseHighTime')));
    d.setConfig('pulseDelayFrames', 4);
    d.setConfig('pulseSync',        true);
end

