% Add a time based event to EEG. 
% Inputs:
%   EEG            - input dataset
%   dtObj          - datetime object of event
%   duration       - duration of event in seconds
%   title          - name of event
function EEG = eeg_addtimeevent(EEG, dtObj, duration, title)

	% assert input is of the same length
	assert(length(dtObj) == length(duration));
	assert(length(dtObj) == length(title));

	% convert timestamps to sample number
	sample = eeg_timetosample(EEG, dtObj);
	
	% remove events that are in the past
	good_samples = sample>0;
	sample = sample(good_samples);
	dtObj = dtObj(good_samples);
	duration = duration(good_samples);
	title = title(good_samples);
	
	% add events
	EEG = eeg_addnewevents(EEG,num2cell(sample), title, {'duration'}, {[duration]});

end
