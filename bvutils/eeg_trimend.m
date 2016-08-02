% trim EEG data to end at specific datetime.
function res = eeg_trimend(EEGdata, dtObj)

    % trim point
	skip = eeg_timetosample(EEGdata, dtObj);
    
	assert(skip >= 0, 'Currently no support for negative adjustment');
	assert(skip < length(EEGdata.data), 'Trim point beyond data in EEG recording. You are probably trying to align EEG data from different times.');
	
%	disp(sprintf('eeg_trimend: trimming %d samples.', skip));
	
	% trim begining of data
	res = eeg_eegrej( EEGdata, [skip length(EEGdata.data)] );
	
