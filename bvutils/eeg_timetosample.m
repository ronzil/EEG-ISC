function res = eeg_timetosample(EEG, dtObj)
	start = eeg_starttime(EEG);
	diff = dtObj - start;
	
	res = round( seconds(diff) * EEG.srate);