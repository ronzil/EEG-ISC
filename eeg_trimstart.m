% trim EEG data to start at specific datetime.
function res = eeg_trimstart(EEGdata, dtObj)

	skip = eeg_timetosample(EEGdata, dtObj);
	assert(skip > 0, 'Currently no support for negative adjusment');
	disp(sprintf('eeg_trimstart: trimming %d samples.', skip));
	
	% trim begining of data
	res = eeg_eegrej( EEGdata, [1 skip] );
	
	% write bvtime back to EEG	
	res = eeg_starttime_set(res, dtObj);
