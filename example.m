% Add the BrainVision utility functions 
add_bvutils();

% load all the BrainVision files located in data directory
alldata_rep = pop_loadbvdir('C:\bigdata\debates\rep');
% align all data to start and end together
alldata_rep = eeg_multi_align(alldata_rep, 60*1, 60*1, 'REMOVE');

% run the algorithm
EEGA_bands('debates_rep', alldata_rep);

