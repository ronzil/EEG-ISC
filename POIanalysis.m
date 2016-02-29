% organize POI data

%%% ASSUMPTIONS
%eeg_time = eeg_starttime(alldata_rep{1}); % note
%eeg_time_unix = seconds(eeg_time-datetime(1970,1,1,0,0,0)+hours(6))*1000;
%eeg_data ->  load('cleanrun3\step6_CorrSpectoTimeBands');

% segtable 
%segtable.Properties.VariableNames = {'startTS', 'duration', 'name'};
% segtable.duration  %in miliseconds

%slider_running = readtable('slider-data\debates1-slider-clean.csv');

%sliderpower_td_all = sliderpower('slider-data\debate1-events_data.csv', 1000);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%% timedata. is a struct with the following properties
%   .data - vector of values
%   .startTS - timestamp of first value in unix time
%   .step - time step between samples in miliseconds. (1/srate)

% prepare slider timedata
startTS = slider_running(1,:).Timestamp;
step = (slider_running(2,:).Timestamp - slider_running(1,:).Timestamp);
data = mean(table2array(slider_running(:, 3:end))');
slider_td_all = struct('startTS',startTS, 'step', step, 'data', data);

slider_td_all_smooth = slider_td_all;
data = tsmovavg(slider_td_all_smooth.data,'s',30);
slider_td_all_smooth.data = data(30:end);


%% prepare slider power timedata
sliderpower_td_all = sliderpower(slider_events_fn, 1000);
sliderpower_td_all_smooth = sliderpower_td_all;
sliderpower_td_all_smooth.data = tsmovavg(sliderpower_td_all_smooth.data,'s',30);
sliderpower_td_all_smooth.data = sliderpower_td_all_smooth.data(30:end);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% remove eeg data for times we dont have slider data

assert(eeg_time_unix>slider_td_all.startTS); % don't mess with the starting point
d = (eeg_time_unix + length(eeg_data)*1000) - (slider_td_all.startTS + length(slider_td_all.data)*slider_td_all.step) -1;
if (d>0)
	eeg_data = eeg_data(:,[1:length(eeg_data)-round(d/1000)]);
end	


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

%%%% seggroups. a cell array contains a struct with fields
% name - name of the segment group
% data - 2D array [startTS, duration]. Each line is a segment
seggroups = {};
names = unique(segtable.name);
for i=1:length(names)
	name = names{i};
	data = table2array(segtable(find(strcmp(segtable.name,names(i))), 1:2));
	seggroups{i} = struct('name', name, 'data', data);
end	
	





%%%%

eeg_td_all = {};
for bandi=1:size(eeg_data,1)
    eeg_values = eeg_data(bandi,:);
    eeg_td_all{bandi} = struct('startTS',eeg_time_unix, 'step', 1000, 'data', eeg_values); %note 1000
end    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


corrmat = [];
rcorrmat = [];
for i=1:length(seggroups)
    val = [];
    for r=1:100
       rseggroup = randomize_segments(seggroups{i}, eeg_td_all{1});
       val(r) = corr_timedatas_by_seggroup(slider_td_all, eeg_td_all{1}, rseggroup);
    end    

	for bandi=1:size(eeg_data,1)
        corrmat(bandi,i) = corr_timedatas_by_seggroup(slider_td_all, eeg_td_all{bandi}, seggroups{i});
        rcorrmat(bandi,i) = (corrmat(bandi,i)-mean(val))/std(val);
    end
end

corrmat
rcorrmat

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[slider_value, slider_sig] = segment_by_timedata(slider_td_all, seggroups, 100);    
[sliderpower_value, sliderpower_sig] = segment_by_timedata(sliderpower_td_all, seggroups, 100);    
[slider_smooth_value, slider_smooth_sig] = segment_by_timedata(slider_td_all_smooth, seggroups, 100);    
[sliderpower_smooth_value, sliderpower_smooth_sig] = segment_by_timedata(sliderpower_td_all_smooth, seggroups, 100);    


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

mmeanr = mean(slider_td_all.data);
sstdr = std(slider_td_all.data);

disp('eeg values');
eegtable_val = table;
eegtable_sig = table;
for bandi=1:size(result,1)

    [eeg_value, eeg_sig, meanr, stdr] = segment_by_timedata(eeg_td_all{bandi}, seggroups, 1000);    
	
	eegtable_val = [eegtable_val ; array2table(eeg_value)];
	eegtable_sig = [eegtable_sig ; array2table(eeg_sig)];
	
	
    for i=1:length(seggroups)
    	disp(sprintf('Band %d Name %s - Val %f (std %f)', bandi, seggroups{i}.name, eeg_value(i), eeg_sig(i)));
    end
	

    eegxcorr = [];
    for i=1:length(seggroups)
        for j=1:length(seggroups)
			vali = (eeg_value(i)-meanr(j))/stdr(j);
			valj = (eeg_value(j)-meanr(j))/stdr(j);
            eegxcorr(i,j) = (vali-valj);
        end
    end
	t = array2table(eegxcorr);
	t.Properties.RowNames = names;
	t.Properties.VariableNames = strrep(names,' ','_');
    disp(t);
    
	
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

eegtable_val.Properties.VariableNames = strrep(names,' ','_');
eegtable_sig.Properties.VariableNames = strrep(names,' ','_');

eegtable_val
eegtable_sig


corrtable = table(cslider',csliderabs',cpower',cslidersmooth',csliderabssmooth',cpowersmooth',meanabs');
corrtable.Properties.VariableNames = {'cslider','csliderabs','cpower','cslidersmooth','csliderabssmooth','cpowersmooth','meanabs'};
disp(corrtable);
   



