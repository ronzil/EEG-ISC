% return starting time of EEG data
function res = eeg_starttime_set(EEGdata, dtObj)
    b = eeg_getbounds(EEGdata);   
    assert(length(b) == 1, 'Only support one continious recording');
    
	EEGdata.event(b).bvdatetime = dtObj;	
	res = EEGdata;
	