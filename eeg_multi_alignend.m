% trim the end of all EEG data in <allEEGdata> cell to the earilest end point. Optionally reduce extra seconds to trim point
function EEGcell = eeg_multi_alignend(EEGcell, extraSeconds)

	if (nargin < 2)
		extraSeconds = 0;
	end

	% find eariliest ending point
	earilest = datetime(3000,1,1); % bug 3000 imminent 
	for i = 1:length(EEGcell)
		en = eeg_starttime(EEGcell{i}) + seconds(length(EEGcell{i}.data)/EEGcell{i}.srate);
		if (en <  earilest) 
			earilest = en;
		end
	end
	
	% add extraSeconds
	cutoff = earilest - seconds(extraSeconds);

	disp(sprintf('Trimming end of all EEG data to %s', datestr(cutoff)));

%	% preform trim
%	for i = 1:length(EEGcell)
%		EEGcell{i} = eeg_trimstart(EEGcell{i}, cutoff);
%	end

%	res = cellfun(@(eeg) eeg_trimstart(eeg, cutoff), EEGcell);
	EEGcell = eeg_multi_apply(@(eeg) eeg_trimend(eeg, cutoff), EEGcell);
