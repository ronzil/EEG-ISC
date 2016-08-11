% Returns a struct with the default configuation parameters for EEG_ICA.
% See inside for documention about the various parameters.
function config = EEG_ISC_defaults() 
    config = struct;

    %%%These needs to be manually defined when running
    %config.run_name = 'experiment7'; % A name given to this run
    %config.data = exp7data; % The data. In the form a cell array of EEG objects.
    %config.data_channels = 1:16;  % The data channels indicies

    % This is optional, however it seems that without dereferncing the
    % data, the ICA does not work properly.
    %config.ref_channel = 17; % The reference channel index
    
    
    config.cache_base_directory = '.'; % Base directory for cache dir
    config.segment_length = 20*60; % Length of segment in seconds. Each segment of the data is calculated seperately.
    config.filter_low_edge = 1; %  lower edge of the frequency pass band filter
    config.filter_high_edge = 50; %  higher edge of the frequency pass band filter
    
    config.spectogram_window_size = 5; % window size in seconds used by FFT
    config.spectogram_band_size = 10; % width of band bucket size. in Hz. I.E 0-10,1-20 etc
    
    config.correlation_window_size = 30; % window size for correlation calculation. In seconds
    
    config.correlation_random_length = 800; % Length of segments when doing random correlations. In seconds.
    config.correlation_random_iterations = 100; %Number of random interations. Results don't seem to change much when increasing value.
    
end