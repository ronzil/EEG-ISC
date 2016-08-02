% Align all EEG data to start at the same time by trimming the starting point to the earliest contained by all EEG data. Optionally add extra seconds to trim point
function EEGcell = eeg_multi_alignstart(EEGcell, extraSeconds)

    % default value 
	if (nargin < 2)
		extraSeconds = 0;
	end

	% find latest starting point (shared by all)
	latest = eeg_starttime(EEGcell{1});
	for i = 1:length(EEGcell)
		st = eeg_starttime(EEGcell{i});
		if (st > latest) 
			latest = st;
		end
	end
	
	% add extraSeconds
	cutoff = latest + seconds(extraSeconds);

	disp(sprintf('Trimming EEG data to start at %s', datestr(cutoff)));

%	% preform trim
%	for i = 1:length(EEGcell)
%		EEGcell{i} = eeg_trimstart(EEGcell{i}, cutoff);
%	end

%	res = cellfun(@(eeg) eeg_trimstart(eeg, cutoff), EEGcell);
	EEGcell = eeg_multi_apply(@(eeg) eeg_trimstart(eeg, cutoff), EEGcell);
