% Add the BrainVision utility functions 
add_bvutils();

% load all the BrainVision files located in data directory
alldata_rep = pop_loadbvdir('C:\bigdata\debates\rep');
% align all data to start and end together
alldata_rep = eeg_multi_align(alldata_rep, 60*1, 60*1, 'REMOVE');

% setup the algorithm configuration
config = EEG_ISC_defaults();
config.run_name = 'testgogo';
config.data = alldata_rep;

% run the algorithm
EEGA_bands(config);

