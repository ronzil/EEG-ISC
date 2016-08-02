% return starting time of EEG data
function dtObj = eeg_starttime(EEGdata)
    b = find(strcmp('boundary', {EEGdata.event.type}));   
    assert(length(b) == 1, 'Only support one continious recording');
	assert(isfield(EEGdata.event(b), 'bvdatetime'), 'No proper bv datetime. Make sure you load the files using this library. '); % make sure we have it
    
    dtObj = EEGdata.event(b).bvdatetime;
    return;
    
	