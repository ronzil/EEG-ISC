% return starting time of EEG data
function dtObj = eeg_starttime(EEGdata)
	assert( isfield(EEGdata.event(1), 'bvdatetime'), 'No proper bv datetime. Make sure you load the files using this library. '); % make sure we have it
    dtObj = EEGdata.event(1).bvdatetime;
    return;
    
	