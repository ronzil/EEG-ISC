% Add a time based event to EEG. 
% Inputs:
%   EEG            - input dataset
%   position       - datetime object of event
%   duration       - duration of event in seconds
%   title          - name of event
function EEG = eeg_addtimeevent(EEG, position, duration, title)

	% assert input is of the same length
	assert(length(position) == length(duration));
	assert(length(position) == length(title));

	% convert timestamps to sample number
	sample = eeg_timetosample(EEG, position);
	
	% remove events that are in the past
	good_samples = sample>0;
	sample = sample(good_samples);
	position = position(good_samples);
	duration = duration(good_samples);
	title = title(good_samples);
	
	% add events
	EEG = eeg_addnewevents(EEG,num2cell(sample), title, {'duration'}, {[duration]});

end
