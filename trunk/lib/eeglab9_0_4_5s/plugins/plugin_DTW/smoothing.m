function [ output_data ] = smoothing(input_data, window_size)
    
    output_data = NaN(1);
    
    if nargin < 2
        error('eegplugin_rozruch requires 2 arguments: data and smoothing window size')
    end;
    
    start = int32(round(window_size / 2));
    window_stop = int32(window_size - start);
    data_stop = int32(length(input_data) - start);
    
    output_data(1) = 0;
    
    % Averaging of data before the window size is reached
    
    for iter=1:start
        output_data(iter) = mean(input_data(1:iter+start));
    end;

    % Averaging of data for which whole window size is available
    for iter=start:data_stop        
        output_data(iter) = mean(input_data(iter-window_stop+1:iter+start));
    end;
   
    % Averaging of data at the end where data for full window size are not
    % available
    for iter=data_stop+1:data_stop+start
        output_data(iter) = mean(input_data(iter-window_stop:data_stop+start));
    end;
    
    
end

