% trim EEG data to start at specific datetime.
function res = eeg_trimstart(EEGdata, dtObj)

	start = eeg_starttime(EEGdata);
	diff = dtObj - start;
	assert(diff>0, 'Currently no support for negative adjusment');
	
	skip = round( seconds(diff) * 1000 / EEGdata.srate);
	disp(sprintf('eeg_trimstart: trimming %d samples.', skip));
	res = eeg_eegrej( EEGdata, [1 skip] );
	% write bvtime back to EEG	
	res = eeg_starttime_set(res, dtObj);
