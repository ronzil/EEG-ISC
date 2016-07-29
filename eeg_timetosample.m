function res = eeg_timetosample(EEG, position)
	start = eeg_starttime(EEG);
	diff = position - start;
	
	res = round( seconds(diff) * EEG.srate);