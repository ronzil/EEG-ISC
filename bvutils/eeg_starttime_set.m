% return starting time of EEG data
function res = eeg_starttime_set(EEGdata, dtObj)
    b = find(strcmp('boundary', {EEGdata.event.type}));   
    assert(length(b) == 1, 'Only support one continious recording');
    
	EEGdata.event(b).bvdatetime = dtObj;	
	res = EEGdata;
	