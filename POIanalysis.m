% organize POI data

%%% get EEG data
eeg_time = eeg_starttime(alldata_rep{1}); % note
eeg_time_unix = seconds(eeg_time-datetime(1970,1,1,0,0,0)+hours(6))*1000;
load('step6_CorrSpectoTimeBands');
%load('step6_CorrSpectoTimeBands_1_315000');
eeg_data = result;
%eeg_values = mean(result);


% process debate csv
segtable = readtable('debate1-speaker-data.csv');
assert (length(segtable.Properties.VariableNames)==3);
segtable.Properties.VariableNames = {'startTS', 'duration', 'name'};
segtable.duration = segtable.duration*1000; %convert to miliseconds

% save only segtable minimum of minlength
minlength = 15000;
segtable = segtable(find(segtable.duration>minlength),:);
% skip first skipahread seconds
skipahead = 10000;
segtable.startTS = segtable.startTS + skipahead;
segtable.duration = segtable.duration - skipahead;

% remove segments that we have no EEG data for
segtable = segtable(find(segtable.startTS>eeg_time_unix),:);
segtable = segtable(find(segtable.startTS-eeg_time_unix+segtable.duration<length(eeg_data)*1000),:);

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

slider_td_all = struct('startTS',startTS, 'step', step, 'data', data);

slider_td_all_smooth = slider_td_all;

data = tsmovavg(slider_td_all_smooth.data,'s',30);
slider_td_all_smooth.data = data(30:end);



%% prepare slider power timedata
sliderpower_td_all = sliderpower('debate1-events_data.csv', 1000);

sliderpower_td_all_smooth = sliderpower_td_all;

sliderpower_td_all_smooth.data = tsmovavg(sliderpower_td_all_smooth.data,'s',30);
sliderpower_td_all_smooth.data = sliderpower_td_all_smooth.data(30:end);


%%%%

eeg_td_all = {};
for bandi=1:size(eeg_data,1)
    eeg_values = eeg_data(bandi,:);
    eeg_td_all{bandi} = struct('startTS',eeg_time_unix, 'step', 1000, 'data', eeg_values);
end    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


corrmat = [];
rcorrmat = [];
for i=1:length(segments)
    val = [];
    for r=1:1000
        rsegment = randomize_segments(segments{i}, eeg_td_all{1});
        val(r) = corr_timedatas_by_segments(slider_td_all, eeg_td_all{1}, rsegment);
    end    

	for bandi=1:size(eeg_data,1)
        corrmat(bandi,i) = corr_timedatas_by_segments(slider_td_all, eeg_td_all{bandi}, segments{i});
        rcorrmat(bandi,i) = (corrmat(bandi,i)-mean(val))/std(val);
    end
end

corrmat
rcorrmat

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[slider_value, slider_sig] = segment_by_timedata(slider_td_all, segments, 100);    
[sliderpower_value, sliderpower_sig] = segment_by_timedata(sliderpower_td_all, segments, 100);    
[slider_smooth_value, slider_smooth_sig] = segment_by_timedata(slider_td_all_smooth, segments, 100);    
[sliderpower_smooth_value, sliderpower_smooth_sig] = segment_by_timedata(sliderpower_td_all_smooth, segments, 100);    


rtable = array2table([slider_value;
				      slider_sig;
					  slider_smooth_value;
					  slider_smooth_sig;
					  sliderpower_value;
					  sliderpower_sig;
					  sliderpower_smooth_value;
					  sliderpower_smooth_sig]);
rtable.Properties.RowNames = {'slider value','slider sig','slider smooth value','slider smooth sig','slider power value','slider power sig','sliderpower smooth value', 'slider power smooth sig'}					  ;

rtable.Properties.VariableNames = strrep(names,' ','_');

disp(rtable);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('eeg values');
eegtable_val = table;
eegtable_sig = table;
for bandi=1:size(result,1)

    [eeg_value, eeg_sig] = segment_by_timedata(eeg_td_all{bandi}, segments, 1000);    
	
	eegtable_val = [eegtable_val ; array2table(eeg_value)];
	eegtable_sig = [eegtable_sig ; array2table(eeg_sig)];
	
	
    for i=1:length(segments)
    	disp(sprintf('Band %d Name %s - Val %f (std %f)', bandi, segments{i}.name, eeg_value(i), eeg_sig(i)));
    end
	
	
	
    cslider(bandi) = corr(eeg_value', slider_value');
    csliderabs(bandi) = corr(eeg_value', abs(slider_value)');        	
    cpower(bandi) = corr(eeg_value', sliderpower_value');
    cslidersmooth(bandi) = corr(eeg_value', slider_smooth_value');
    csliderabssmooth(bandi) = corr(eeg_value', abs(slider_smooth_value)');        	
    cpowersmooth(bandi) = corr(eeg_value', sliderpower_smooth_value');
	
    meanabs(bandi) = mean(abs(eeg_value));

    
    [dummy, perm] = sort(eeg_value);
    winlist = names(perm);    
%   	disp(sprintf('Band %d. Cslider %f. csliderabs %f, Csliderpower %f. mean abs %f.', bandi, sig, sig4, sig2, sig3 ));    
    disp(winlist');
    
end 

maxv = max()
eegtable_sig = []

eegtable_val.Properties.VariableNames = strrep(names,' ','_');
eegtable_sig.Properties.VariableNames = strrep(names,' ','_');

eegtable_val
eegtable_sig


corrtable = table(cslider',csliderabs',cpower',cslidersmooth',csliderabssmooth',cpowersmooth',meanabs');
corrtable.Properties.VariableNames = {'cslider','csliderabs','cpower','cslidersmooth','csliderabssmooth','cpowersmooth','meanabs'};
disp(corrtable);
   



