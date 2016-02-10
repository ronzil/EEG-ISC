% trim the start of all EEG data in <allEEGdata> cell to the latest point. Optionally add extra seconds to trim point
function res = eeg_multi_alignstart(allEEGdata, extraSeconds)

	if (nargin < 2)
		extraSeconds = 0
	end

	% find latest starting point
	latest = eeg_starttime(allEEGdata{1});
	for i = 1:length(allEEGdata)
		st = eeg_starttime(allEEGdata{i});
		if (st > latest) 
			latest = st;
		end
	end
	
	disp(sprintf('Trimming all EEG data to %s', datestr(latest)));
	
	% add extraSeconds
	cutoff = latest + seconds(extraSeconds);

	% preform trim
	for i = 1:length(allEEGdata)
		allEEGdata{i} = eeg_trimstart(allEEGdata{i}, cutoff);
	end
	
	res = allEEGdata;