% Add the BrainVision utility functions 
add_bvutils();

% load all the BrainVision files located in data directory
alldata_dem = pop_loadbvdir('C:\bigdata\debates\dem');
% align all data to start and end together. Trim an extra 60 seconds at
% start and end.
alldata_dem = eeg_multi_align(alldata_dem, 60, 60);

% setup the algorithm configuration
config = EEG_ISC_defaults();
config.run_name = 'dem_run';
config.data = alldata_dem;
config.data_channels = 1:16;
config.ref_channel = 17;

% run the algorithm
results = EEG_ISC_run(config);


%%% interpet results
% results.correlations Contains the calculated ISC for each spectral band plus the raw data.
% results.band_labels Contains the names of each of the spectral bands. e.g '21-30Hz'
% results.significance Contains a table of the significance metric per band and per time segment. In standard deviations. 