% Returns a struct with the default configuation parameters for EEG_ICA
function config = EEG_ISC_defaults() 
    config = struct;

    config.cache_base_directory = '.';
    config.segment_length = 20*60;% in seconds
    config.filter_low_edge = 1; %  lower edge of the frequency pass band 
    config.filter_high_edge = 50; %  higher edge of the frequency pass band 
    
    config.spectogram_window_size = 5; % in seconds
    config.spectogram_band_size = 10;
    
    config.correlation_window_size = 30;
    config.correlation_random_length = 100;
    config.correlation_random_iterations = 100;
    
    config.significance_threshold = 2; % in s.d
    
end