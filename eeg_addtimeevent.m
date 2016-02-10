% Add a time based event to EEG. 
% Inputs:
%   EEG            - input dataset
%   position       - datetime object of event
%   duration       - duration of event in seconds
%   title          - name of event
function EEG = eeg_addtimeevent(EEG, position, duration, title)

	sample = eeg_timetosample(EEG, position)
	
	assert(sample>0);

	EEG = eeg_addnewevents(EEG, {[sample]}, {title}, {'duration'}, {[duration]});
