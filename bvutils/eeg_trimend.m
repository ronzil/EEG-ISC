% trim EEG data to end at specific datetime.
function res = eeg_trimend(EEGdata, dtObj)

	skip = eeg_timetosample(EEGdata, dtObj);
	assert(skip >= 0, 'Currently no support for negative adjusment');
	if (skip >= length(EEGdata.data))
		res = EEGdata;
		return
	end
	
	disp(sprintf('eeg_trimend: trimming %d samples.', skip));
	
	% trim begining of data
	res = eeg_eegrej( EEGdata, [skip length(EEGdata.data)] );
	
