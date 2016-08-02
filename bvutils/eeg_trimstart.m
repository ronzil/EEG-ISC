% trim EEG data to start at specific datetime.
function res = eeg_trimstart(EEGdata, dtObj)

    % trim point
	skip = eeg_timetosample(EEGdata, dtObj);
    
	assert(skip >= 0, 'Currently no support for negative adjustment');
	assert(skip < length(EEGdata.data), 'Trim point beyond data in EEG recording. You are probably trying to align EEG data from different times.');

    if (skip == 0) 
		res = EEGdata;
		return
    end
	
	% disp(sprintf('eeg_trimstart: trimming %d samples.', skip));
	
	% trim begining of data
	res = eeg_eegrej( EEGdata, [1 skip] );
	
	% write bvtime back to EEG	
	res = eeg_starttime_set(res, dtObj);
