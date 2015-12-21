function [data_out, ReadTime, DataRate] = video_read(FilePath, Format, FrameSize, Indices)
    % [data_out, ReadTime, DataRate] = video_read(FilePath, Format, FrameSize, Indices)
    %  Function to read raw video frames from a binary file.
    %   - Damien Loterie (05/2014)
    
    % Find number of bytes for this format
    FormatSize = format_size(Format);
    
    % Calculate sizes
    FramePixels = prod(FrameSize);
    BytesPerFrame = FramePixels*FormatSize;
    
    % Open file
    FileID = fopen(FilePath);
    
    % Read frames
    data_out = zeros([FrameSize numel(Indices)], Format);
    ticID = tic;
    for i=1:numel(Indices)
        % Find frame position within the stream
        BytePos = (Indices(i)-1)*BytesPerFrame;
        
        % Move to this position
        fseek(FileID, BytePos, -1);
        
        % Read data
        data_out(:,:,i) = fread(FileID, FrameSize, ['*' Format]);
    end
    
    % Close file
    fclose(FileID);
    
    % Timing information
    ReadTime = toc(ticID);
    DataRate = numel(Indices)*BytesPerFrame/ReadTime;
end

