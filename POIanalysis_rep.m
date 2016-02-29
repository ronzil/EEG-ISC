% organize POI data

%%% get EEG data
eeg_time = eeg_starttime(alldata_rep{1}); % note
eeg_time_unix = seconds(eeg_time-datetime(1970,1,1,0,0,0)+hours(6))*1000;
load('cleanrun3\step6_CorrSpectoTimeBands');
%load('step6_CorrSpectoTimeBands_1_315000');
eeg_data = result;


% process debate csv
segtable = readtable('slider-data\debate1-speaker-data.csv');
assert (length(segtable.Properties.VariableNames)==3);
segtable.Properties.VariableNames = {'startTS', 'duration', 'name'};
segtable.duration = segtable.duration*1000; %convert to miliseconds

% prepare slider timedata
slider_running = readtable('slider-data\debates1-slider-clean.csv');
slider_events_fn = 'slider-data\debate1-events_data.csv';

POIanalysis;