% trim the start of all EEG data in <allEEGdata> cell to the latest point. Optionally add extra seconds to trim point
function EEGcell = eeg_multi_alignstart(EEGcell, extraSeconds)

	if (nargin < 2)
		extraSeconds = 0;
	end

	% find latest starting point
	latest = eeg_starttime(EEGcell{1});
	for i = 1:length(EEGcell)
		st = eeg_starttime(EEGcell{i});
		if (st > latest) 
			latest = st;
		end
	end
	
	% add extraSeconds
	cutoff = latest + seconds(extraSeconds);

	disp(sprintf('Trimming all EEG data to %s', datestr(cutoff)));

%	% preform trim
%	for i = 1:length(EEGcell)
%		EEGcell{i} = eeg_trimstart(EEGcell{i}, cutoff);
%	end

%	res = cellfun(@(eeg) eeg_trimstart(eeg, cutoff), EEGcell);
	EEGcell = eeg_multi_apply(@(eeg) eeg_trimstart(eeg, cutoff), EEGcell);
