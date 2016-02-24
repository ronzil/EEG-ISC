% organize POI data


% process debate csv
segtable = readtable('debate1-speaker-data.csv', 'format','%d64%f%s');
assert (length(segtable.Properties.VariableNames)==3);
segtable.Properties.VariableNames = {'startTS', 'duration', 'name'};
segtable.duration = segtable.duration*1000; %convert to miliseconds

% save only segtable minimum of minlength
minlength = 30000;
segtable = segtable(find(segtable.duration>minlength),:);
% skip first skipahread seconds
skipahead = 10000;
segtable.startTS = segtable.startTS + skipahead;
segtable.duration = segtable.duration - skipahead;


%%%% segments. a cell array contains a struct with fields
% name - name of the segment group
% data - 2D array [startTS, duration]
segments = {};
names = unique(segtable.name);
for i=1:length(names)
	name = names{i};
	data = table2array(segtable(find(strcmp(segtable.name,names(i))), 1:2));
	segments{i} = struct('name', name, 'data', data);
end	
	



%%%%%%% timedata. is a struct with the following properties
%   .data - vector of values
%   .startTS - timestamp of first value in unix time
%   .step - time step between samples in miliseconds. (1/srate)

% prepare slider timedata
slider_running = readtable('debates1-slider-clean.csv');
startTS = slider_running(1,:).Timestamp;
step = (slider_running(2,:).Timestamp - slider_running(1,:).Timestamp);
data = mean(table2array(slider_running(:, 3:end))');


%data = tsmovavg(data,'s',30);
%data = data(30:end);

slider_td_all = struct('startTS',startTS, 'step', step, 'data', data);


%% prepare slider power timedata
sliderpower_td_all = sliderpower('debate1-events_data.csv', 1000);

%sliderpower_td_all.data = tsmovavg(sliderpower_td_all.data,'s',30);
%sliderpower_td_all.data = sliderpower_td_all.data(30:end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('slider values');
for i=1:length(segments)
    [value, sig] = segment_by_timedata(slider_td_all, segments{i}, 100);    
	disp(sprintf('Name %s - Val %f (std %f)', segments{i}.name, value, sig));
end

disp('slider power values');
for i=1:length(segments)
    [value, sig] = segment_by_timedata(sliderpower_td_all, segments{i}, 100);    
	disp(sprintf('Name %s - Val %f (std %f)', segments{i}.name, value, sig));
end

%%% get EEG data
eeg_time = eeg_starttime(alldata_rep{1}); % note
eeg_time_unix = seconds(eeg_time-datetime(1970,1,1,0,0,0)+hours(6))*1000;
load('step6_CorrSpectoTimeBands');
%eeg_values = mean(result);

disp('eeg values');
eeg_td_all = {};
for bandi=1:size(result,1)
    eeg_values = result(bandi,:);
    eeg_td_all{bandi} = struct('startTS',eeg_time_unix, 'step', 1000, 'data', eeg_values);

    value = []; sig=[];
    for i=1:length(segments)
        [value(i), sig(i)] = segment_by_timedata(eeg_td_all{bandi}, segments{i}, 1000);    
    	disp(sprintf('Band %d Name %s - Val %f (std %f)', bandi, segments{i}.name, value(i), sig(i)));
    end
   	disp(sprintf('Band %d total sig %f', bandi, mean(abs(sig))  ));    
    
end    

