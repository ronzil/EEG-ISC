% return starting time of EEG data
function dtObj = eeg_starttime(EEGdata)
	startstr = EEGdata.event(1).bvtime;
	
	assert( strcmp(class(startstr), 'char'), 'No proper bvtime. Make sure you are using this library before the bv plugin '); % make sure we have it
	
	dtObj = parsebvtime(startstr);
	
	