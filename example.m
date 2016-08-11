% Add the BrainVision utility functions 
add_bvutils();

% load all the BrainVision files located in data directory
alldata_dem = pop_loadbvdir('C:\bigdata\debates\dem');
% align all data to start and end together
alldata_dem = eeg_multi_align(alldata_dem, 60, 60);

% setup the algorithm configuration
config = EEG_ISC_defaults();
config.run_name = 'dem_run';
config.data = alldata_dem;
config.data_channels = 1:16;
config.ref_channel = 17;

% run the algorithm
results_dem = EEG_ISC_run(config);
