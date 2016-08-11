% Add the BrainVision utility functions 
add_bvutils();

% load all the BrainVision files located in data directory
alldata_rep = pop_loadbvdir('C:\bigdata\debates\rep');
% align all data to start and end together
alldata_rep = eeg_multi_align(alldata_rep, 60*1, 60*1, 'REMOVE');

% load all the BrainVision files located in data directory
alldata_dem = pop_loadbvdir('C:\bigdata\debates\dem');
% align all data to start and end together
alldata_dem = eeg_multi_align(alldata_dem, 60*5, 60*1);


% setup the algorithm configuration
config = EEG_ISC_defaults();
config.run_name = 'go15dem';
config.data = alldata_dem;
config.data_channels = [1:16];
config.ref_channel = 17;

% run the algorithm
results_dem = EEG_ISC_run(config);

config.run_name = 'go14rep';
config.data = alldata_rep;
result_rep = EEG_ISC_run(config);

