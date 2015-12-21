function ind = mask_to_indices(mask_logical, remapping)
    % ind = mask_to_indices(mask_logical, remapping)
    % Converts the logical indices in 'mask' into linear indices.
    % Optionally, it can also remap the indices. Currently the only 
    % supported remapping is 'fftshifted-to-fft', when mask is a fftshifted
    % representation but the output indices are meant to be used on
    % non-fftshifted datasets.
    %  - Damien Loterie (01/2015)

    if nargin<2
       ind = find(mask_logical);
    else
        switch lower(remapping)
            case 'fftshifted-to-fft'
                % Label every element with its linear index in the mask
                number_of_elements = sum(sum(mask_logical));
                mask1 = zeros(size(mask_logical));
                mask1(mask_logical) = 1:number_of_elements;
                
                % Transform to the 'target' mask
                mask2 = ifftshift2(mask1);
                
                % Find where the elements end up in mask2, and read what are
                % their original positions in mask1
                pos2 = find(mask2);    % Position of each element within mask2 (fftshifted mask)
                pos1 = mask2(pos2);    % Corresponding position within mask1 (non-fftshifted mask)
                
                % Create indices that extract elements from a mask2 dataset, 
                % while keeping the order as if it came from mask1.
                ind = zeros(number_of_elements,1);
                ind(pos1) = pos2;
                ind = uint32(ind);
            case 'fftshifted-to-fft-transpose'
                % Label every element with its linear index in the mask
                number_of_elements = sum(sum(mask_logical));
                mask1 = zeros(size(mask_logical));
                mask1(mask_logical) = 1:number_of_elements;
                
                % Transform to the 'target' mask
                mask2 = ifftshift2(mask1)';
                
                % Find where the elements end up in mask2, and read what are
                % their original positions in mask1
                pos2 = find(mask2);    % Position of each element within mask2 (fftshifted mask)
                pos1 = mask2(pos2);    % Corresponding position within mask1 (non-fftshifted mask)
                
                % Create indices that extract elements from a mask2 dataset, 
                % while keeping the order as if it came from mask1.
                ind = zeros(number_of_elements,1);
                ind(pos1) = pos2;
                ind = uint32(ind);
            case 'fftshifted-to-fftw-r2c-transpose'
                % Create a map of linear indices corresponding to fftw-r2c
                % (Note: In MATLAB, the x and y indices are swapped with
                %        respect to the C++ memory order.)
                Ny  = int32(size(mask_logical,1));
                Nx  = int32(size(mask_logical,2));
                Nxh = floor(Nx/2) + 1;
                ix1 = 1:Nxh;
                ix2 = (Nxh+1):Nx;
                map_r2c_x = repmat(0:(Nx-1),    [Ny 1]);
                map_r2c_y = repmat((0:(Ny-1))', [1  Nx]);
                map_r2c   = zeros(size(map_r2c_x), 'like', map_r2c_x);
                map_r2c(:,ix1) = map_r2c_x(:,ix1) + Nxh*map_r2c_y(:,ix1);
                
                % Remap the complex conjugate half to the other half
                % (with negative indices to indicate conjugation)
                map_r2c(:,ix2) = mod(Nx-map_r2c_x(:,ix2),Nx) + Nxh*mod(Ny-map_r2c_y(:,ix2),Ny);
                map_r2c(:,ix2) = -map_r2c(:,ix2);

                % fftshift
                map_fftshift = fftshift(map_r2c);
                
                % Extract indices
                ind = map_fftshift(mask_logical);
            case 'fftshifted-to-fftw-c2c-transpose'
                % Create a map of linear indices corresponding to fftw-r2c
                % (Note: In MATLAB, the x and y indices are swapped with
                %        respect to the C++ memory order.)
                Ny  = int32(size(mask_logical,1));
                Nx  = int32(size(mask_logical,2));

                map_c2c_x = repmat(0:(Nx-1),    [Ny 1]);
                map_c2c_y = repmat((0:(Ny-1))', [1  Nx]);
                map_c2c = map_c2c_x + Nx*map_c2c_y;

                % fftshift
                map_fftshift = fftshift(map_c2c);
                
                % Extract indices
                ind = map_fftshift(mask_logical);
            otherwise
                error('Unknown remapping');
        end
    end
    

    
end

