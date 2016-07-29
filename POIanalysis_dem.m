% organize POI data

%alldata_dem = pop_loadbvdir('C:\bigdata\debates\dem');
%alldata_dem = eeg_multi_alignstart(alldata_dem, 60*6);

%%% get EEG data
eeg_time = eeg_starttime(alldata_dem{1}); % note
eeg_time_unix = seconds(eeg_time-datetime(1970,1,1,0,0,0)+hours(6))*1000;
%load('finalrunfull-dem\step6_CorrSpectoTimeBands');
load('finalrun20-dem\step6_CorrSpectoTimeBands');
%load('cleanrun3-dem\step6_CorrSpectoTimeBands');
%load('step6_CorrSpectoTimeBands_1_315000');
eeg_data = result;

% process debate csv
segtable = readtable('slider-data\debate2-speaker-data.csv');
segtable.Properties.VariableNames = {'d1', 'startTS', 'd2','d3', 'duration', 'name'};
segtable(:,[1,3,4]) = []; % delete unneeded columns.

segtable.duration = segtable.duration*1000; %convert to miliseconds

% prepare slider timedata
slider_running = readtable('slider-data\debate2-slider_data_clean.csv');

slider_events_fn = 'slider-data\debate2-events-data.csv';


POIanalysis;