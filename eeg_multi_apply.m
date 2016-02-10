%apply func to all EEG data in cell
function EEGcell = eeg_multi_apply(func, EEGcell)
	for i = 1:length(EEGcell)
		EEGcell{i} = func(EEGcell{i});
	end
