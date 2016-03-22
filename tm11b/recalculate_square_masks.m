function params = recalculate_square_masks( params )
    params.freq.mask1 = mask_square([params.ROI(4),params.ROI(3)],...
                                    params.freq.x,...
                                    params.freq.y,...
                                    params.freq.r1*2);
                                
    params.freq.mask1c = mask_square([params.ROI(4),params.ROI(3)],...
                                     [],...
                                     [],...
                                     params.freq.r1*2);
                                 
    params.freq.mask2 = mask_square([params.ROI(4),params.ROI(3)],...
                                    params.freq.x,...
                                    params.freq.y,...
                                    params.freq.r2*2);
                                
    params.freq.mask2c = mask_square([params.ROI(4),params.ROI(3)],...
                                     [],...
                                     [],...
                                     params.freq.r2*2);

end
