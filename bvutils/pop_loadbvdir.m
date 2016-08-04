% Load all the BrainVision data files in a given directory
function allData = pop_loadbvdir(path)

	allData = {};
	files = dir(strcat(path, filesep, '*.vhdr'));
	for file = files'
		EEG = pop_loadbv(path, file.name);
%		EEG = eeg_checkset(EEG);
		allData{end+1} = EEG;
	end