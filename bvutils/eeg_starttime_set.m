% return starting time of EEG data
function res = eeg_starttime_set(EEGData, dtObj)
	EEGData.event(1).bvtime = writebvtime(dtObj);	
	res = EEGData;
	